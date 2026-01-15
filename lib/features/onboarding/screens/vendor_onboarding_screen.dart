import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../../payment/services/payment_service.dart';
import '../../map/services/map_service.dart';
import '../../ai/services/ai_service.dart';

class VendorOnboardingScreen extends StatefulWidget {
  const VendorOnboardingScreen({super.key});

  @override
  State<VendorOnboardingScreen> createState() => _VendorOnboardingScreenState();
}

class _VendorOnboardingScreenState extends State<VendorOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  // Controllers
  final _storeNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mpesaController = TextEditingController();
  final _bankAccountController = TextEditingController();
  
  // State
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isSearchingAddress = false;
  bool _isGeneratingDescription = false;
  double? _latitude;
  double? _longitude;
  String? _selectedBankCode;
  String _selectedPaymentMethod = 'mpesa'; // mpesa or bank
  List<PlaceSearchResult> _addressSuggestions = [];
  List<String> _descriptionOptions = [];
  Timer? _debounceTimer;
  
  final MapService _mapService = MapService();
  final AIService _aiService = AIService();

  @override
  void initState() {
    super.initState();
    _phoneController.text = '+254';
    _mpesaController.text = '+254';
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _mpesaController.dispose();
    _bankAccountController.dispose();
    _pageController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    try {
      final place = await _mapService.getCurrentLocationWithAddress();
      if (mounted) {
        setState(() {
          _latitude = place.latitude;
          _longitude = place.longitude;
          _addressController.text = place.shortAddress;
        });
      }
    } catch (e) {
      debugPrint('Location permission error: $e');
    }
  }

  void _onAddressChanged(String query) {
    _debounceTimer?.cancel();
    if (query.length < 3) {
      setState(() => _addressSuggestions = []);
      return;
    }
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearchingAddress = true);
      try {
        final results = await _mapService.searchPlaces(query);
        if (mounted) {
          setState(() {
            _addressSuggestions = results;
            _isSearchingAddress = false;
          });
        }
      } catch (e) {
        setState(() => _isSearchingAddress = false);
      }
    });
  }

  void _selectAddress(PlaceSearchResult place) {
    setState(() {
      _addressController.text = place.shortAddress;
      _latitude = place.latitude;
      _longitude = place.longitude;
      _addressSuggestions = [];
    });
  }

  Future<void> _generateDescriptions() async {
    if (_storeNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter store name first')),
      );
      return;
    }

    setState(() => _isGeneratingDescription = true);
    
    try {
      final options = await _aiService.generateDescriptionOptions(
        _storeNameController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _descriptionOptions = options;
          _isGeneratingDescription = false;
        });
        _showDescriptionPicker();
      }
    } catch (e) {
      setState(() => _isGeneratingDescription = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate descriptions: $e')),
        );
      }
    }
  }

  void _showDescriptionPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Text(
                    'AI Generated Descriptions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _descriptionOptions.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _descriptionController.text = _descriptionOptions[index];
                        });
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Option ${index + 1}',
                                    style: const TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.touch_app,
                                  size: 16,
                                  color: AppTheme.textGray,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Tap to select',
                                  style: TextStyle(
                                    color: AppTheme.textGray,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _descriptionOptions[index],
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateKenyanPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter phone number';
    }
    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    
    // Check Kenyan phone format: +254XXXXXXXXX or 07XXXXXXXX or 01XXXXXXXX
    if (cleaned.startsWith('+254')) {
      if (cleaned.length != 13) return 'Enter valid Kenyan number (+254XXXXXXXXX)';
      final prefix = cleaned.substring(4, 6);
      if (!['07', '01', '11'].contains(prefix.substring(0, 2))) {
        return 'Invalid Kenyan mobile prefix';
      }
    } else if (cleaned.startsWith('0')) {
      if (cleaned.length != 10) return 'Enter valid Kenyan number (07XXXXXXXX)';
    } else {
      return 'Number must start with +254 or 0';
    }
    return null;
  }

  String? _validateMpesaNumber(String? value) {
    if (_selectedPaymentMethod != 'mpesa') return null;
    return _validateKenyanPhone(value);
  }

  String? _validateBankAccount(String? value) {
    if (_selectedPaymentMethod != 'bank') return null;
    if (value == null || value.isEmpty) {
      return 'Please enter bank account number';
    }
    if (value.length < 8 || value.length > 16) {
      return 'Account number should be 8-16 digits';
    }
    return null;
  }

  Future<void> _submitOnboarding() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your store location'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final vendorId = authProvider.currentUser!.id;
      
      // Step 1: Create Paystack Subaccount (if configured)
      String subaccountId = 'PENDING_SETUP';
      
      if (AppConfig.isPaystackConfigured) {
        try {
          final paymentService = PaymentService();
          await paymentService.initialize();
          
          // For M-Pesa, we'll use a different flow (Paystack supports M-Pesa in Kenya)
          if (_selectedPaymentMethod == 'mpesa') {
            subaccountId = await paymentService.createMpesaSubaccount(
              businessName: _storeNameController.text.trim(),
              phoneNumber: _mpesaController.text.trim(),
            );
          } else {
            subaccountId = await paymentService.createSubaccount(
              businessName: _storeNameController.text.trim(),
              settlementBank: _selectedBankCode!,
              accountNumber: _bankAccountController.text.trim(),
              percentageCharge: AppConfig.storeSharePercent,
            );
          }
        } catch (e) {
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
        'bank_account': _selectedPaymentMethod == 'bank' 
            ? _bankAccountController.text.trim() 
            : null,
        'mobile_money_number': _selectedPaymentMethod == 'mpesa'
            ? _mpesaController.text.trim()
            : null,
        'category_ids': [],
        'is_open': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client.from('stores').insert(storeData);

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Store created successfully!'),
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

  void _nextStep() {
    if (_currentStep < 2) {
      // Validate current step before proceeding
      if (_currentStep == 0) {
        if (_storeNameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter store name')),
          );
          return;
        }
        if (_descriptionController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter or generate a description')),
          );
          return;
        }
      } else if (_currentStep == 1) {
        if (_latitude == null || _longitude == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select your store location')),
          );
          return;
        }
        final phoneError = _validateKenyanPhone(_phoneController.text);
        if (phoneError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(phoneError)),
          );
          return;
        }
      }
      
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Store'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          
          // Form pages
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStoreInfoStep(),
                  _buildLocationStep(),
                  _buildPaymentStep(),
                ],
              ),
            ),
          ),
          
          // Bottom navigation
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildStepDot(0, 'Store Info'),
          _buildStepLine(0),
          _buildStepDot(1, 'Location'),
          _buildStepLine(1),
          _buildStepDot(2, 'Payment'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryGreen : Colors.grey[300],
            shape: BoxShape.circle,
            border: isCurrent
                ? Border.all(color: AppTheme.primaryGreen, width: 3)
                : null,
          ),
          child: Center(
            child: isActive && !isCurrent
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppTheme.primaryGreen : Colors.grey,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isActive = _currentStep > afterStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: isActive ? AppTheme.primaryGreen : Colors.grey[300],
      ),
    );
  }

  Widget _buildStoreInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.store, size: 64, color: AppTheme.primaryGreen),
          const SizedBox(height: 16),
          Text(
            'Tell us about your store',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'This information will be shown to customers',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textGray,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Store Name
          TextFormField(
            controller: _storeNameController,
            decoration: const InputDecoration(
              labelText: 'Store Name *',
              hintText: 'e.g., Mama Pesa Foods',
              prefixIcon: Icon(Icons.store_outlined),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter store name';
              }
              if (value.trim().length < 3) {
                return 'Store name too short';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // Description with AI generate button
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Description *',
              hintText: 'Describe your store to customers...',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.description_outlined),
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: _isGeneratingDescription
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.auto_awesome,
                          color: AppTheme.primaryGreen,
                        ),
                        tooltip: 'Generate with AI',
                        onPressed: _generateDescriptions,
                      ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter description';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          
          // AI suggestion hint
          InkWell(
            onTap: _generateDescriptions,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 16, color: AppTheme.primaryGreen.withOpacity(0.8)),
                const SizedBox(width: 4),
                Text(
                  'Tap to generate description with AI',
                  style: TextStyle(
                    color: AppTheme.primaryGreen.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.location_on, size: 64, color: AppTheme.primaryGreen),
          const SizedBox(height: 16),
          Text(
            'Where is your store?',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Customers will find you based on this location',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textGray,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Address search
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Store Address *',
              hintText: 'Search for your location...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearchingAddress
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _latitude != null
                      ? const Icon(Icons.check_circle, color: AppTheme.successGreen)
                      : null,
            ),
            onChanged: _onAddressChanged,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter address';
              }
              return null;
            },
          ),
          
          // Address suggestions
          if (_addressSuggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: _addressSuggestions.take(5).map((place) {
                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(
                      place.shortAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      place.fullAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    dense: true,
                    onTap: () => _selectAddress(place),
                  );
                }).toList(),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Current location button
          OutlinedButton.icon(
            onPressed: _requestLocationPermission,
            icon: const Icon(Icons.my_location),
            label: const Text('Use Current Location'),
          ),
          
          // Location status
          if (_latitude != null && _longitude != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.successGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location set: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                        style: const TextStyle(color: AppTheme.successGreen),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Phone number
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number *',
              hintText: '+254 7XX XXX XXX',
              prefixIcon: Icon(Icons.phone_outlined),
              helperText: 'Kenyan number starting with +254 or 07',
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d\+\s\-]')),
            ],
            validator: _validateKenyanPhone,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.payments, size: 64, color: AppTheme.primaryGreen),
          const SizedBox(height: 16),
          Text(
            'How should we pay you?',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll receive payments automatically after each order',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textGray,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Payment method selection
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'mpesa',
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                  title: const Row(
                    children: [
                      Icon(Icons.phone_android, color: AppTheme.successGreen),
                      SizedBox(width: 8),
                      Text('M-Pesa'),
                    ],
                  ),
                  subtitle: const Text('Receive directly to your M-Pesa'),
                  activeColor: AppTheme.primaryGreen,
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  value: 'bank',
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                  title: const Row(
                    children: [
                      Icon(Icons.account_balance, color: AppTheme.primaryGreen),
                      SizedBox(width: 8),
                      Text('Bank Account'),
                    ],
                  ),
                  subtitle: const Text('Transfer to your bank account'),
                  activeColor: AppTheme.primaryGreen,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // M-Pesa input
          if (_selectedPaymentMethod == 'mpesa') ...[
            TextFormField(
              controller: _mpesaController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'M-Pesa Number *',
                hintText: '+254 7XX XXX XXX',
                prefixIcon: Icon(Icons.phone_android),
                helperText: 'Safaricom number registered for M-Pesa',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d\+\s\-]')),
              ],
              validator: _validateMpesaNumber,
            ),
          ],
          
          // Bank input
          if (_selectedPaymentMethod == 'bank') ...[
            DropdownButtonFormField<String>(
              value: _selectedBankCode,
              decoration: const InputDecoration(
                labelText: 'Select Bank *',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
              items: AppConfig.kenyanBanks.map((bank) {
                return DropdownMenuItem<String>(
                  value: bank['code'],
                  child: Text(bank['name']!),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedBankCode = value),
              validator: (value) {
                if (_selectedPaymentMethod == 'bank' && value == null) {
                  return 'Please select a bank';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankAccountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Account Number *',
                hintText: 'Enter your account number',
                prefixIcon: Icon(Icons.credit_card),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: _validateBankAccount,
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Payment split info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'How payments work',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'For each order (e.g., KSh 155):',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                _buildPaymentSplitRow('You receive', 'KSh 100', AppTheme.successGreen),
                _buildPaymentSplitRow('Rider gets', 'KSh 40', Colors.blue),
                _buildPaymentSplitRow('Platform fee', 'KSh 10', Colors.orange),
                _buildPaymentSplitRow('Tax & fees', 'KSh 5', Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSplitRow(String label, String amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(
            amount,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: _currentStep < 2
            ? ElevatedButton(
                onPressed: _nextStep,
                child: const Text('Continue'),
              )
            : ElevatedButton(
                onPressed: _isLoading ? null : _submitOnboarding,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Create My Store'),
              ),
      ),
    );
  }
}
