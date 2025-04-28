import 'dart:io' show Platform;

// config/app_config.dart
class AppConfig {
  static String get baseUrl {
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    if (Platform.isIOS) return 'http://localhost:8000';
    return 'http://localhost:8000';
  }
}
