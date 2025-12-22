class Product {
  final String id;
  final String name;
  final String mainImage;
  final int lowStockThreshold;
  final List<Variant> variants;
  final int totalStock;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.mainImage,
    required this.lowStockThreshold,
    required this.variants,
    required this.totalStock,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper to get full image URL
  String getMainImageUrl(String baseUrl) {
    if (mainImage.startsWith('http://') || mainImage.startsWith('https://')) {
      return mainImage;
    }
    // Remove /api/v1 from baseUrl and add the image path
    final serverUrl = baseUrl.replaceAll('/api/v1', '');
    return '$serverUrl$mainImage';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      mainImage: (json['mainImage'] ?? '').toString(),
      lowStockThreshold: _parseInt(json['lowStockThreshold'], defaultValue: 10),
      variants: _parseVariants(json['variants']),
      totalStock: _parseInt(json['totalStock'], defaultValue: 0),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }
  
  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
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
      'mainImage': mainImage,
      'lowStockThreshold': lowStockThreshold,
      'variants': variants.map((v) => v.toJson()).toList(),
    };
  }
}

// Roll class for each variant
class Roll {
  final String id;
  final String location; // 'warehouse' or 'magasin'
  final double length; // in meters

  Roll({
    required this.id,
    required this.location,
    required this.length,
  });

  factory Roll.fromJson(Map<String, dynamic> json) {
    return Roll(
      id: (json['_id'] ?? '').toString(),
      location: (json['location'] ?? 'warehouse').toString(),
      length: _parseDouble(json['length']),
    );
  }
  
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'length': length,
    };
  }
}

class Variant {
  final String id;
  final String colorName;
  final String color;
  final String reference;
  final String? image;
  final List<Roll> rolls;
  final double totalStock;

  Variant({
    required this.id,
    required this.colorName,
    required this.color,
    required this.reference,
    this.image,
    required this.rolls,
    required this.totalStock,
  });

  // Helper to get full image URL
  String? getImageUrl(String baseUrl) {
    if (image == null) return null;
    if (image!.startsWith('http://') || image!.startsWith('https://')) {
      return image;
    }
    // Remove /api/v1 from baseUrl and add the image path
    final serverUrl = baseUrl.replaceAll('/api/v1', '');
    return '$serverUrl$image';
  }

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: (json['_id'] ?? '').toString(),
      colorName: (json['colorName'] ?? '').toString(),
      color: (json['color'] ?? '#9333ea').toString(),
      reference: (json['reference'] ?? '').toString(),
      image: json['image']?.toString(),
      rolls: _parseRolls(json['rolls']),
      totalStock: _parseDouble(json['totalStock']),
    );
  }
  
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
  
  static List<Roll> _parseRolls(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];
    return value
        .map((r) {
          try {
            return Roll.fromJson(r as Map<String, dynamic>);
          } catch (e) {
            print('Error parsing roll: $e');
            return null;
          }
        })
        .whereType<Roll>()
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'colorName': colorName,
      'color': color,
      'reference': reference,
      'image': image,
      'rolls': rolls.map((r) => r.toJson()).toList(),
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
