import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  static const String baseUrl = 'http://api.ecommercetn.me/api/v1';

  // Get all products
  Future<List<Product>> getProducts({String? category, String? search}) async {
    try {
      var uri = Uri.parse('$baseUrl/products');
      final queryParams = <String, String>{};
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] == null) {
          return [];
        }
        final products = (data['data'] as List)
            .map((p) {
              try {
                return Product.fromJson(p as Map<String, dynamic>);
              } catch (e) {
                print('Error parsing product: $e');
                print('Product data: $p');
                return null;
              }
            })
            .whereType<Product>()
            .toList();
        return products;
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  // Get product by ID
  Future<Product> getProductById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/$id'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Product.fromJson(data['data']);
      } else {
        throw Exception('Failed to load product');
      }
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }

  // Get stats
  Future<Stats> getStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stats/dashboard'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Stats.fromJson(data['data']);
      } else {
        throw Exception('Failed to load stats');
      }
    } catch (e) {
      throw Exception('Error fetching stats: $e');
    }
  }

  // Get categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/categories'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  // Create product
  Future<Product> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(productData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Product.fromJson(data['data']);
      } else {
        throw Exception('Failed to create product');
      }
    } catch (e) {
      throw Exception('Error creating product: $e');
    }
  }

  // Update stock
  Future<void> updateStock({
    required String productId,
    required String variantId,
    required String operation,
    required int quantity,
    String? reason,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/products/$productId/variants/$variantId/stock'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'operation': operation,
          'quantity': quantity,
          'reason': reason,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update stock');
      }
    } catch (e) {
      throw Exception('Error updating stock: $e');
    }
  }

  // Add variant
  Future<void> addVariant(String productId, Map<String, dynamic> variantData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products/$productId/variants'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(variantData),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to add variant');
      }
    } catch (e) {
      throw Exception('Error adding variant: $e');
    }
  }

  // Delete variant
  Future<void> deleteVariant(String productId, String variantId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$productId/variants/$variantId'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete variant');
      }
    } catch (e) {
      throw Exception('Error deleting variant: $e');
    }
  }
}
