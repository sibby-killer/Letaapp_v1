class OrderModel {
  final String id;
  final String customerId;
  final String storeId;
  final String? riderId;
  final String orderNumber;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double platformFee;
  final double tax;
  final double total;
  final String status; // pending, confirmed, preparing, ready, picked_up, delivering, completed, cancelled
  final String deliveryMode; // rider, self_delivery
  final String paymentStatus; // pending, paid, refunded
  final String? paystackReference;
  final DeliveryAddress deliveryAddress;
  final DateTime? estimatedDeliveryTime;
  final DateTime? completedAt;
  final bool customerConfirmed; // Digital Handshake
  final bool riderConfirmed; // Digital Handshake
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.storeId,
    this.riderId,
    required this.orderNumber,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.platformFee,
    required this.tax,
    required this.total,
    required this.status,
    required this.deliveryMode,
    required this.paymentStatus,
    this.paystackReference,
    required this.deliveryAddress,
    this.estimatedDeliveryTime,
    this.completedAt,
    this.customerConfirmed = false,
    this.riderConfirmed = false,
    this.cancellationReason,
    required this.createdAt,
    this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      storeId: json['store_id'] as String,
      riderId: json['rider_id'] as String?,
      orderNumber: json['order_number'] as String,
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
      platformFee: (json['platform_fee'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      status: json['status'] as String,
      deliveryMode: json['delivery_mode'] as String,
      paymentStatus: json['payment_status'] as String,
      paystackReference: json['paystack_reference'] as String?,
      deliveryAddress: DeliveryAddress.fromJson(
          json['delivery_address'] as Map<String, dynamic>),
      estimatedDeliveryTime: json['estimated_delivery_time'] != null
          ? DateTime.parse(json['estimated_delivery_time'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      customerConfirmed: json['customer_confirmed'] as bool? ?? false,
      riderConfirmed: json['rider_confirmed'] as bool? ?? false,
      cancellationReason: json['cancellation_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'store_id': storeId,
      'rider_id': riderId,
      'order_number': orderNumber,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'platform_fee': platformFee,
      'tax': tax,
      'total': total,
      'status': status,
      'delivery_mode': deliveryMode,
      'payment_status': paymentStatus,
      'paystack_reference': paystackReference,
      'delivery_address': deliveryAddress.toJson(),
      'estimated_delivery_time': estimatedDeliveryTime?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'customer_confirmed': customerConfirmed,
      'rider_confirmed': riderConfirmed,
      'cancellation_reason': cancellationReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String? imageUrl;
  final Map<String, dynamic>? selectedVariants;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.selectedVariants,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      imageUrl: json['image_url'] as String?,
      selectedVariants: json['selected_variants'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'image_url': imageUrl,
      'selected_variants': selectedVariants,
    };
  }

  double get totalPrice => price * quantity;
}

class DeliveryAddress {
  final String address;
  final double latitude;
  final double longitude;
  final String? apartmentNumber;
  final String? instructions;

  DeliveryAddress({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.apartmentNumber,
    this.instructions,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      apartmentNumber: json['apartment_number'] as String?,
      instructions: json['instructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'apartment_number': apartmentNumber,
      'instructions': instructions,
    };
  }
}
