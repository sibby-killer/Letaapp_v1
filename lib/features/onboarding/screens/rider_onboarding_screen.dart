import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/routes/app_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../rider/providers/rider_provider.dart';
import '../../rider/services/rider_service.dart';

class RiderOnboardingScreen extends StatefulWidget {
  const RiderOnboardingScreen({super.key});

  @override
  State<RiderOnboardingScreen> createState() => _RiderOnboardingScreenState();
}

class _RiderOnboardingScreenState extends State<RiderOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final _mpesaController = TextEditingController();
  
  int _currentStep = 0;
  TransportType _selectedTransport = TransportType.bicycle;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mpesaController.text = '+254';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _mpesaController.dispose();
    super.dispose();
  }

  String? _validateMpesaNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter M-Pesa number';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    if (cleaned.startsWith('+254')) {
      if (cleaned.length != 13) return 'Enter valid number (+254XXXXXXXXX)';
    } else if (cleaned.startsWith('0')) {
      if (cleaned.length != 10) return 'Enter valid number (07XXXXXXXX)';
    } else {
      return 'Number must start with +254 or 0';
    }
    return null;
  }

  Future<void> _completeOnboarding() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final riderProvider = context.read<RiderProvider>();
      final riderId = authProvider.currentUser!.id;
      final riderName = authProvider.currentUser!.fullName;

      // Create rider profile
      final created = await riderProvider.createProfile(
        riderId: riderId,
        transportType: _selectedTransport,
        mobileMoneyNumber: _mpesaController.text.trim(),
      );

      if (!created) {
        throw Exception(riderProvider.errorMessage ?? 'Failed to create profile');
      }

      // Setup payment
      await riderProvider.setupPayment(
        riderId: riderId,
        riderName: riderName,
        mobileMoneyNumber: _mpesaController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Profile created! Welcome aboard!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.of(context).pushReplacementNamed(AppRouter.riderDashboard);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _nextStep() {
    if (_currentStep < 1) {
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
        title: const Text('Rider Setup'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
        automaticallyImplyLeading: false,
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
                  _buildTransportStep(),
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
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      child: Row(
        children: [
          _buildStepDot(0, 'Transport'),
          _buildStepLine(0),
          _buildStepDot(1, 'Payment'),
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
            fontSize: 12,
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

  Widget _buildTransportStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.delivery_dining, size: 64, color: AppTheme.primaryGreen),
          const SizedBox(height: 16),
          Text(
            'How will you deliver?',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Select your mode of transport',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textGray,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Transport options
          _buildTransportOption(
            type: TransportType.skates,
            icon: Icons.skateboarding,
            title: 'Skates',
            description: 'Roller skates or skateboard',
            color: Colors.purple,
          ),
          const SizedBox(height: 16),
          _buildTransportOption(
            type: TransportType.bicycle,
            icon: Icons.pedal_bike,
            title: 'Bicycle',
            description: 'Pedal bike or e-bike',
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildTransportOption(
            type: TransportType.motorbike,
            icon: Icons.two_wheeler,
            title: 'Motorbike',
            description: 'Boda boda or motorcycle',
            color: Colors.orange,
          ),
          
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can change your transport type later in settings',
                    style: TextStyle(color: Colors.blue, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportOption({
    required TransportType type,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final isSelected = _selectedTransport == type;
    
    return InkWell(
      onTap: () => setState(() => _selectedTransport = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? color.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Radio<TransportType>(
              value: type,
              groupValue: _selectedTransport,
              onChanged: (value) => setState(() => _selectedTransport = value!),
              activeColor: color,
            ),
          ],
        ),
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
            'You\'ll receive payments directly to M-Pesa',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textGray,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // M-Pesa card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[700]!, Colors.green[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.phone_android,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'M-Pesa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Instant payments after each delivery',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // M-Pesa number input
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
          const SizedBox(height: 32),
          
          // Earnings info
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
                      'How earnings work',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildEarningsRow('Per delivery', 'KSh 40 average'),
                _buildEarningsRow('Paid', 'After each delivery'),
                _buildEarningsRow('Bonus', 'Peak hours + tips'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
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
        child: _currentStep < 1
            ? ElevatedButton(
                onPressed: _nextStep,
                child: const Text('Continue'),
              )
            : ElevatedButton(
                onPressed: _isLoading ? null : _completeOnboarding,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Start Delivering'),
              ),
      ),
    );
  }
}
