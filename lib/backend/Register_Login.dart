import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = "https://smartbox-chi.vercel.app";

  // -------------------
  // REGISTER
  // -------------------
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/register");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": name,
          "email": email,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "error": data["error"] ?? "Registration failed"};
      }
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  // -------------------
  // LOGIN
  // -------------------
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/login");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "user": data["user"], "token": data["access_token"]};
      } else {
        return {"success": false, "error": data["error"] ?? "Login failed"};
      }
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }
}
