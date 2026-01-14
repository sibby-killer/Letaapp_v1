class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String iconUrl; // Icon asset or URL
  final String? color; // Hex color code
  final bool isActive;
  final bool isCustom; // True if vendor-created
  final String? createdBy; // Vendor ID if custom
  final int displayOrder;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    required this.iconUrl,
    this.color,
    this.isActive = true,
    this.isCustom = false,
    this.createdBy,
    this.displayOrder = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String,
      color: json['color'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isCustom: json['is_custom'] as bool? ?? false,
      createdBy: json['created_by'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'color': color,
      'is_active': isActive,
      'is_custom': isCustom,
      'created_by': createdBy,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
