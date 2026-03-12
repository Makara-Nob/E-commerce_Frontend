import 'package:flutter/foundation.dart';
import '../models/product/product.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();

  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _hasMore = true;
  String? _searchQuery;
  int? _selectedCategoryId;
  int? _selectedBrandId;

  double? _minPrice;
  double? _maxPrice;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  String? get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  int? get selectedBrandId => _selectedBrandId;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;

  // Load products (initial or refresh)
  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _products = [];
      _currentPage = 0;
      _hasMore = true;
    }

    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _productService.getAllProducts(
        page: _currentPage + 1, // Backend is 1-based
        limit: 10,
        search: _searchQuery,
        categoryId: _selectedCategoryId,
        brandId: _selectedBrandId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        sortBy: _sortBy,
      );

      if (response.success && response.data != null) {
        if (refresh) {
          _products = response.data!.products;
        } else {
          _products.addAll(response.data!.products);
        }
        
        _totalPages = response.data!.totalPages;
        _currentPage++; // Or use response.data.currentPage
        _hasMore = _currentPage < _totalPages;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search products
  Future<void> searchProducts(String query) async {
    _searchQuery = query.isEmpty ? null : query;
    await loadProducts(refresh: true);
  }

  // Filter by category
  Future<void> filterByCategory(int? categoryId) async {
    _selectedCategoryId = categoryId;
    await loadProducts(refresh: true);
  }

  // Filter by brand
  Future<void> filterByBrand(int? brandId) async {
    _selectedBrandId = brandId;
    await loadProducts(refresh: true);
  }

  // Filter by price range
  Future<void> filterByPriceRange(double? min, double? max) async {
    _minPrice = min;
    _maxPrice = max;
    await loadProducts(refresh: true);
  }

  // Sort products
  String? _sortBy;
  String? get sortBy => _sortBy;

  Future<void> sortProducts(String? sortBy) async {
    _sortBy = sortBy;
    await loadProducts(refresh: true);
  }

  // Clear filters
  Future<void> clearFilters() async {
    _searchQuery = null;
    _selectedCategoryId = null;
    _selectedBrandId = null;
    _minPrice = null;
    _maxPrice = null;
    await loadProducts(refresh: true);
  }

  // Get product by ID (from cache or API)
  Future<Product?> getProductById(int id) async {
    // Check if product is in cache
    final cachedProduct = _products.firstWhere(
      (p) => p.id == id,
      orElse: () => Product(
        id: 0,
        name: '',
        sku: '',
        quantity: 0,
        minStock: 0,
        costPrice: 0,
        sellingPrice: 0,
        status: '',
      ),
    );

    if (cachedProduct.id != 0) {
      return cachedProduct;
    }

    // Fetch from API
    try {
      final response = await _productService.getProductById(id);
      if (response.success && response.data != null) {
        return response.data;
      }
    } catch (e) {
      _errorMessage = 'Failed to load product: $e';
      notifyListeners();
    }

    return null;
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
