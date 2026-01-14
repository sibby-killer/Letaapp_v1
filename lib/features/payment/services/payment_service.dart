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

  // Create Paystack subaccount for vendor
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
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create subaccount');
      }

      final data = json.decode(response.body);
      return data['data']['subaccount_code'] as String;
    } catch (e) {
      throw Exception('Subaccount creation failed: ${e.toString()}');
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

  // Calculate payment breakdown
  Map<String, double> calculatePaymentSplit(OrderModel order) {
    return {
      'vendor_share': order.subtotal,
      'rider_share': order.deliveryMode == 'rider' ? order.deliveryFee : 0.0,
      'company_share': order.platformFee + 
          (order.deliveryMode == 'self_delivery' ? order.deliveryFee : 0.0),
      'tax': order.tax,
      'total': order.total,
    };
  }
}
