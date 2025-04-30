// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:feedback_frontend/screens/config/app_config.dart';
import 'package:feedback_frontend/utils/user_provider.dart';
import 'package:feedback_frontend/utils/app_routes.dart';

class TokenService {
  // Key constants
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _tokenExpiryKey = 'token_expiry';
  static const _userDataKey = 'user_data';

  // Timer for automatic refresh
  static Timer? _refreshTimer;
  static final _client = http.Client();

  /// Initialize automatic token refresh
  static Future<void> initAutoRefresh() async {
    _cancelAutoRefresh();
    if (await hasValidRefreshToken()) {
      await _scheduleRefresh();
    }
  }

  /// Store tokens and user data
  static Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
    int expiresIn = 1800, // Default 30 minutes
    Map<String, dynamic>? userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_accessTokenKey, accessToken),
      prefs.setString(_refreshTokenKey, refreshToken),
      prefs.setString(
        _tokenExpiryKey,
        DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String(),
      ),
      if (userData != null) prefs.setString(_userDataKey, jsonEncode(userData)),
    ]);
    await _scheduleRefresh();
  }

  /// Get valid access token (auto-refreshes if needed)
  static Future<String?> getValidAccessToken() async {
    if (await isAccessTokenExpired()) {
      await refreshToken(); // Fixed: Changed from _refreshToken to refreshToken
    }
    return await getAccessToken();
  }

  /// Get raw access token without refresh logic
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// Get token expiry time
  static Future<DateTime?> getTokenExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final expiry = prefs.getString(_tokenExpiryKey);
    return expiry != null ? DateTime.parse(expiry) : null;
  }

  /// Check if token is expired
  static Future<bool> isAccessTokenExpired() async {
    final expiry = await getTokenExpiry();
    return expiry == null || expiry.isBefore(DateTime.now());
  }

  /// Check if refresh token exists
  static Future<bool> hasValidRefreshToken() async {
    return await getRefreshToken() != null;
  }

  /// Generate authentication headers
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getValidAccessToken();
    return {
      'Authorization': 'Bearer ${token ?? ''}',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Refresh the access token using refresh token
  static Future<bool> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;
      final response = await _client.post(
        Uri.parse('${AppConfig.baseUrl}/api/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storeTokens(
          accessToken: data['access'],
          refreshToken: data['refresh'] ?? refreshToken,
          expiresIn: data['expires_in'] ?? 1800,
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      return false;
    }
  }

  // Private methods for automatic refresh
  static Future<void> _scheduleRefresh() async {
    _cancelAutoRefresh();

    final expiry = await getTokenExpiry();
    if (expiry == null) return;
    // Schedule refresh 5 minutes before expiry
    final refreshTime = expiry.subtract(const Duration(minutes: 5));
    final delay = refreshTime.difference(DateTime.now());
    if (delay > Duration.zero) {
      _refreshTimer = Timer(delay, () async {
        try {
          await refreshToken();
          await _scheduleRefresh(); // Reschedule next refresh
        } catch (e) {
          debugPrint('Auto-refresh failed: $e');
        }
      });
    } else {
      // Token is already close to expiry, refresh immediately
      await refreshToken();
    }
  }

  static void _cancelAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Clear all stored tokens and cancel refresh timer
  static Future<void> clearTokens() async {
    _cancelAutoRefresh();
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_accessTokenKey),
      prefs.remove(_refreshTokenKey),
      prefs.remove(_tokenExpiryKey),
      prefs.remove(_userDataKey),
    ]);
  }

  /// Get stored user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userDataKey);
    return userData != null ? jsonDecode(userData) : null;
  }
}

class AuthenticatedClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final BuildContext context;

  AuthenticatedClient(this.context);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Get valid token (auto-refreshes if needed)
    final token = await TokenService.getValidAccessToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    var response = await _inner.send(request);

    // Handle token expiration (401 Unauthorized)
    if (response.statusCode == 401) {
      if (await TokenService.refreshToken()) {
        // Retry with new token
        final newToken = await TokenService.getValidAccessToken();
        request.headers['Authorization'] = 'Bearer $newToken';
        return _inner.send(request);
      } else {
        // Force logout if refresh fails
        await TokenService.clearTokens();
        // Check if the widget is still in the tree before using context
        if (context.findAncestorStateOfType<State>()?.mounted ?? false) {
          Provider.of<UserProvider>(context, listen: false).logout();
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (route) => false,
          );
        }
        throw Exception('Session expired - Please login again');
      }
    }
    return response;
  }
}
