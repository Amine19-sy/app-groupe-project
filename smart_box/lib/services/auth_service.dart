import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:smart_box/services/BaseUrl.dart';

class AuthService {
  final _storage = FlutterSecureStorage();
  final String baseUrl = ChromeUrl;

  // Register function
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  
  }) async {
    final url = Uri.parse('$baseUrl/register');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final responseBody = jsonDecode(response.body);
      throw Exception(responseBody['error'] ?? 'An error occurred');
    }
  }

  // Login function
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final responseBody = jsonDecode(response.body);
      throw Exception(responseBody['error'] ?? 'An error occurred');
    }
  }

    Future<Map<String, dynamic>> fetchCurrentUser(String token) async {
    final url = Uri.parse('$baseUrl/me');
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to fetch user');
    }
  }

    Future<void> persistToken(String token) =>
    _storage.write(key: 'access_token', value: token);

  Future<String?> readToken() =>
    _storage.read(key: 'access_token');

  Future<void> deleteToken() =>
    _storage.delete(key: 'access_token');
}
