import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  static Future<void> refreshTokenIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final refreshToken = prefs.getString('refresh_token');

    if (accessToken == null || refreshToken == null) {
      throw Exception('No tokens available');
    }

    // Simple check - in production, decode JWT to check expiry
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/token/refresh/'),
      body: jsonEncode({'refresh': refreshToken}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final newToken = jsonDecode(response.body)['access'];
      await prefs.setString('access_token', newToken);
    } else {
      throw Exception('Token refresh failed');
    }
  }

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAccessToken();
    if (token == null) throw Exception('No token available');

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
}
