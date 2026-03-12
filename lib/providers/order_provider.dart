import 'package:flutter/foundation.dart';
import '../models/order/order.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();

  List<Order> _orders = [];
  Order? _currentOrder;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _hasMore = true;

  List<Order> get orders => _orders;
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  // Create order
  Future<bool> createOrder({
    String? deliveryAddress,
    String? deliveryPhone,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _orderService.createOrder(
        deliveryAddress: deliveryAddress,
        deliveryPhone: deliveryPhone,
        notes: notes,
        items: items,
      );

      if (response.success && response.data != null) {
        _currentOrder = response.data;
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
      _errorMessage = 'Failed to create order: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load orders (with pagination)
  Future<void> loadOrders({bool refresh = false}) async {
    if (refresh) {
      _orders = [];
      _currentPage = 0;
      _hasMore = true;
    }

    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _orderService.getMyOrders(
        page: _currentPage,
        limit: 20,
      );

      if (response.success && response.data != null) {
        _orders.addAll(response.data!.orders);
        _totalPages = response.data!.totalPages;
        _currentPage++;
        _hasMore = _currentPage < _totalPages;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'Failed to load orders: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get order by ID
  Future<void> loadOrderById(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _orderService.getOrderById(id);

      if (response.success && response.data != null) {
        _currentOrder = response.data;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'Failed to load order: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear current order
  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
