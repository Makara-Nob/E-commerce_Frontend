import '../models/api_response.dart';
import '../models/banner/banner.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class BannerService {
  final ApiService _apiService = ApiService();

  // Get active banners
  Future<ApiResponse<List<Banner>>> getActiveBanners() async {
    final response = await _apiService.get<List<dynamic>>(
      ApiConstants.publicBanners,
      requiresAuth: false,
      fromJson: (json) => json as List<dynamic>,
    );

    if (response.success && response.data != null) {
      final banners = response.data!
          .map((item) => Banner.fromJson(item as Map<String, dynamic>))
          .toList();
      
      return ApiResponse<List<Banner>>(
        success: true,
        message: response.message,
        data: banners,
      );
    }

    return ApiResponse<List<Banner>>(
      success: false,
      message: response.message,
      error: response.error,
    );
  }
}
