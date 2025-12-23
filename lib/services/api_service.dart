import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import '../models/product.dart';

class ApiService {
  // Set to false for production builds
  static bool isDevelopment = false;
  
  // PHYSICAL DEVICE: Use your computer's WiFi IP
  // Make sure your phone is connected to the SAME WiFi network as your computer
  // If using Ethernet, try 192.168.0.146 instead
  static String baseUrl = isDevelopment
      ? 'http://192.168.0.146:5000/api/v1'
      : 'http://api.ecommercetn.me/api/v1';

  // Common headers to prevent caching
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0',
  };

  // Get all products with pagination
  Future<Map<String, dynamic>> getProducts({
    String? category,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/products');
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      // Add timestamp to bust cache
      queryParams['_t'] = DateTime.now().millisecondsSinceEpoch.toString();
      uri = uri.replace(queryParameters: queryParams);

      print('🔵 Making HTTP GET request to: $uri');
      final response = await http
          .get(uri, headers: _headers)
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
          return {
            'products': <Product>[],
            'page': page,
            'pages': 0,
            'total': 0,
          };
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
        return {
          'products': products,
          'page': data['page'] ?? page,
          'pages': data['pages'] ?? 1,
          'total': data['total'] ?? products.length,
        };
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
      final uri = Uri.parse('$baseUrl/products/$id?_t=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(uri, headers: _headers);

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
      final uri = Uri.parse('$baseUrl/stats/dashboard?_t=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(uri, headers: _headers);

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
      final uri = Uri.parse('$baseUrl/products/categories?_t=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(uri, headers: _headers);

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

  // Create product with image upload
  Future<Product> createProduct(
    Map<String, dynamic> productData,
    File? mainImage,
    Map<int, File>? variantImages,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/products'),
      );

      // Add main image if provided
      if (mainImage != null) {
        final extension = mainImage.path.split('.').last.toLowerCase();
        String contentType = 'image/jpeg';
        if (extension == 'png') {
          contentType = 'image/png';
        } else if (extension == 'gif') {
          contentType = 'image/gif';
        } else if (extension == 'webp') {
          contentType = 'image/webp';
        }
        
        request.files.add(
          await http.MultipartFile.fromPath(
            'mainImage',
            mainImage.path,
            contentType: MediaType.parse(contentType),
          ),
        );
      }

      // Upload variant images first and get URLs (simplified - using placeholder for now)
      final variants = productData['variants'] as List?;
      if (variants != null && variantImages != null) {
        for (var i = 0; i < variants.length; i++) {
          final variantImage = variantImages[i];
          if (variantImage != null) {
            // For now, keep as placeholder - proper implementation would upload separately
            variants[i]['image'] = '/uploads/variant_${DateTime.now().millisecondsSinceEpoch}.jpg';
          }
        }
      }

      // Add other fields as JSON in a single field
      request.fields['name'] = productData['name'];
      if (variants != null) {
        request.fields['variants'] = json.encode(variants);
      }
      if (productData['lowStockThreshold'] != null) {
        request.fields['lowStockThreshold'] = productData['lowStockThreshold'].toString();
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Product.fromJson(data['data']);
      } else {
        print('Create product failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to create product: ${response.body}');
      }
    } catch (e) {
      print('Error creating product: $e');
      throw Exception('Error creating product: $e');
    }
  }

  // Update product with optional image upload
  Future<Product> updateProduct(
    String productId,
    Map<String, dynamic> productData,
    File? mainImage,
  ) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/products/$productId'),
      );

      // Add main image if provided
      if (mainImage != null) {
        final extension = mainImage.path.split('.').last.toLowerCase();
        String contentType = 'image/jpeg';
        if (extension == 'png') {
          contentType = 'image/png';
        } else if (extension == 'gif') {
          contentType = 'image/gif';
        } else if (extension == 'webp') {
          contentType = 'image/webp';
        }
        
        request.files.add(
          await http.MultipartFile.fromPath(
            'mainImage',
            mainImage.path,
            contentType: MediaType.parse(contentType),
          ),
        );
      }

      // Add other fields
      if (productData['name'] != null) {
        request.fields['name'] = productData['name'];
      }
      if (productData['variants'] != null) {
        request.fields['variants'] = json.encode(productData['variants']);
      }
      if (productData['lowStockThreshold'] != null) {
        request.fields['lowStockThreshold'] = productData['lowStockThreshold'].toString();
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Product.fromJson(data['data']);
      } else {
        print('Update product failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to update product: ${response.body}');
      }
    } catch (e) {
      print('Error updating product: $e');
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

  // Add variant with optional image upload
  Future<void> addVariant(
    String productId,
    Map<String, dynamic> variantData,
    File? variantImage,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/products/$productId/variants'),
      );

      // Add variant image if provided
      if (variantImage != null) {
        final extension = variantImage.path.split('.').last.toLowerCase();
        String contentType = 'image/jpeg';
        if (extension == 'png') {
          contentType = 'image/png';
        } else if (extension == 'gif') {
          contentType = 'image/gif';
        } else if (extension == 'webp') {
          contentType = 'image/webp';
        }
        
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            variantImage.path,
            contentType: MediaType.parse(contentType),
          ),
        );
      }

      // Add variant fields
      if (variantData['colorName'] != null) {
        request.fields['colorName'] = variantData['colorName'];
      }
      if (variantData['color'] != null) {
        request.fields['color'] = variantData['color'];
      }
      if (variantData['reference'] != null) {
        request.fields['reference'] = variantData['reference'];
      }
      if (variantData['rolls'] != null) {
        request.fields['rolls'] = json.encode(variantData['rolls']);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 201) {
        throw Exception('Failed to add variant: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error adding variant: $e');
    }
  }

  // Update variant with optional image upload
  Future<void> updateVariant(
    String productId,
    String variantId,
    Map<String, dynamic> variantData,
    File? variantImage,
  ) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/products/$productId/variants/$variantId'),
      );

      // Add variant image if provided
      if (variantImage != null) {
        final extension = variantImage.path.split('.').last.toLowerCase();
        String contentType = 'image/jpeg';
        if (extension == 'png') {
          contentType = 'image/png';
        } else if (extension == 'gif') {
          contentType = 'image/gif';
        } else if (extension == 'webp') {
          contentType = 'image/webp';
        }
        
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            variantImage.path,
            contentType: MediaType.parse(contentType),
          ),
        );
      }

      // Add variant fields
      if (variantData['colorName'] != null) {
        request.fields['colorName'] = variantData['colorName'];
      }
      if (variantData['color'] != null) {
        request.fields['color'] = variantData['color'];
      }
      if (variantData['reference'] != null) {
        request.fields['reference'] = variantData['reference'];
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Failed to update variant: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating variant: $e');
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
