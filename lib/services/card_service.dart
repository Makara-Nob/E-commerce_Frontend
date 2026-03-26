import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/payment/saved_card.dart';
import 'storage_service.dart';

class CardService {
  final _storage = StorageService();

  Future<String> _token() async => (await _storage.getToken()) ?? '';

  Map<String, String> _headers(String token) => {
    'Content-Type': ApiConstants.contentTypeJson,
    ApiConstants.authorizationHeader: '${ApiConstants.bearerPrefix} $token',
  };

  Future<List<SavedCard>> getSavedCards() async {
    final token = await _token();
    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.savedCards}'),
      headers: _headers(token),
    ).timeout(ApiConstants.requestTimeout);

    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      if (body['data'] != null && body['data']['savedCards'] != null) {
        final list = body['data']['savedCards'] as List<dynamic>;
        return list.map((e) => SavedCard.fromJson(e as Map<String, dynamic>)).toList();
      } else if (body['savedCards'] != null) {
        final list = body['savedCards'] as List<dynamic>;
        return list.map((e) => SavedCard.fromJson(e as Map<String, dynamic>)).toList();
      }
      return []; // Return empty if no cards array is found
    }
    throw Exception(body['message'] ?? 'Failed to fetch saved cards');
  }

  Future<void> deleteCard(int index) async {
    final token = await _token();
    final res = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.deleteCard(index)}'),
      headers: _headers(token),
    ).timeout(ApiConstants.requestTimeout);

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Failed to delete card');
    }
  }

  Future<Map<String, dynamic>> initLinkCard() async {
    final token = await _token();
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.linkCard}'),
      headers: _headers(token),
    ).timeout(ApiConstants.requestTimeout);

    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      if (body['data'] != null) {
         return body['data'] as Map<String, dynamic>;
      }
      return body as Map<String, dynamic>;
    }
    throw Exception(body['message'] ?? 'Failed to init link card');
  }

  Future<bool> payByToken(int orderId, int cardIndex) async {
    final token = await _token();
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.payByToken(orderId)}'),
      headers: _headers(token),
      body: jsonEncode({'cardIndex': cardIndex}),
    ).timeout(ApiConstants.requestTimeout);

    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['success'] == true) return true;
    throw Exception(body['message'] ?? 'Payment failed');
  }
}
