import 'dart:io';
import '../models/api_response.dart';
import '../models/auth/login_request.dart';
import '../models/auth/register_request.dart';
import '../models/auth/auth_response.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  // Login
  Future<ApiResponse<AuthResponse>> login(String username, String password) async {
    final loginRequest = LoginRequest(
      username: username,
      password: password,
    );

    final response = await _apiService.post<AuthResponse>(
      ApiConstants.login,
      body: loginRequest.toJson(),
      requiresAuth: false,
      fromJson: (json) => AuthResponse.fromJson(json),
    );

    // Save token and user data if login successful
    if (response.success && response.data != null) {
      final token = response.data!.token;
      print('✅ AuthService: Login successful, saving token');
      print('🔑 Token: ${token.length > 20 ? token.substring(0, 20) : token}... (${token.length} chars)');
      await _storageService.saveToken(token);
      await _storageService.saveUser(response.data!.user);
      print('💾 AuthService: Token and user saved to storage');
    }

    return response;
  }

  // Register
  Future<ApiResponse<dynamic>> register(RegisterRequest request) async {
    final response = await _apiService.post(
      ApiConstants.register,
      body: request.toJson(),
      requiresAuth: false,
      fromJson: (json) => json,
    );
    return response;
  }

  // Verify OTP
  Future<ApiResponse<AuthResponse>> verifyOtp(String email, String otp) async {
    final response = await _apiService.post<AuthResponse>(
      ApiConstants.verifyOtp,
      body: {'email': email, 'otp': otp},
      requiresAuth: false,
      fromJson: (json) => AuthResponse.fromJson(json),
    );

    if (response.success && response.data != null) {
      final token = response.data!.token;
      await _storageService.saveToken(token);
      await _storageService.saveUser(response.data!.user);
    }

    return response;
  }

  // Resend OTP
  Future<ApiResponse<dynamic>> resendOtp(String email) async {
    return await _apiService.post(
      ApiConstants.resendOtp,
      body: {'email': email},
      requiresAuth: false,
      fromJson: (json) => json,
    );
  }

  // Validate token
  Future<ApiResponse<bool>> validateToken() async {
    return await _apiService.get<bool>(
      ApiConstants.validateToken,
      requiresAuth: true,
      fromJson: (json) => json as bool,
    );
  }

  // Get Profile
  Future<ApiResponse<UserData>> getProfile() async {
    return await _apiService.get<UserData>(
      ApiConstants.getProfile,
      requiresAuth: true,
      fromJson: (json) => UserData.fromJson(json),
    );
  }

  // Logout
  Future<void> logout() async {
    await _storageService.clearAll();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _storageService.isLoggedIn();
  }

  // Get current user
  Future<UserData?> getCurrentUser() async {
    return await _storageService.getUser();
  }

  // Update Profile
  Future<ApiResponse<UserData>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
  }) async {
    final Map<String, dynamic> body = {};
    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (phone != null) body['phone'] = phone;
    if (email != null) body['email'] = email;

    final response = await _apiService.post<UserData>(
      ApiConstants.updateProfile,
      body: body,
      requiresAuth: true,
      fromJson: (json) => UserData.fromJson(json),
    );

    if (response.success && response.data != null) {
      // Update local storage
      await _storageService.saveUser(response.data!);
    }
    return response;
  }

  // Upload Profile Image
  Future<ApiResponse<String>> uploadProfileImage(File file) async {
    return await _apiService.uploadFile(file);
  }

  // Update Profile with Image URL
  Future<ApiResponse<UserData>> updateProfileWithImage(String imageUrl) async {
      // Re-uses the existing update endpoint, assuming it accepts profileUrl
      // We need to check if the UserData model has profileUrl and if the update endpoint accepts it.
      // Based on my earlier check of UserEntity, it has profileUrl.
      // The UpdateUserRequestDto also has profileUrl.
      
      final body = {'profileUrl': imageUrl};
      
      final response = await _apiService.post<UserData>(
        ApiConstants.updateProfile,
        body: body,
        requiresAuth: true,
        fromJson: (json) => UserData.fromJson(json),
      );

      if (response.success && response.data != null) {
        await _storageService.saveUser(response.data!);
      }
      
      return response;
  }
}
