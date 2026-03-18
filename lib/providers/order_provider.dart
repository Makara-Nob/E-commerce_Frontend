import 'package:flutter/foundation.dart';
import '../models/order/order.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();

  List<Order> _orders = [];
  Order? _currentOrder;
  bool _isLoading = false;
  String? _errorMessage;

  List<Order> get orders => _orders;
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Create order
  Future<bool> createOrder({
    String? deliveryAddress,
    String? deliveryPhone,
    String? notes,
    required List<Map<String, dynamic>> items,
    String paymentMethod = 'ABA_PAYWAY',
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
        paymentMethod: paymentMethod,
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

  // Load orders
  Future<void> loadOrders({bool refresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    if (refresh) {
      _orders = [];
    }
    notifyListeners();

    try {
      final response = await _orderService.getMyOrders();

      if (response.success && response.data != null) {
        _orders = response.data!;
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

  // Check payment status manually
  Future<bool> checkPaymentStatus(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _orderService.checkPaymentStatus(id);

      if (response.success && response.data != null) {
        // Update current order if it matches
        if (_currentOrder?.id == id) {
          _currentOrder = response.data;
        }
        
        // Update order in list if it exists
        final index = _orders.indexWhere((o) => o.id == id);
        if (index != -1) {
          _orders[index] = response.data!;
        }
        
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
      _errorMessage = 'Failed to check payment status: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get PayWay payload
  Future<Map<String, dynamic>?> getPaywayPayload(int id, String paymentOption) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _orderService.getPaywayPayload(id, paymentOption);
      _isLoading = false;
      notifyListeners();

      if (response.success && response.data != null) {
        return response.data;
      } else {
        _errorMessage = response.message;
        return null;
      }
    } catch (e) {
      _errorMessage = 'Failed to get PayWay payload: $e';
      _isLoading = false;
      notifyListeners();
      return null;
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
