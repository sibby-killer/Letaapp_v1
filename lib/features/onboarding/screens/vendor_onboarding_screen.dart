import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../../payment/services/payment_service.dart';
import '../../map/services/map_service.dart';

class VendorOnboardingScreen extends StatefulWidget {
  const VendorOnboardingScreen({super.key});

  @override
  State<VendorOnboardingScreen> createState() => _VendorOnboardingScreenState();
}

class _VendorOnboardingScreenState extends State<VendorOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _mobileMoneyController = TextEditingController();
  
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;
  String _selectedBankCode = '058'; // Default: GTBank
  
  // Common Nigerian banks - Add more as needed
  final List<Map<String, String>> _banks = [
    {'code': '058', 'name': 'GTBank'},
    {'code': '044', 'name': 'Access Bank'},
    {'code': '011', 'name': 'First Bank'},
    {'code': '033', 'name': 'UBA'},
    {'code': '057', 'name': 'Zenith Bank'},
    {'code': '035', 'name': 'Wema Bank'},
    {'code': '232', 'name': 'Sterling Bank'},
    {'code': '030', 'name': 'Heritage Bank'},
  ];

  @override
  void dispose() {
    _storeNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _bankAccountController.dispose();
    _mobileMoneyController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      final mapService = MapService();
      final location = await mapService.getCurrentLocation();
      
      setState(() {
        _latitude = location.latitude;
        _longitude = location.longitude;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location captured successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _submitOnboarding() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture your store location'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final vendorId = authProvider.currentUser!.id;
      
      // Step 1: Create Paystack Subaccount (skip in dev mode if keys not set)
      String subaccountId = 'PENDING_SETUP';
      
      if (AppConfig.paystackSecretKey != 'YOUR_PAYSTACK_SECRET_KEY' &&
          AppConfig.paystackSecretKey.isNotEmpty) {
        try {
          final paymentService = PaymentService();
          await paymentService.initialize();
          
          subaccountId = await paymentService.createSubaccount(
            businessName: _storeNameController.text.trim(),
            settlementBank: _selectedBankCode,
            accountNumber: _bankAccountController.text.trim(),
            percentageCharge: (1 - AppConfig.companyCommissionRate) * 100,
          );
        } catch (e) {
          // Continue without Paystack in development
          debugPrint('Paystack setup skipped: $e');
        }
      }

      // Step 2: Create Store Profile
      final storeData = {
        'vendor_id': vendorId,
        'name': _storeNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'phone': _phoneController.text.trim(),
        'paystack_subaccount_id': subaccountId,
        'bank_account': _bankAccountController.text.trim(),
        'mobile_money_number': _mobileMoneyController.text.trim().isNotEmpty
            ? _mobileMoneyController.text.trim()
            : null,
        'category_ids': [], // Will be selected later
        'is_open': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client.from('stores').insert(storeData);

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store created successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );

        Navigator.of(context).pushReplacementNamed(AppRouter.vendorDashboard);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create store: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Store'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Store Information',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us about your business',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textGray,
                    ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _storeNameController,
                decoration: const InputDecoration(
                  labelText: 'Store Name',
                  hintText: 'My Awesome Store',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter store name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Tell customers about your store',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: '123 Main Street',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _getCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: Text(_latitude == null
                    ? 'Capture Store Location'
                    : 'Location Captured ✓'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _latitude == null
                      ? AppTheme.primaryGreen
                      : AppTheme.successGreen,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+1234567890',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Payment Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'For receiving payments from customers',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textGray,
                    ),
              ),
              const SizedBox(height: 16),
              // Bank Selection Dropdown
              DropdownButtonFormField<String>(
                value: _selectedBankCode,
                decoration: const InputDecoration(
                  labelText: 'Select Bank',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
                items: _banks.map((bank) {
                  return DropdownMenuItem<String>(
                    value: bank['code'],
                    child: Text(bank['name']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBankCode = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankAccountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Bank Account Number',
                  hintText: '1234567890',
                  prefixIcon: Icon(Icons.credit_card_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter bank account';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mobileMoneyController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Money (Optional)',
                  hintText: '+1234567890',
                  prefixIcon: Icon(Icons.phone_android_outlined),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitOnboarding,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Create Store'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
