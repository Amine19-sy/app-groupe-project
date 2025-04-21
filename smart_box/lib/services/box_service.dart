import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_box/models/box.dart';
import 'package:smart_box/services/BaseUrl.dart';
class BoxService {
  final String baseUrl = ChromeUrl;

  
  Future<List<Box>> fetchUserBoxes(String userId) async {
    final url = Uri.parse('$baseUrl/api/boxes?user_id=$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Box.fromJson(json)).toList();
    } else {
      final responseBody = jsonDecode(response.body);
      throw Exception(responseBody['error'] ?? 'An error occurred while fetching boxes.');
    }
  }
    Future<Box> addBox({
    required String userId,
    required String name,
    required String description,
  }) async {
    final url = Uri.parse('$baseUrl/api/add_box');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'user_id': userId,
        'name': name,
        'description': description,
      }),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      return Box.fromJson(jsonResponse);
    } else {
      final Map<String, dynamic> errorResponse = jsonDecode(response.body);
      throw Exception(errorResponse['error'] ?? 'An error occurred while adding the box.');
    }
  }

}
