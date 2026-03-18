import '../models/api_response.dart';
import '../models/order/order.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class OrderService {
  final ApiService _apiService = ApiService();

  // Create order from cart
  Future<ApiResponse<Order>> createOrder({
    String? deliveryAddress,
    String? deliveryPhone,
    String? notes,
    required List<Map<String, dynamic>> items,
    String paymentMethod = 'ABA_PAYWAY',
  }) async {
    final request = OrderRequest(
      shippingAddress: deliveryAddress,
      deliveryPhone: deliveryPhone,
      notes: notes,
      items: items,
      paymentMethod: paymentMethod,
    );

    return await _apiService.post<Order>(
      ApiConstants.orders,
      body: request.toJson(),
      requiresAuth: true,
      fromJson: (json) => Order.fromJson(json),
    );
  }

  // Get my orders
  Future<ApiResponse<List<Order>>> getMyOrders({
    int page = 0,
    int limit = 20,
    String? status,
    String? sortBy,
    String? sortDirection,
  }) async {
    // The backend /api/v1/orders/my-orders is a GET request and returns an array of orders directly in `data`.
    final response = await _apiService.getList<Order>(
      ApiConstants.myOrders,
      requiresAuth: true,
      fromJson: (json) => Order.fromJson(json),
    );

    return response;
  }

  // Get order by ID
  Future<ApiResponse<Order>> getOrderById(int id) async {
    return await _apiService.get<Order>(
      ApiConstants.orderById(id),
      requiresAuth: true,
      fromJson: (json) => Order.fromJson(json),
    );
  }

  // Check payment status manually
  Future<ApiResponse<Order>> checkPaymentStatus(int id) async {
    return await _apiService.post<Order>(
      ApiConstants.checkPayment(id),
      body: {}, // empty body
      requiresAuth: true,
      fromJson: (json) => Order.fromJson(json['order']),
    );
  }

  // Get PayWay payload for existing order
  Future<ApiResponse<Map<String, dynamic>>> getPaywayPayload(int id, String paymentOption) async {
    return await _apiService.post<Map<String, dynamic>>(
      ApiConstants.paywayPayload(id),
      body: {'paymentOption': paymentOption},
      requiresAuth: true,
      fromJson: (json) => json,
    );
  }
}
