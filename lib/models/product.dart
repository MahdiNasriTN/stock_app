class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final String material;
  final double width;
  final String mainImage;
  final List<String> tags;
  final bool isFeatured;
  final int lowStockThreshold;
  final List<Variant> variants;
  final int totalStock;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.material,
    required this.width,
    required this.mainImage,
    required this.tags,
    required this.isFeatured,
    required this.lowStockThreshold,
    required this.variants,
    required this.totalStock,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      material: (json['material'] ?? '').toString(),
      width: _parseDouble(json['width']),
      mainImage: (json['mainImage'] ?? '').toString(),
      tags: _parseList(json['tags']),
      isFeatured: json['isFeatured'] == true,
      lowStockThreshold: _parseInt(json['lowStockThreshold'], defaultValue: 10),
      variants: _parseVariants(json['variants']),
      totalStock: _parseInt(json['totalStock'], defaultValue: 0),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }
  
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
  
  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
  
  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
  
  static List<Variant> _parseVariants(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];
    return value
        .map((v) {
          try {
            return Variant.fromJson(v as Map<String, dynamic>);
          } catch (e) {
            print('Error parsing variant: $e');
            return null;
          }
        })
        .whereType<Variant>()
        .toList();
  }
  
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'material': material,
      'width': width,
      'mainImage': mainImage,
      'tags': tags,
      'isFeatured': isFeatured,
      'lowStockThreshold': lowStockThreshold,
      'variants': variants.map((v) => v.toJson()).toList(),
    };
  }
}

class Variant {
  final String id;
  final String name;
  final String colorName;
  final String color;
  final int stockQuantity;

  Variant({
    required this.id,
    required this.name,
    required this.colorName,
    required this.color,
    required this.stockQuantity,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      colorName: (json['colorName'] ?? '').toString(),
      color: (json['color'] ?? '#9333ea').toString(),
      stockQuantity: _parseIntVariant(json['stockQuantity']),
    );
  }
  
  static int _parseIntVariant(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'colorName': colorName,
      'color': color,
      'stockQuantity': stockQuantity,
    };
  }
}

class Stats {
  final int totalProducts;
  final int totalStock;
  final int lowStockCount;
  final List<CategoryBreakdown> categoryBreakdown;

  Stats({
    required this.totalProducts,
    required this.totalStock,
    required this.lowStockCount,
    required this.categoryBreakdown,
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    final overview = json['overview'] ?? {};
    final stockOverview = json['stockOverview'] ?? {};
    final categoryData = json['categoryBreakdown'] ?? [];
    
    return Stats(
      totalProducts: overview['totalProducts'] ?? 0,
      totalStock: stockOverview['totalStock'] ?? 0,
      lowStockCount: stockOverview['lowStockCount'] ?? 0,
      categoryBreakdown: (categoryData as List<dynamic>)
          .map((c) => CategoryBreakdown.fromJson(c))
          .toList(),
    );
  }
}

class CategoryBreakdown {
  final String category;
  final int count;

  CategoryBreakdown({
    required this.category,
    required this.count,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      category: json['category'] ?? json['_id'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}
