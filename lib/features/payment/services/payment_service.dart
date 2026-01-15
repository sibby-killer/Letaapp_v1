import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/config/app_config.dart';
import '../../../core/models/order_model.dart';

class PaymentService {
  bool _isInitialized = false;

  // Initialize Paystack (using API directly instead of plugin for better compatibility)
  Future<void> initialize() async {
    _isInitialized = true;
  }

  // Create Paystack subaccount for vendor (Bank Account)
  Future<String> createSubaccount({
    required String businessName,
    required String settlementBank,
    required String accountNumber,
    required double percentageCharge,
  }) async {
    try {
      final url = Uri.parse('https://api.paystack.co/subaccount');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${AppConfig.paystackSecretKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'business_name': businessName,
          'settlement_bank': settlementBank,
          'account_number': accountNumber,
          'percentage_charge': percentageCharge,
          'country': 'KE', // Kenya
          'primary_contact_email': '$businessName@leta.app'.toLowerCase().replaceAll(' ', ''),
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create subaccount');
      }

      final data = json.decode(response.body);
      return data['data']['subaccount_code'] as String;
    } catch (e) {
      throw Exception('Subaccount creation failed: ${e.toString()}');
    }
  }

  // Create Paystack subaccount for M-Pesa (Kenya Mobile Money)
  Future<String> createMpesaSubaccount({
    required String businessName,
    required String phoneNumber,
  }) async {
    try {
      // Normalize phone number to Paystack format
      String normalizedPhone = phoneNumber.replaceAll(RegExp(r'[\s\-]'), '');
      if (normalizedPhone.startsWith('0')) {
        normalizedPhone = '+254${normalizedPhone.substring(1)}';
      }
      
      final url = Uri.parse('https://api.paystack.co/subaccount');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${AppConfig.paystackSecretKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'business_name': businessName,
          'settlement_bank': 'MPESA', // M-Pesa code for Paystack Kenya
          'account_number': normalizedPhone,
          'percentage_charge': AppConfig.storeSharePercent,
          'country': 'KE',
          'primary_contact_phone': normalizedPhone,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create M-Pesa subaccount');
      }

      final data = json.decode(response.body);
      return data['data']['subaccount_code'] as String;
    } catch (e) {
      throw Exception('M-Pesa subaccount creation failed: ${e.toString()}');
    }
  }

  // Create subaccount for rider
  Future<String> createRiderSubaccount({
    required String riderName,
    required String phoneNumber,
  }) async {
    try {
      String normalizedPhone = phoneNumber.replaceAll(RegExp(r'[\s\-]'), '');
      if (normalizedPhone.startsWith('0')) {
        normalizedPhone = '+254${normalizedPhone.substring(1)}';
      }
      
      final url = Uri.parse('https://api.paystack.co/subaccount');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${AppConfig.paystackSecretKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'business_name': 'Rider - $riderName',
          'settlement_bank': 'MPESA',
          'account_number': normalizedPhone,
          'percentage_charge': AppConfig.riderSharePercent,
          'country': 'KE',
          'primary_contact_phone': normalizedPhone,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create rider subaccount');
      }

      final data = json.decode(response.body);
      return data['data']['subaccount_code'] as String;
    } catch (e) {
      throw Exception('Rider subaccount creation failed: ${e.toString()}');
    }
  }

  // Initialize payment transaction
  Future<String> initializeTransaction({
    required OrderModel order,
    required String vendorSubaccountId,
    String? riderSubaccountId,
  }) async {
    try {
      // Calculate split amounts
      final vendorShare = order.subtotal;
      final riderShare = order.deliveryMode == 'rider' ? order.deliveryFee : 0.0;
      final companyShare = order.platformFee + 
          (order.deliveryMode == 'self_delivery' ? order.deliveryFee : 0.0);

      // Build subaccount split
      final subaccounts = <Map<String, dynamic>>[];

      // Vendor gets subtotal
      subaccounts.add({
        'subaccount': vendorSubaccountId,
        'share': (vendorShare * 100).round(), // Convert to kobo/cents
      });

      // Rider gets delivery fee (if not self-delivery)
      if (order.deliveryMode == 'rider' && riderSubaccountId != null) {
        subaccounts.add({
          'subaccount': riderSubaccountId,
          'share': (riderShare * 100).round(),
        });
      }

      final url = Uri.parse('https://api.paystack.co/transaction/initialize');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${AppConfig.paystackSecretKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': order.customerId, // Use actual customer email
          'amount': (order.total * 100).round(), // Convert to kobo/cents
          'reference': order.orderNumber,
          'subaccount': vendorSubaccountId,
          'split': {
            'type': 'flat',
            'bearer_type': 'all',
            'subaccounts': subaccounts,
          },
          'metadata': {
            'order_id': order.id,
            'order_number': order.orderNumber,
            'custom_fields': [
              {
                'display_name': 'Order Number',
                'variable_name': 'order_number',
                'value': order.orderNumber,
              },
            ],
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to initialize transaction');
      }

      final data = json.decode(response.body);
      return data['data']['reference'] as String;
    } catch (e) {
      throw Exception('Transaction initialization failed: ${e.toString()}');
    }
  }

  // Charge customer using Paystack Popup/Redirect
  // In production, use url_launcher to open Paystack payment page
  Future<Map<String, dynamic>> initializePayment({
    required String email,
    required double amount,
    required String reference,
    String? callbackUrl,
  }) async {
    try {
      final url = Uri.parse('https://api.paystack.co/transaction/initialize');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${AppConfig.paystackSecretKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'amount': (amount * 100).round(), // Convert to kobo/cents
          'reference': reference,
          'callback_url': callbackUrl ?? 'https://yourapp.com/payment/callback',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Payment initialization failed');
      }

      final data = json.decode(response.body);
      return {
        'authorization_url': data['data']['authorization_url'],
        'access_code': data['data']['access_code'],
        'reference': data['data']['reference'],
      };
    } catch (e) {
      throw Exception('Payment failed: ${e.toString()}');
    }
  }

  // Verify transaction
  Future<bool> verifyTransaction(String reference) async {
    try {
      final url = Uri.parse('https://api.paystack.co/transaction/verify/$reference');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${AppConfig.paystackSecretKey}',
        },
      );

      if (response.statusCode != 200) {
        return false;
      }

      final data = json.decode(response.body);
      final status = data['data']['status'] as String;

      return status == 'success';
    } catch (e) {
      return false;
    }
  }

  // Calculate payment breakdown using Kenya split configuration
  // Example: For KSh 155 order -> Store: 100, Rider: 40, Company: 10, Tax: 5
  Map<String, double> calculatePaymentSplit(OrderModel order) {
    final total = order.total;
    
    // Calculate based on configured percentages
    final storeShare = total * (AppConfig.storeSharePercent / 100);
    final riderShare = order.deliveryMode == 'rider' 
        ? total * (AppConfig.riderSharePercent / 100) 
        : 0.0;
    final companyShare = total * (AppConfig.companySharePercent / 100);
    final taxAndFees = total * (AppConfig.taxTransactionPercent / 100);
    
    return {
      'store_share': storeShare,
      'rider_share': riderShare,
      'company_share': companyShare,
      'tax_and_fees': taxAndFees,
      'total': total,
    };
  }

  // Calculate split for a specific amount (useful for displaying to users)
  Map<String, double> calculateSplitForAmount(double amount, {bool hasRider = true}) {
    final storeShare = amount * (AppConfig.storeSharePercent / 100);
    final riderShare = hasRider ? amount * (AppConfig.riderSharePercent / 100) : 0.0;
    final companyShare = amount * (AppConfig.companySharePercent / 100);
    final taxAndFees = amount * (AppConfig.taxTransactionPercent / 100);
    
    return {
      'store_share': double.parse(storeShare.toStringAsFixed(2)),
      'rider_share': double.parse(riderShare.toStringAsFixed(2)),
      'company_share': double.parse(companyShare.toStringAsFixed(2)),
      'tax_and_fees': double.parse(taxAndFees.toStringAsFixed(2)),
      'total': amount,
    };
  }

  // Initialize M-Pesa STK Push for payment (Safaricom Daraja API via Paystack)
  Future<Map<String, dynamic>> initiateMpesaPayment({
    required String phoneNumber,
    required double amount,
    required String reference,
    required String description,
  }) async {
    try {
      // Normalize phone number
      String normalizedPhone = phoneNumber.replaceAll(RegExp(r'[\s\-]'), '');
      if (normalizedPhone.startsWith('0')) {
        normalizedPhone = '254${normalizedPhone.substring(1)}';
      } else if (normalizedPhone.startsWith('+')) {
        normalizedPhone = normalizedPhone.substring(1);
      }

      final url = Uri.parse('https://api.paystack.co/charge');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${AppConfig.paystackSecretKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'amount': (amount * 100).round(), // Convert to cents
          'email': '$normalizedPhone@leta.app', // Paystack requires email
          'currency': 'KES',
          'mobile_money': {
            'phone': normalizedPhone,
            'provider': 'mpesa',
          },
          'reference': reference,
          'metadata': {
            'description': description,
          },
        }),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'M-Pesa payment failed');
      }

      final data = json.decode(response.body);
      return {
        'status': data['data']['status'],
        'reference': data['data']['reference'],
        'display_text': data['data']['display_text'] ?? 'Check your phone for M-Pesa prompt',
      };
    } catch (e) {
      throw Exception('M-Pesa payment failed: ${e.toString()}');
    }
  }

  // Process split payment for an order
  Future<Map<String, dynamic>> processSplitPayment({
    required OrderModel order,
    required String customerPhone,
    required String vendorSubaccountId,
    String? riderSubaccountId,
  }) async {
    try {
      final split = calculatePaymentSplit(order);
      
      // Build split configuration for Paystack
      final subaccounts = <Map<String, dynamic>>[
        {
          'subaccount': vendorSubaccountId,
          'share': (split['store_share']! * 100).round(),
        },
      ];

      if (riderSubaccountId != null && split['rider_share']! > 0) {
        subaccounts.add({
          'subaccount': riderSubaccountId,
          'share': (split['rider_share']! * 100).round(),
        });
      }

      // Normalize phone
      String normalizedPhone = customerPhone.replaceAll(RegExp(r'[\s\-]'), '');
      if (normalizedPhone.startsWith('0')) {
        normalizedPhone = '254${normalizedPhone.substring(1)}';
      } else if (normalizedPhone.startsWith('+')) {
        normalizedPhone = normalizedPhone.substring(1);
      }

      final url = Uri.parse('https://api.paystack.co/transaction/initialize');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${AppConfig.paystackSecretKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': '$normalizedPhone@leta.app',
          'amount': (order.total * 100).round(),
          'currency': 'KES',
          'reference': order.orderNumber,
          'split': {
            'type': 'flat',
            'bearer_type': 'account', // Company bears transaction fees
            'subaccounts': subaccounts,
          },
          'channels': ['mobile_money'],
          'mobile_money': {
            'phone': normalizedPhone,
            'provider': 'mpesa',
          },
          'metadata': {
            'order_id': order.id,
            'order_number': order.orderNumber,
            'store_share': split['store_share'],
            'rider_share': split['rider_share'],
            'company_share': split['company_share'],
            'custom_fields': [
              {
                'display_name': 'Order Number',
                'variable_name': 'order_number',
                'value': order.orderNumber,
              },
            ],
          },
        }),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Payment initialization failed');
      }

      final data = json.decode(response.body);
      return {
        'authorization_url': data['data']['authorization_url'],
        'access_code': data['data']['access_code'],
        'reference': data['data']['reference'],
        'split': split,
      };
    } catch (e) {
      throw Exception('Split payment failed: ${e.toString()}');
    }
  }
}
