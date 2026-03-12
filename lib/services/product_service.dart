import '../models/api_response.dart';
import '../models/product/product.dart';
import '../models/product/product_list_response.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class ProductService {
  final ApiService _apiService = ApiService();

  // Get all products with pagination and filters
  Future<ApiResponse<ProductListResponse>> getAllProducts({
    int page = 1,
    int limit = 10,
    String? search,
    int? categoryId,
    int? brandId, 
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortDirection,
  }) async {
    final Map<String, dynamic> requestBody = {
      'pageNo': page,
      'pageSize': limit,
      'search': search,
      'status': 'ACTIVE', // Default to active public products
      'categoryId': categoryId,
      'brandId': brandId,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'sortBy': sortBy,
    };

    // Clean up null values to avoid sending them (though backend might handle nulls, cleaner to remove)
    requestBody.removeWhere((key, value) => value == null || (value is String && value.isEmpty));

    try {
      final response = await _apiService.post<ProductListResponse>(
        ApiConstants.publicProducts, // Ensure this endpoint corresponds to /api/v1/public/products/all
        body: requestBody,
        requiresAuth: false,
        fromJson: (json) => ProductListResponse.fromJson(json),
      );
      return response;
    } catch (e) {
      return ApiResponse<ProductListResponse>(
        success: false, 
        message: 'Failed to fetch products: $e',
        error: e.toString()
      );
    }
  }

  // Get product by ID
  Future<ApiResponse<Product>> getProductById(int id) async {
    return await _apiService.get<Product>(
      ApiConstants.publicProductById(id),
      requiresAuth: false,
      fromJson: (json) => Product.fromJson(json),
    );
  }

  // Get related products
  Future<ApiResponse<List<Product>>> getRelatedProducts(int id) async {
    try {
      final response = await _apiService.getList<Product>(
        ApiConstants.relatedProducts(id),
        requiresAuth: false,
        fromJson: (json) => Product.fromJson(json),
      );
      return response;
    } catch (e) {
      print("🔴 Error fetching related products: $e");
      return ApiResponse<List<Product>>(
        success: false,
        message: 'Failed to load related products: $e',
        error: e.toString(),
      );
    }
  }
}
