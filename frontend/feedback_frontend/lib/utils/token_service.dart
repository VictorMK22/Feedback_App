import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class TokenService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _tokenExpiryKey = 'token_expiry';

  static Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  /// Gets the stored access token if valid, otherwise refreshes it
  static Future<String?> getValidAccessToken() async {
    try {
      if (await isAccessTokenExpired()) {
        await refreshToken();
      }
      return await getAccessToken();
    } catch (e) {
      debugPrint('Error getting valid token: $e');
      return null;
    }
  }

  static Future<String?> getAccessToken() async {
    final prefs = await _prefs;
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await _prefs;
    return prefs.getString(_refreshTokenKey);
  }

  static Future<DateTime?> getTokenExpiry() async {
    final prefs = await _prefs;
    final expiry = prefs.getString(_tokenExpiryKey);
    return expiry != null ? DateTime.parse(expiry) : null;
  }

  static Future<bool> isAccessTokenExpired() async {
    final expiry = await getTokenExpiry();
    return expiry == null || expiry.isBefore(DateTime.now());
  }

  static Future<void> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/token/refresh/'),
        body: jsonEncode({'refresh': refreshToken}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storeTokens(
          accessToken: data['access'],
          refreshToken: refreshToken, // Some APIs return new refresh token
          expiresIn: data['expires_in'] ?? 3600, // Default 1 hour
        );
      } else {
        throw Exception('Token refresh failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
      rethrow;
    }
  }

  static Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
    int? expiresIn,
  }) async {
    final prefs = await _prefs;
    await Future.wait([
      prefs.setString(_accessTokenKey, accessToken),
      prefs.setString(_refreshTokenKey, refreshToken),
      if (expiresIn != null)
        prefs.setString(
          _tokenExpiryKey,
          DateTime.now().add(Duration(seconds: expiresIn)).toString(),
        ),
    ]);
  }

  static Future<void> clearTokens() async {
    final prefs = await _prefs;
    await Future.wait([
      prefs.remove(_accessTokenKey),
      prefs.remove(_refreshTokenKey),
      prefs.remove(_tokenExpiryKey),
    ]);
  }

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getValidAccessToken();
    if (token == null) {
      throw Exception('No valid token available');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
}
