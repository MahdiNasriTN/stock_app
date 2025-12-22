import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  static bool isDevelopment = false;
  // PHYSICAL DEVICE: Use your computer's WiFi IP
  // Make sure your phone is connected to the SAME WiFi network as your computer
  // If using Ethernet, try 192.168.0.146 instead
  static String baseUrl = isDevelopment
      ? 'http://192.168.0.146:5000/api/v1'
      : 'http://api.ecommercetn.me/api/v1';
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

      print('🔵 Making HTTP GET request to: $uri');
      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('❌ Request TIMEOUT after 10 seconds');
              throw Exception(
                'Connection timeout - check if backend is running',
              );
            },
          );


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
        throw Exception('Failed to load products: ${response.statusCode}');
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
      final response = await http.get(
        Uri.parse('$baseUrl/products/categories'),
      );

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

  // Update product
  Future<Product> updateProduct(String productId, Map<String, dynamic> productData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/products/$productId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(productData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Product.fromJson(data['data']);
      } else {
        throw Exception('Failed to update product');
      }
    } catch (e) {
      throw Exception('Error updating product: $e');
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$productId'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete product');
      }
    } catch (e) {
      throw Exception('Error deleting product: $e');
    }
  }

  // Add variant
  Future<void> addVariant(
    String productId,
    Map<String, dynamic> variantData,
  ) async {
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

  // Add roll to variant
  Future<void> addRoll({
    required String productId,
    required String variantId,
    required String location,
    required double length,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products/$productId/variants/$variantId/rolls'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'location': location, 'length': length}),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to add roll');
      }
    } catch (e) {
      throw Exception('Error adding roll: $e');
    }
  }

  // Update roll
  Future<void> updateRoll({
    required String productId,
    required String variantId,
    required String rollId,
    String? location,
    double? length,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (location != null) body['location'] = location;
      if (length != null) body['length'] = length;

      final response = await http.put(
        Uri.parse(
          '$baseUrl/products/$productId/variants/$variantId/rolls/$rollId',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update roll');
      }
    } catch (e) {
      throw Exception('Error updating roll: $e');
    }
  }

  // Delete roll
  Future<void> deleteRoll({
    required String productId,
    required String variantId,
    required String rollId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '$baseUrl/products/$productId/variants/$variantId/rolls/$rollId',
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete roll');
      }
    } catch (e) {
      throw Exception('Error deleting roll: $e');
    }
  }
}
