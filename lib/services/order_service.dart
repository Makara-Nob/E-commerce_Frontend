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
  }) async {
    final request = OrderRequest(
      shippingAddress: deliveryAddress,
      deliveryPhone: deliveryPhone,
      notes: notes,
      items: items,
    );

    return await _apiService.post<Order>(
      ApiConstants.orders,
      body: request.toJson(),
      requiresAuth: true,
      fromJson: (json) => Order.fromJson(json),
    );
  }

  // Get my orders with filters
  Future<ApiResponse<OrderListResponse>> getMyOrders({
    int page = 0,
    int limit = 20,
    String? status,
    String? sortBy,
    String? sortDirection,
  }) async {
    final Map<String, dynamic> filters = {
      'page': page,
      'size': limit,
    };

    if (status != null) filters['status'] = status;
    if (sortBy != null) filters['sortBy'] = sortBy;
    if (sortDirection != null) filters['sortDirection'] = sortDirection;

    final response = await _apiService.post<OrderListResponse>(
      ApiConstants.myOrders,
      body: filters,
      requiresAuth: true,
      fromJson: (json) => OrderListResponse.fromJson(json),
    );

    // Fallback for Admin or if my-orders endpoint fails for role mismatch
    if (!response.success && (response.message.contains('session') || response.message.contains('expired') || response.error.toString().contains('401'))) {
       print('⚠️ OrderService: my-orders failed with 401. Trying getAllOrders (fallback for Admin)...');
       // Try fetching all orders (Admin endpoint) might work if my-orders is restricted
       // Note: This assumes /api/v1/orders supports GET. If it requires parameters, might need to adjust.
       return await _apiService.get<OrderListResponse>(
         '${ApiConstants.orders}?page=$page&size=$limit', // Try GET format
         requiresAuth: true,
         fromJson: (json) => OrderListResponse.fromJson(json),
       );
    }
    
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
}
