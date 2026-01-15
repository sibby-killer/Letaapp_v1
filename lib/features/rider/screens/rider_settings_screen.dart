import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/rider_provider.dart';
import '../services/rider_service.dart';

class RiderSettingsScreen extends StatefulWidget {
  const RiderSettingsScreen({super.key});

  @override
  State<RiderSettingsScreen> createState() => _RiderSettingsScreenState();
}

class _RiderSettingsScreenState extends State<RiderSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _overlayEnabled = false;
  bool _isCheckingPermissions = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final riderProvider = context.read<RiderProvider>();
    if (riderProvider.profile != null) {
      setState(() {
        _notificationsEnabled = riderProvider.profile!.notificationsEnabled;
        _overlayEnabled = riderProvider.profile!.overlayPermissionGranted;
      });
    }
    _checkOverlayPermission();
  }

  Future<void> _checkOverlayPermission() async {
    setState(() => _isCheckingPermissions = true);
    final status = await Permission.systemAlertWindow.status;
    setState(() {
      _overlayEnabled = status.isGranted;
      _isCheckingPermissions = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final authProvider = context.read<AuthProvider>();
    final riderProvider = context.read<RiderProvider>();
    
    if (value) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable notifications in settings')),
          );
        }
        return;
      }
    }

    final success = await riderProvider.updateSettings(
      riderId: authProvider.currentUser!.id,
      notificationsEnabled: value,
    );

    if (success) {
      setState(() => _notificationsEnabled = value);
    }
  }

  Future<void> _requestOverlayPermission() async {
    final status = await Permission.systemAlertWindow.request();
    
    if (status.isGranted) {
      final authProvider = context.read<AuthProvider>();
      final riderProvider = context.read<RiderProvider>();
      
      await riderProvider.updateSettings(
        riderId: authProvider.currentUser!.id,
        overlayPermissionGranted: true,
      );
      
      setState(() => _overlayEnabled = true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Overlay permission granted!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'Overlay permission is needed to show delivery notifications over other apps. '
              'Please enable it in your device settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<RiderProvider>(
        builder: (context, riderProvider, _) {
          final profile = riderProvider.profile;
          
          return ListView(
            children: [
              // Notifications Section
              _buildSectionHeader('Notifications'),
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.notifications, color: Colors.blue),
                ),
                title: const Text('Push Notifications'),
                subtitle: const Text('Get notified about new deliveries'),
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
                activeColor: AppTheme.primaryGreen,
              ),
              const Divider(),
              
              // Overlay Permission
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.layers, color: Colors.purple),
                ),
                title: const Text('Display Over Other Apps'),
                subtitle: Text(
                  _overlayEnabled 
                      ? 'Enabled - See delivery popups anytime'
                      : 'Tap to enable delivery popups',
                ),
                trailing: _isCheckingPermissions
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _overlayEnabled ? Icons.check_circle : Icons.error_outline,
                        color: _overlayEnabled ? AppTheme.successGreen : AppTheme.warningOrange,
                      ),
                onTap: _overlayEnabled ? null : _requestOverlayPermission,
              ),
              const Divider(),

              // Transport Section
              _buildSectionHeader('Transport'),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTransportIcon(profile?.transportType),
                    color: Colors.orange,
                  ),
                ),
                title: const Text('Mode of Transport'),
                subtitle: Text(_getTransportName(profile?.transportType)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showTransportPicker(profile?.transportType),
              ),
              const Divider(),

              // Contact Section
              _buildSectionHeader('Contact & Support'),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.phone, color: AppTheme.primaryGreen),
                ),
                title: const Text('Contact Support'),
                subtitle: const Text('Get help with your account'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showContactSupport(),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.report_problem, color: Colors.red),
                ),
                title: const Text('Report an Issue'),
                subtitle: const Text('Report bugs or problems'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showReportIssue(),
              ),
              const Divider(),

              // Payment Section
              _buildSectionHeader('Payment'),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.phone_android, color: Colors.green),
                ),
                title: const Text('M-Pesa Number'),
                subtitle: Text(profile?.mobileMoneyNumber ?? 'Not set'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showUpdateMpesa(profile?.mobileMoneyNumber),
              ),
              const Divider(),

              // Account Section
              _buildSectionHeader('Account'),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.privacy_tip, color: Colors.grey),
                ),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description, color: Colors.grey),
                ),
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const SizedBox(height: 24),
              
              // App version
              Center(
                child: Text(
                  'Leta App v1.0.0',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  IconData _getTransportIcon(TransportType? type) {
    switch (type) {
      case TransportType.skates:
        return Icons.skateboarding;
      case TransportType.bicycle:
        return Icons.pedal_bike;
      case TransportType.motorbike:
        return Icons.two_wheeler;
      default:
        return Icons.help_outline;
    }
  }

  String _getTransportName(TransportType? type) {
    switch (type) {
      case TransportType.skates:
        return 'Skates';
      case TransportType.bicycle:
        return 'Bicycle';
      case TransportType.motorbike:
        return 'Motorbike';
      default:
        return 'Not set';
    }
  }

  void _showTransportPicker(TransportType? current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Transport',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...TransportType.values.map((type) => ListTile(
              leading: Icon(_getTransportIcon(type)),
              title: Text(_getTransportName(type)),
              trailing: current == type
                  ? const Icon(Icons.check, color: AppTheme.primaryGreen)
                  : null,
              onTap: () async {
                Navigator.pop(context);
                final authProvider = context.read<AuthProvider>();
                final riderProvider = context.read<RiderProvider>();
                await riderProvider.updateTransportType(
                  authProvider.currentUser!.id,
                  type,
                );
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showContactSupport() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.support_agent, size: 48, color: AppTheme.primaryGreen),
              const SizedBox(height: 16),
              const Text(
                'Contact Support',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.phone, color: AppTheme.primaryGreen),
                title: const Text('Call Us'),
                subtitle: const Text('+254 700 000 000'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Launch phone call
                },
              ),
              ListTile(
                leading: const Icon(Icons.email, color: Colors.blue),
                title: const Text('Email Us'),
                subtitle: const Text('support@leta.app'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Launch email
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.green),
                title: const Text('WhatsApp'),
                subtitle: const Text('+254 700 000 000'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Launch WhatsApp
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportIssue() {
    final controller = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Report an Issue',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe the issue...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report submitted. Thank you!'),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              },
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateMpesa(String? current) {
    final controller = TextEditingController(text: current ?? '+254');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Update M-Pesa Number',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'M-Pesa Number',
                hintText: '+254 7XX XXX XXX',
                prefixIcon: Icon(Icons.phone_android),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final authProvider = context.read<AuthProvider>();
                final riderProvider = context.read<RiderProvider>();
                await riderProvider.setupPayment(
                  riderId: authProvider.currentUser!.id,
                  riderName: authProvider.currentUser!.fullName,
                  mobileMoneyNumber: controller.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('M-Pesa number updated!'),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
