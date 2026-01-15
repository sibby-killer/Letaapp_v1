import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';

enum TransportType { skates, bicycle, motorbike }

class RiderProfile {
  final String id;
  final String riderId;
  final TransportType transportType;
  final String? mobileMoneyNumber;
  final String? paystackSubaccountId;
  final bool isVerified;
  final bool isOnline;
  final double? latitude;
  final double? longitude;
  final double totalEarnings;
  final int totalDeliveries;
  final double rating;
  final int ratingCount;
  final bool notificationsEnabled;
  final bool overlayPermissionGranted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RiderProfile({
    required this.id,
    required this.riderId,
    required this.transportType,
    this.mobileMoneyNumber,
    this.paystackSubaccountId,
    this.isVerified = false,
    this.isOnline = false,
    this.latitude,
    this.longitude,
    this.totalEarnings = 0.0,
    this.totalDeliveries = 0,
    this.rating = 5.0,
    this.ratingCount = 0,
    this.notificationsEnabled = true,
    this.overlayPermissionGranted = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory RiderProfile.fromJson(Map<String, dynamic> json) {
    return RiderProfile(
      id: json['id'] as String,
      riderId: json['rider_id'] as String,
      transportType: TransportType.values.firstWhere(
        (e) => e.name == (json['transport_type'] as String? ?? 'bicycle'),
        orElse: () => TransportType.bicycle,
      ),
      mobileMoneyNumber: json['mobile_money_number'] as String?,
      paystackSubaccountId: json['paystack_subaccount_id'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      isOnline: json['is_online'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      totalDeliveries: json['total_deliveries'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      ratingCount: json['rating_count'] as int? ?? 0,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      overlayPermissionGranted: json['overlay_permission_granted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rider_id': riderId,
      'transport_type': transportType.name,
      'mobile_money_number': mobileMoneyNumber,
      'paystack_subaccount_id': paystackSubaccountId,
      'is_verified': isVerified,
      'is_online': isOnline,
      'latitude': latitude,
      'longitude': longitude,
      'total_earnings': totalEarnings,
      'total_deliveries': totalDeliveries,
      'rating': rating,
      'rating_count': ratingCount,
      'notifications_enabled': notificationsEnabled,
      'overlay_permission_granted': overlayPermissionGranted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Calculate profile completion percentage
  int get profileCompletionPercent {
    int completed = 0;
    int total = 5;
    
    if (mobileMoneyNumber != null && mobileMoneyNumber!.isNotEmpty) completed++;
    if (paystackSubaccountId != null && paystackSubaccountId!.isNotEmpty) completed++;
    if (notificationsEnabled) completed++;
    if (overlayPermissionGranted) completed++;
    if (isVerified) completed++;
    
    return ((completed / total) * 100).round();
  }

  RiderProfile copyWith({
    String? id,
    String? riderId,
    TransportType? transportType,
    String? mobileMoneyNumber,
    String? paystackSubaccountId,
    bool? isVerified,
    bool? isOnline,
    double? latitude,
    double? longitude,
    double? totalEarnings,
    int? totalDeliveries,
    double? rating,
    int? ratingCount,
    bool? notificationsEnabled,
    bool? overlayPermissionGranted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RiderProfile(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      transportType: transportType ?? this.transportType,
      mobileMoneyNumber: mobileMoneyNumber ?? this.mobileMoneyNumber,
      paystackSubaccountId: paystackSubaccountId ?? this.paystackSubaccountId,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      overlayPermissionGranted: overlayPermissionGranted ?? this.overlayPermissionGranted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class RiderService {
  final _supabase = Supabase.instance.client;

  // Check if rider has profile setup
  Future<bool> hasProfile(String riderId) async {
    try {
      final response = await _supabase
          .from('rider_profiles')
          .select('id')
          .eq('rider_id', riderId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Get rider profile
  Future<RiderProfile?> getRiderProfile(String riderId) async {
    try {
      final response = await _supabase
          .from('rider_profiles')
          .select()
          .eq('rider_id', riderId)
          .maybeSingle();
      
      if (response == null) return null;
      return RiderProfile.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Create rider profile
  Future<RiderProfile> createProfile({
    required String riderId,
    required TransportType transportType,
    String? mobileMoneyNumber,
  }) async {
    try {
      final data = {
        'rider_id': riderId,
        'transport_type': transportType.name,
        'mobile_money_number': mobileMoneyNumber,
        'is_verified': false,
        'is_online': false,
        'total_earnings': 0.0,
        'total_deliveries': 0,
        'rating': 5.0,
        'rating_count': 0,
        'notifications_enabled': true,
        'overlay_permission_granted': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('rider_profiles')
          .insert(data)
          .select()
          .single();

      return RiderProfile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create rider profile: ${e.toString()}');
    }
  }

  // Update rider profile
  Future<RiderProfile> updateProfile({
    required String riderId,
    TransportType? transportType,
    String? mobileMoneyNumber,
    String? paystackSubaccountId,
    bool? isVerified,
    bool? notificationsEnabled,
    bool? overlayPermissionGranted,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (transportType != null) updateData['transport_type'] = transportType.name;
      if (mobileMoneyNumber != null) updateData['mobile_money_number'] = mobileMoneyNumber;
      if (paystackSubaccountId != null) updateData['paystack_subaccount_id'] = paystackSubaccountId;
      if (isVerified != null) updateData['is_verified'] = isVerified;
      if (notificationsEnabled != null) updateData['notifications_enabled'] = notificationsEnabled;
      if (overlayPermissionGranted != null) updateData['overlay_permission_granted'] = overlayPermissionGranted;

      final response = await _supabase
          .from('rider_profiles')
          .update(updateData)
          .eq('rider_id', riderId)
          .select()
          .single();

      return RiderProfile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update rider profile: ${e.toString()}');
    }
  }

  // Set rider online/offline status
  Future<bool> setOnlineStatus(String riderId, bool isOnline, {double? latitude, double? longitude}) async {
    try {
      final updateData = <String, dynamic>{
        'is_online': isOnline,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;

      await _supabase
          .from('rider_profiles')
          .update(updateData)
          .eq('rider_id', riderId);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Update rider location
  Future<bool> updateLocation(String riderId, double latitude, double longitude) async {
    try {
      await _supabase
          .from('rider_profiles')
          .update({
            'latitude': latitude,
            'longitude': longitude,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('rider_id', riderId);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get rider earnings
  Future<Map<String, dynamic>> getRiderEarnings(String riderId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final startOfMonth = DateTime(today.year, today.month, 1);

      // Get all earnings
      final response = await _supabase
          .from('rider_earnings')
          .select()
          .eq('rider_id', riderId)
          .order('created_at', ascending: false);

      final earnings = response as List;
      
      double todayEarnings = 0;
      double weekEarnings = 0;
      double monthEarnings = 0;
      double totalEarnings = 0;

      for (final earning in earnings) {
        final amount = (earning['amount'] as num).toDouble();
        final createdAt = DateTime.parse(earning['created_at']);
        
        totalEarnings += amount;
        
        if (createdAt.isAfter(startOfDay)) {
          todayEarnings += amount;
        }
        if (createdAt.isAfter(startOfWeek)) {
          weekEarnings += amount;
        }
        if (createdAt.isAfter(startOfMonth)) {
          monthEarnings += amount;
        }
      }

      return {
        'today': todayEarnings,
        'this_week': weekEarnings,
        'this_month': monthEarnings,
        'total': totalEarnings,
        'recent': earnings.take(20).toList(),
      };
    } catch (e) {
      return {
        'today': 0.0,
        'this_week': 0.0,
        'this_month': 0.0,
        'total': 0.0,
        'recent': [],
      };
    }
  }

  // Get available deliveries for rider
  Future<List<Map<String, dynamic>>> getAvailableDeliveries(String riderId, {double? latitude, double? longitude}) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, stores(name, address, latitude, longitude)')
          .eq('status', 'ready_for_pickup')
          .isFilter('rider_id', null)
          .order('created_at', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Accept a delivery
  Future<bool> acceptDelivery(String orderId, String riderId) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'rider_id': riderId,
            'status': 'picked_up',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .isFilter('rider_id', null); // Only if not already taken

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get rider's active deliveries
  Future<List<Map<String, dynamic>>> getActiveDeliveries(String riderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, stores(name, address, latitude, longitude), users!orders_customer_id_fkey(full_name, phone)')
          .eq('rider_id', riderId)
          .inFilter('status', ['picked_up', 'in_transit'])
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Get rider's completed deliveries
  Future<List<Map<String, dynamic>>> getCompletedDeliveries(String riderId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, stores(name, address)')
          .eq('rider_id', riderId)
          .eq('status', 'delivered')
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Update delivery status
  Future<bool> updateDeliveryStatus(String orderId, String status) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
            if (status == 'delivered') 'delivered_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      return true;
    } catch (e) {
      return false;
    }
  }
}
