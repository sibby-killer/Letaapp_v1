class ProductModel {
  final String id;
  final String storeId;
  final String categoryId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final List<String>? imageUrls;
  final bool isAvailable;
  final int stock;
  final String? unit; // e.g., "kg", "piece", "liter"
  final Map<String, dynamic>? variants; // e.g., sizes, colors
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    required this.storeId,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.imageUrls,
    this.isAvailable = true,
    this.stock = 0,
    this.unit,
    this.variants,
    required this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : null,
      isAvailable: json['is_available'] as bool? ?? true,
      stock: json['stock'] as int? ?? 0,
      unit: json['unit'] as String?,
      variants: json['variants'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'image_urls': imageUrls,
      'is_available': isAvailable,
      'stock': stock,
      'unit': unit,
      'variants': variants,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
