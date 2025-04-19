import 'dart:convert';
import 'package:http/http.dart' as http;

class ItemBoxService {
  static const String baseUrl = "https://smartbox-chi.vercel.app";

  // ------------------------
  // Get Items by Box ID
  // ------------------------
  Future<List<Map<String, dynamic>>> getItems(String boxId) async {
    final url = Uri.parse("$baseUrl/api/items?box_id=$boxId");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List items = jsonDecode(response.body);
      return items.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Failed to fetch items");
    }
  }

  // ------------------------
  // Add an Item to a Box
  // ------------------------
  Future<Map<String, dynamic>> addItem({
    required String boxId,
    required String name,
    int quantity = 1,
  }) async {
    final url = Uri.parse("$baseUrl/api/add_item");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "box_id": boxId,
        "name": name,
        "quantity": quantity,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["error"] ?? "Failed to add item");
    }
  }

  // ------------------------
  // Remove Item by ID
  // ------------------------
  Future<void> removeItem(String itemId) async {
    final url = Uri.parse("$baseUrl/api/remove_item/$itemId");

    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)["error"] ?? "Failed to remove item");
    }
  }

  // ------------------------
  // Get History of a Box
  // ------------------------
  Future<List<Map<String, dynamic>>> getHistory(String boxId) async {
    final url = Uri.parse("$baseUrl/api/history/$boxId");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List history = jsonDecode(response.body);
      return history.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Failed to fetch history");
    }
  }

  Future<List<Map<String, dynamic>>> getAllBoxes() async {
    final url = Uri.parse("$baseUrl/api/boxes");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List boxes = jsonDecode(response.body);
      return boxes.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Failed to fetch boxes");
    }
  }


}
