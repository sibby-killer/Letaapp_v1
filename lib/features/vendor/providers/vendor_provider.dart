import 'package:flutter/material.dart';
import '../../../core/models/store_model.dart';
import '../services/vendor_service.dart';

class VendorProvider extends ChangeNotifier {
  final VendorService _vendorService = VendorService();
  
  StoreModel? _store;
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasCheckedStore = false;

  StoreModel? get store => _store;
  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasStore => _store != null;
  bool get hasCheckedStore => _hasCheckedStore;

  // Check if vendor has a store and load it
  Future<bool> checkAndLoadStore(String vendorId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _store = await _vendorService.getVendorStore(vendorId);
      _hasCheckedStore = true;
      _isLoading = false;
      notifyListeners();
      return _store != null;
    } catch (e) {
      _errorMessage = e.toString();
      _hasCheckedStore = true;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load store statistics
  Future<void> loadStats() async {
    if (_store == null) return;

    try {
      _stats = await _vendorService.getStoreStats(_store!.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load stats: $e');
    }
  }

  // Toggle store open/closed
  Future<bool> toggleStoreStatus() async {
    if (_store == null) return false;

    final newStatus = !_store!.isOpen;
    final success = await _vendorService.toggleStoreStatus(_store!.id, newStatus);
    
    if (success) {
      // Reload store to get updated status
      await checkAndLoadStore(_store!.vendorId);
    }
    
    return success;
  }

  // Update store details
  Future<bool> updateStore({
    String? name,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    Map<String, dynamic>? openingHours,
    String? logoUrl,
    String? bannerUrl,
    List<String>? categoryIds,
  }) async {
    if (_store == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _store = await _vendorService.updateStore(
        storeId: _store!.id,
        name: name,
        description: description,
        address: address,
        latitude: latitude,
        longitude: longitude,
        phone: phone,
        openingHours: openingHours,
        logoUrl: logoUrl,
        bannerUrl: bannerUrl,
        categoryIds: categoryIds,
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

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    final success = await _vendorService.updateOrderStatus(orderId, status);
    if (success) {
      await loadStats(); // Refresh stats
    }
    return success;
  }

  // Get recent orders
  Future<List<Map<String, dynamic>>> getRecentOrders({int limit = 10}) async {
    if (_store == null) return [];
    return await _vendorService.getRecentOrders(_store!.id, limit: limit);
  }

  // Clear provider state (on logout)
  void clear() {
    _store = null;
    _stats = null;
    _hasCheckedStore = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
