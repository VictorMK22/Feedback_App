import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:feedback_frontend/utils/user_provider.dart';
import 'utils/app_routes.dart';

void main() async {
  // Initialize Flutter binding before using plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Add a small delay to ensure plugin registration completes
  await Future.delayed(const Duration(milliseconds: 100));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // Add other providers here if needed
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login, // Start at the login screen
      routes: AppRoutes.routes, // Register routes
      // Optional: Add theme configuration
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}
