class StoreModel {
  final String id;
  final String vendorId;
  final String name;
  final String description;
  final String? logoUrl;
  final String? bannerUrl;
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;
  final bool isOpen;
  final Map<String, dynamic>? openingHours;
  final String paystackSubaccountId; // For split payment
  final String? bankAccount;
  final String? mobileMoneyNumber;
  final List<String> categoryIds;
  final double rating;
  final int totalOrders;
  final DateTime createdAt;
  final DateTime? updatedAt;

  StoreModel({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.description,
    this.logoUrl,
    this.bannerUrl,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.isOpen = true,
    this.openingHours,
    required this.paystackSubaccountId,
    this.bankAccount,
    this.mobileMoneyNumber,
    required this.categoryIds,
    this.rating = 0.0,
    this.totalOrders = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      logoUrl: json['logo_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phone: json['phone'] as String?,
      isOpen: json['is_open'] as bool? ?? true,
      openingHours: json['opening_hours'] as Map<String, dynamic>?,
      paystackSubaccountId: json['paystack_subaccount_id'] as String,
      bankAccount: json['bank_account'] as String?,
      mobileMoneyNumber: json['mobile_money_number'] as String?,
      categoryIds: List<String>.from(json['category_ids'] ?? []),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['total_orders'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'name': name,
      'description': description,
      'logo_url': logoUrl,
      'banner_url': bannerUrl,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'is_open': isOpen,
      'opening_hours': openingHours,
      'paystack_subaccount_id': paystackSubaccountId,
      'bank_account': bankAccount,
      'mobile_money_number': mobileMoneyNumber,
      'category_ids': categoryIds,
      'rating': rating,
      'total_orders': totalOrders,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
