import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Product> _products = [];
  Stats? _stats;
  List<Map<String, dynamic>> _categories = [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  String? _currentSearch;
  String? _currentCategory;

  List<Product> get products => _products;
  Stats? get stats => _stats;
  List<Map<String, dynamic>> get categories => _categories;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> fetchProducts({String? category, String? search}) async {
    _loading = true;
    _error = null;
    _currentPage = 1;
    _hasMore = true;
    _currentSearch = search;
    _currentCategory = category;
    notifyListeners();

    try {
      print('📱 ProductProvider: Starting fetchProducts (page 1)...');
      final result = await _apiService.getProducts(
        category: category,
        search: search,
        page: 1,
      );
      _products = result['products'];
      _currentPage = result['page'];
      _totalPages = result['pages'];
      _hasMore = _currentPage < _totalPages;
      print('📱 ProductProvider: Got ${_products.length} products (page $_currentPage/$_totalPages)');
      _loading = false;
      notifyListeners();
    } catch (e) {
      print('📱 ProductProvider: ERROR - $e');
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreProducts() async {
    if (_loadingMore || !_hasMore) return;

    _loadingMore = true;
    _error = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      print('📱 ProductProvider: Loading more products (page $nextPage)...');
      final result = await _apiService.getProducts(
        category: _currentCategory,
        search: _currentSearch,
        page: nextPage,
      );
      _products.addAll(result['products']);
      _currentPage = result['page'];
      _totalPages = result['pages'];
      _hasMore = _currentPage < _totalPages;
      print('📱 ProductProvider: Loaded ${result['products'].length} more products (page $_currentPage/$_totalPages)');
      _loadingMore = false;
      notifyListeners();
    } catch (e) {
      print('📱 ProductProvider: ERROR loading more - $e');
      _error = e.toString();
      _loadingMore = false;
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

  Future<bool> createProduct(
    Map<String, dynamic> productData,
    File? mainImage,
    Map<int, File>? variantImages,
  ) async {
    try {
      await _apiService.createProduct(productData, mainImage, variantImages);
      await fetchProducts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(
    String productId,
    Map<String, dynamic> productData,
    File? mainImage,
  ) async {
    try {
      await _apiService.updateProduct(productId, productData, mainImage);
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
    File? variantImage,
  ) async {
    try {
      await _apiService.addVariant(productId, variantData, variantImage);
      await fetchProducts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateVariant(
    String productId,
    String variantId,
    Map<String, dynamic> variantData,
    File? variantImage,
  ) async {
    try {
      await _apiService.updateVariant(productId, variantId, variantData, variantImage);
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
