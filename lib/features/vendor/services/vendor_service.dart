import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/store_model.dart';

class VendorService {
  final _supabase = Supabase.instance.client;

  // Check if vendor has a store setup
  Future<bool> hasStore(String vendorId) async {
    try {
      final response = await _supabase
          .from('stores')
          .select('id')
          .eq('vendor_id', vendorId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Get vendor's store
  Future<StoreModel?> getVendorStore(String vendorId) async {
    try {
      final response = await _supabase
          .from('stores')
          .select()
          .eq('vendor_id', vendorId)
          .maybeSingle();
      
      if (response == null) return null;
      return StoreModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Update store details
  Future<StoreModel> updateStore({
    required String storeId,
    String? name,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    bool? isOpen,
    Map<String, dynamic>? openingHours,
    String? logoUrl,
    String? bannerUrl,
    List<String>? categoryIds,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (address != null) updateData['address'] = address;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (phone != null) updateData['phone'] = phone;
      if (isOpen != null) updateData['is_open'] = isOpen;
      if (openingHours != null) updateData['opening_hours'] = openingHours;
      if (logoUrl != null) updateData['logo_url'] = logoUrl;
      if (bannerUrl != null) updateData['banner_url'] = bannerUrl;
      if (categoryIds != null) updateData['category_ids'] = categoryIds;

      final response = await _supabase
          .from('stores')
          .update(updateData)
          .eq('id', storeId)
          .select()
          .single();

      return StoreModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update store: ${e.toString()}');
    }
  }

  // Toggle store open/closed status
  Future<bool> toggleStoreStatus(String storeId, bool isOpen) async {
    try {
      await _supabase
          .from('stores')
          .update({
            'is_open': isOpen,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', storeId);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get store statistics
  Future<Map<String, dynamic>> getStoreStats(String storeId) async {
    try {
      // Get today's orders
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final ordersResponse = await _supabase
          .from('orders')
          .select('id, total, status')
          .eq('store_id', storeId)
          .gte('created_at', startOfDay.toIso8601String());

      final orders = ordersResponse as List;
      
      double todayRevenue = 0;
      int pendingOrders = 0;
      int completedOrders = 0;

      for (final order in orders) {
        if (order['status'] == 'completed' || order['status'] == 'delivered') {
          todayRevenue += (order['total'] as num).toDouble();
          completedOrders++;
        } else if (order['status'] != 'cancelled') {
          pendingOrders++;
        }
      }

      // Get total orders count
      final totalOrdersResponse = await _supabase
          .from('orders')
          .select('id')
          .eq('store_id', storeId);
      
      final totalOrders = (totalOrdersResponse as List).length;

      // Get products count
      final productsResponse = await _supabase
          .from('products')
          .select('id')
          .eq('store_id', storeId);
      
      final totalProducts = (productsResponse as List).length;

      return {
        'today_revenue': todayRevenue,
        'pending_orders': pendingOrders,
        'completed_orders': completedOrders,
        'total_orders': totalOrders,
        'total_products': totalProducts,
      };
    } catch (e) {
      return {
        'today_revenue': 0.0,
        'pending_orders': 0,
        'completed_orders': 0,
        'total_orders': 0,
        'total_products': 0,
      };
    }
  }

  // Get recent orders for vendor
  Future<List<Map<String, dynamic>>> getRecentOrders(String storeId, {int limit = 10}) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, users!orders_customer_id_fkey(full_name, phone)')
          .eq('store_id', storeId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
      
      return true;
    } catch (e) {
      return false;
    }
  }
}
