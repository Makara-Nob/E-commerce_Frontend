import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/auth/auth_response.dart';

class StorageService {
  // static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';

  // Save JWT token securely
  Future<void> saveToken(String token) async {
    // await _storage.write(key: _tokenKey, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print('💾 StorageService: Token saved (length: ${token.length})');
  }

  // Get JWT token
  Future<String?> getToken() async {
    // return await _storage.read(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    print('🔓 StorageService: Token retrieved - ${token != null ? "Found (${token.length} chars)" : "Not found"}');
    return token;
  }

  // Save user data
  Future<void> saveUser(UserData user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // Get user data
  Future<UserData?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return UserData.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  // Clear all stored data (logout)
  Future<void> clearAll() async {
    // await _storage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
