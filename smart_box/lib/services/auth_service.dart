import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_box/services/BaseUrl.dart';

class AuthService {
  
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
}
