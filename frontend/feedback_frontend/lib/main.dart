import 'package:flutter/material.dart';
import 'utils/app_routes.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login,  // Start at the login screen
      routes: AppRoutes.routes,      // Register routes
    );
  }
}