import 'package:flutter/material.dart';
import 'package:feedback_frontend/screens/auth/login_screen.dart';
import 'package:feedback_frontend/screens/auth/registration_screen.dart';
import 'package:feedback_frontend/screens/auth/forgot_password_screen.dart';
import 'package:feedback_frontend/screens/home_screen.dart';
import 'package:feedback_frontend/screens/profile_screen.dart';
import 'package:feedback_frontend/screens/feedback_submission_screen.dart';
import 'package:feedback_frontend/screens/feedback_history_screen.dart';
import 'package:feedback_frontend/screens/notification_screen.dart';
import 'package:feedback_frontend/screens/admin_dashboard_screen.dart';
import 'package:feedback_frontend/screens/settings_screen.dart';

class AppRoutes {
  // Route constants
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const profile = '/profile';
  static const feedbackSubmission = '/feedbackSubmission';
  static const feedbackHistory = '/feedbackHistory';
  static const notifications = '/notifications';
  static const adminDashboard = '/adminDashboard';
  static const forgotPassword = '/forgotPassword';
  static const String settings = '/settings';

  // Routes map
  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    register: (context) => const RegistrationScreen(),
    home: (context) => const HomeDashboardScreen(),
    profile: (context) => const ProfileScreen(),
    feedbackSubmission: (context) => const FeedbackSubmissionScreen(),
    feedbackHistory: (context) => const FeedbackHistoryScreen(),
    notifications: (context) => const NotificationScreen(),
    adminDashboard: (context) => const AdminDashboardScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    AppRoutes.settings: (context) => const SettingsScreen(),
  };
}
