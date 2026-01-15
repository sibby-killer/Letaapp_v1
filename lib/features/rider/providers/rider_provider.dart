import 'package:flutter/material.dart';
import '../services/rider_service.dart';
import '../../payment/services/payment_service.dart';
import '../../../core/config/app_config.dart';

class RiderProvider extends ChangeNotifier {
  final RiderService _riderService = RiderService();
  final PaymentService _paymentService = PaymentService();
  
  RiderProfile? _profile;
  Map<String, dynamic>? _earnings;
  List<Map<String, dynamic>> _availableDeliveries = [];
  List<Map<String, dynamic>> _activeDeliveries = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasCheckedProfile = false;

  RiderProfile? get profile => _profile;
  Map<String, dynamic>? get earnings => _earnings;
  List<Map<String, dynamic>> get availableDeliveries => _availableDeliveries;
  List<Map<String, dynamic>> get activeDeliveries => _activeDeliveries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasProfile => _profile != null;
  bool get hasCheckedProfile => _hasCheckedProfile;
  bool get isOnline => _profile?.isOnline ?? false;
  int get profileCompletion => _profile?.profileCompletionPercent ?? 0;

  // Check if rider has profile and load it
  Future<bool> checkAndLoadProfile(String riderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _riderService.getRiderProfile(riderId);
      _hasCheckedProfile = true;
      _isLoading = false;
      notifyListeners();
      return _profile != null;
    } catch (e) {
      _errorMessage = e.toString();
      _hasCheckedProfile = true;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Create rider profile
  Future<bool> createProfile({
    required String riderId,
    required TransportType transportType,
    String? mobileMoneyNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _riderService.createProfile(
        riderId: riderId,
        transportType: transportType,
        mobileMoneyNumber: mobileMoneyNumber,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update profile with payment setup
  Future<bool> setupPayment({
    required String riderId,
    required String riderName,
    required String mobileMoneyNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? subaccountId;
      
      // Try to create Paystack subaccount if configured
      if (AppConfig.isPaystackConfigured) {
        try {
          await _paymentService.initialize();
          subaccountId = await _paymentService.createRiderSubaccount(
            riderName: riderName,
            phoneNumber: mobileMoneyNumber,
          );
        } catch (e) {
          debugPrint('Paystack setup skipped: $e');
        }
      }

      _profile = await _riderService.updateProfile(
        riderId: riderId,
        mobileMoneyNumber: mobileMoneyNumber,
        paystackSubaccountId: subaccountId,
      );
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update transport type
  Future<bool> updateTransportType(String riderId, TransportType type) async {
    try {
      _profile = await _riderService.updateProfile(
        riderId: riderId,
        transportType: type,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Toggle online status
  Future<bool> toggleOnlineStatus(String riderId, {double? latitude, double? longitude}) async {
    if (_profile == null) return false;

    final newStatus = !_profile!.isOnline;
    final success = await _riderService.setOnlineStatus(
      riderId,
      newStatus,
      latitude: latitude,
      longitude: longitude,
    );

    if (success) {
      _profile = _profile!.copyWith(
        isOnline: newStatus,
        latitude: latitude ?? _profile!.latitude,
        longitude: longitude ?? _profile!.longitude,
      );
      notifyListeners();

      // If going online, load available deliveries
      if (newStatus) {
        await loadAvailableDeliveries(riderId, latitude: latitude, longitude: longitude);
      }
    }

    return success;
  }

  // Update location
  Future<void> updateLocation(String riderId, double latitude, double longitude) async {
    await _riderService.updateLocation(riderId, latitude, longitude);
    if (_profile != null) {
      _profile = _profile!.copyWith(latitude: latitude, longitude: longitude);
      notifyListeners();
    }
  }

  // Load earnings
  Future<void> loadEarnings(String riderId) async {
    try {
      _earnings = await _riderService.getRiderEarnings(riderId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load earnings: $e');
    }
  }

  // Load available deliveries
  Future<void> loadAvailableDeliveries(String riderId, {double? latitude, double? longitude}) async {
    try {
      _availableDeliveries = await _riderService.getAvailableDeliveries(
        riderId,
        latitude: latitude,
        longitude: longitude,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load available deliveries: $e');
    }
  }

  // Load active deliveries
  Future<void> loadActiveDeliveries(String riderId) async {
    try {
      _activeDeliveries = await _riderService.getActiveDeliveries(riderId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load active deliveries: $e');
    }
  }

  // Accept delivery
  Future<bool> acceptDelivery(String orderId, String riderId) async {
    final success = await _riderService.acceptDelivery(orderId, riderId);
    if (success) {
      await loadAvailableDeliveries(riderId);
      await loadActiveDeliveries(riderId);
    }
    return success;
  }

  // Update delivery status
  Future<bool> updateDeliveryStatus(String orderId, String status, String riderId) async {
    final success = await _riderService.updateDeliveryStatus(orderId, status);
    if (success) {
      await loadActiveDeliveries(riderId);
      if (status == 'delivered') {
        await loadEarnings(riderId);
      }
    }
    return success;
  }

  // Update settings
  Future<bool> updateSettings({
    required String riderId,
    bool? notificationsEnabled,
    bool? overlayPermissionGranted,
  }) async {
    try {
      _profile = await _riderService.updateProfile(
        riderId: riderId,
        notificationsEnabled: notificationsEnabled,
        overlayPermissionGranted: overlayPermissionGranted,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear state
  void clear() {
    _profile = null;
    _earnings = null;
    _availableDeliveries = [];
    _activeDeliveries = [];
    _hasCheckedProfile = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
