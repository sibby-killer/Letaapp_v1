import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/order_model.dart';
import '../../../core/database/local_database.dart';
import '../../../core/services/service_locator.dart';

class OrderProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final LocalDatabase _localDb = getIt<LocalDatabase>();

  List<OrderModel> _orders = [];
  OrderModel? _currentOrder;
  bool _isLoading = false;
  String? _errorMessage;

  List<OrderModel> get orders => _orders;
  OrderModel? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Create new order
  Future<OrderModel?> createOrder({
    required String customerId,
    required String storeId,
    required List<OrderItem> items,
    required double subtotal,
    required double deliveryFee,
    required double platformFee,
    required double tax,
    required double total,
    required String deliveryMode,
    required DeliveryAddress deliveryAddress,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Generate order number
      final orderNumber = await _generateOrderNumber();

      final orderData = {
        'customer_id': customerId,
        'store_id': storeId,
        'order_number': orderNumber,
        'items': items.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'platform_fee': platformFee,
        'tax': tax,
        'total': total,
        'status': 'pending',
        'delivery_mode': deliveryMode,
        'payment_status': 'pending',
        'delivery_address': deliveryAddress.toJson(),
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      final order = OrderModel.fromJson(response);
      
      // Cache order locally
      await _localDb.cacheOrder(order);
      
      _currentOrder = order;
      _orders.insert(0, order);
      _isLoading = false;
      notifyListeners();
      
      return order;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Fetch user orders
  Future<void> fetchOrders(String userId, String role) async {
    _isLoading = true;
    notifyListeners();

    try {
      List<dynamic> response;

      if (role == 'customer') {
        response = await _supabase
            .from('orders')
            .select()
            .eq('customer_id', userId)
            .order('created_at', ascending: false);
      } else if (role == 'vendor') {
        // Fetch orders for vendor's stores
        final stores = await _supabase
            .from('stores')
            .select('id')
            .eq('vendor_id', userId);
        
        final storeIds = stores.map((s) => s['id']).toList();
        
        if (storeIds.isEmpty) {
          response = [];
        } else {
          response = await _supabase
              .from('orders')
              .select()
              .inFilter('store_id', storeIds)
              .order('created_at', ascending: false);
        }
      } else if (role == 'rider') {
        response = await _supabase
            .from('orders')
            .select()
            .eq('rider_id', userId)
            .order('created_at', ascending: false);
      } else {
        response = [];
      }

      _orders = response.map((json) => OrderModel.fromJson(json)).toList();
      
      // Cache orders locally
      for (final order in _orders) {
        await _localDb.cacheOrder(order);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Try loading from cache
      if (role == 'customer') {
        _orders = await _localDb.getCachedOrders(userId);
      }
      
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      // Update local state
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final updatedOrder = OrderModel.fromJson({
          ..._orders[index].toJson(),
          'status': newStatus,
          'updated_at': DateTime.now().toIso8601String(),
        });
        _orders[index] = updatedOrder;
        
        if (_currentOrder?.id == orderId) {
          _currentOrder = updatedOrder;
        }
        
        // Update cache
        await _localDb.cacheOrder(updatedOrder);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  // Digital Handshake: Customer confirms receipt
  Future<bool> customerConfirmReceipt(String orderId) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'customer_confirmed': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      // Check if both parties confirmed
      final order = await _supabase
          .from('orders')
          .select()
          .eq('id', orderId)
          .single();

      if (order['customer_confirmed'] && order['rider_confirmed']) {
        // Both confirmed - mark as completed
        await updateOrderStatus(orderId, 'completed');
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  // Digital Handshake: Rider confirms delivery
  Future<bool> riderConfirmDelivery(String orderId) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'rider_confirmed': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  // Assign rider to order
  Future<bool> assignRider(String orderId, String riderId) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'rider_id': riderId,
            'status': 'confirmed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  // Generate unique order number
  Future<String> _generateOrderNumber() async {
    try {
      final response = await _supabase.rpc('generate_order_number');
      return response as String;
    } catch (e) {
      // Fallback: generate locally if RPC fails
      final now = DateTime.now();
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final random = (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
      return 'ORD-$dateStr-$random';
    }
  }

  // Get order by ID
  Future<OrderModel?> getOrder(String orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('id', orderId)
          .single();

      return OrderModel.fromJson(response);
    } catch (e) {
      // Try cache
      return await _localDb.getCachedOrder(orderId);
    }
  }
}
