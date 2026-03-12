import 'package:flutter/foundation.dart';
import '../models/cart/cart.dart';
import '../services/cart_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();

  Cart? _cart;
  bool _isLoading = false;
  String? _errorMessage;

  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get itemCount => _cart?.itemCount ?? 0;
  double get totalAmount => _cart?.totalAmount ?? 0.0;

  // Load cart
  Future<void> loadCart() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _cartService.getCart();

      if (response.success && response.data != null) {
        _cart = response.data;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'Failed to load cart: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add item to cart
  Future<bool> addToCart(int productId, int quantity, {int? variantId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _cartService.addToCart(productId, quantity, variantId: variantId);

      if (response.success && response.data != null) {
        _cart = response.data;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to add to cart: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update item quantity
  Future<bool> updateQuantity(int itemId, int quantity) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _cartService.updateItemQuantity(itemId, quantity);

      if (response.success && response.data != null) {
        _cart = response.data;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update quantity: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Remove item
  Future<bool> removeItem(int itemId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _cartService.removeItem(itemId);

      if (response.success && response.data != null) {
        _cart = response.data;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to remove item: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear cart
  Future<bool> clearCart() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _cartService.clearCart();

      if (response.success) {
        _cart = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to clear cart: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear local cart state (for logout)
  void clearLocalCart() {
    _cart = null;
    _errorMessage = null;
    notifyListeners();
  }
}
