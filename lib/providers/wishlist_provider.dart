import 'package:flutter/foundation.dart';
import '../models/product/product.dart';
import '../services/api_service.dart';

class WishlistProvider with ChangeNotifier {
  final List<Product> _items = [];
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  List<Product> get items => [..._items];
  int get itemCount => _items.length;
  bool get isLoading => _isLoading;

  Future<void> loadWishlist() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getList<Product>(
        '/api/v1/wishlist',
        fromJson: (json) => Product.fromJson(json),
      );

      if (response.success && response.data != null) {
        _items.clear();
        _items.addAll(response.data!);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading wishlist: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleWishlist(Product product) async {
    final isExisting = isExist(product.id);
    
    // Optimistic UI update
    if (isExisting) {
      _items.removeWhere((p) => p.id == product.id);
    } else {
      _items.add(product);
    }
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/api/v1/wishlist/toggle',
        body: {'productId': product.id},
      );

      if (!response.success) {
        // Revert on failure
        if (isExisting) {
          _items.add(product);
        } else {
          _items.removeWhere((p) => p.id == product.id);
        }
        notifyListeners();
      }
    } catch (e) {
      // Revert on error
      if (isExisting) {
        _items.add(product);
      } else {
        _items.removeWhere((p) => p.id == product.id);
      }
      notifyListeners();
    }
  }

  bool isExist(int productId) {
    return _items.any((p) => p.id == productId);
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
