import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Product> _products = [];
  Stats? _stats;
  List<Map<String, dynamic>> _categories = [];
  bool _loading = false;
  String? _error;

  List<Product> get products => _products;
  Stats? get stats => _stats;
  List<Map<String, dynamic>> get categories => _categories;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchProducts({String? category, String? search}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      print('📱 ProductProvider: Starting fetchProducts...');
      _products = await _apiService.getProducts(
        category: category,
        search: search,
      );
      print('📱 ProductProvider: Got ${_products.length} products');
      _loading = false;
      notifyListeners();
    } catch (e) {
      print('📱 ProductProvider: ERROR - $e');
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  Future<Product?> fetchProductById(String id) async {
    try {
      return await _apiService.getProductById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> fetchStats() async {
    try {
      _stats = await _apiService.getStats();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchCategories() async {
    try {
      _categories = await _apiService.getCategories();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> createProduct(Map<String, dynamic> productData) async {
    try {
      await _apiService.createProduct(productData);
      await fetchProducts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(String productId, Map<String, dynamic> productData) async {
    try {
      await _apiService.updateProduct(productId, productData);
      await fetchProducts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _apiService.deleteProduct(productId);
      await fetchProducts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addVariant(
    String productId,
    Map<String, dynamic> variantData,
  ) async {
    try {
      await _apiService.addVariant(productId, variantData);
      await fetchProducts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVariant(String productId, String variantId) async {
    try {
      await _apiService.deleteVariant(productId, variantId);
      await fetchProducts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Roll management methods
  Future<bool> addRoll({
    required String productId,
    required String variantId,
    required String location,
    required double length,
  }) async {
    try {
      await _apiService.addRoll(
        productId: productId,
        variantId: variantId,
        location: location,
        length: length,
      );
      await fetchProducts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRoll({
    required String productId,
    required String variantId,
    required String rollId,
    String? location,
    double? length,
  }) async {
    try {
      await _apiService.updateRoll(
        productId: productId,
        variantId: variantId,
        rollId: rollId,
        location: location,
        length: length,
      );
      await fetchProducts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRoll({
    required String productId,
    required String variantId,
    required String rollId,
  }) async {
    try {
      await _apiService.deleteRoll(
        productId: productId,
        variantId: variantId,
        rollId: rollId,
      );
      await fetchProducts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  List<Product> get lowStockProducts {
    return _products.where((p) => p.totalStock <= p.lowStockThreshold).toList();
  }
}
