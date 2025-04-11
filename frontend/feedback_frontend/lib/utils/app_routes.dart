import 'screens/auth/login_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/home_dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/feedback/feedback_submission_screen.dart';
import 'screens/feedback/feedback_history_screen.dart';
import 'screens/notifications/notification_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

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

  // Routes map
  static Map<String, WidgetBuilder> routes = {
    login: (context) => LoginScreen(),
    register: (context) => RegistrationScreen(),
    home: (context) => HomeDashboardScreen(),
    profile: (context) => ProfileScreen(),
    feedbackSubmission: (context) => FeedbackSubmissionScreen(),
    feedbackHistory: (context) => FeedbackHistoryScreen(),
    notifications: (context) => NotificationScreen(),
    adminDashboard: (context) => AdminDashboardScreen(),
  };
}