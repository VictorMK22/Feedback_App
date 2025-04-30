import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../utils/token_service.dart';

class UserProvider with ChangeNotifier {
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  NotificationPreference get notificationPref =>
      _currentUser?.profile.notificationPreference ??
      NotificationPreference.both;

  Future<void> initializeUser() async {
    // Correct method name
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');

      if (userData != null) {
        final accessToken = await TokenService.getValidAccessToken();
        if (accessToken != null) {
          final userJson = jsonDecode(userData) as Map<String, dynamic>;
          _currentUser = AppUser.fromJson({
            ...userJson,
            'access': accessToken,
            'refresh': await TokenService.getRefreshToken(),
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing user: $e');
      await logout();
    } finally {
      notifyListeners();
    }
  }

  Future<void> setUser(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(user.toJson()));
      await TokenService.storeTokens(
        accessToken: user.accessToken ?? '',
        refreshToken: user.refreshToken ?? '',
        userData: user.toJson(),
      );
      _currentUser = user;
    } catch (e) {
      debugPrint('Error saving user: $e');
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await TokenService.clearTokens();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      _currentUser = null;
    } catch (e) {
      debugPrint('Error during logout: $e');
    } finally {
      notifyListeners();
    }
  }
}
