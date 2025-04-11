import 'package:flutter/material.dart';
import 'utils/validation.dart'; // Importing centralized validation methods
import 'utils/app_routes.dart'; // Importing app routes

class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _login(BuildContext context) {
    String emailOrUsername = emailController.text.trim();
    String password = passwordController.text;

    // Validate inputs using Validator methods
    String? emailError = Validator.validateEmail(emailOrUsername);
    String? passwordError = Validator.validatePassword(password);

    // Check for errors
    if (emailError != null || passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          emailError ?? passwordError!,
        )),
      );
      return;
    }

    // Validation passed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login successful')),
    );

    // Call backend API for login logic here
    Navigator.pushNamed(context, AppRoutes.home); // Navigate to home screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo Section
              Center(
                child: Text(
                  'AppLogo',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              SizedBox(height: 30),

              // Welcome Message
              Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Log in to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 20),

              // Email or Username Input Field
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email or Username',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),

              // Password Input Field
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 10),

              // Forgot Password Link
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {
                    // Navigate to Forgot Password screen
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Login Button
              Center(
                child: ElevatedButton(
                  onPressed: () => _login(context),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                  child: Text('Login'),
                ),
              ),
              SizedBox(height: 20),

              // Social Login Options
              Center(
                child: Column(
                  children: [
                    Text('or continue with'),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.facebook, color: Colors.blue),
                          onPressed: () {
                            // Handle Facebook Login
                          },
                        ),
                        SizedBox(width: 10),
                        IconButton(
                          icon: Icon(Icons.g_translate, color: Colors.red),
                          onPressed: () {
                            // Handle Google Login
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Sign Up Link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Don’t have an account?'),
                    SizedBox(width: 5),
                    InkWell(
                      onTap: () {
                        // Navigate to Sign Up screen
                        Navigator.pushNamed(context, AppRoutes.register);
                      },
                      child: Text(
                        'Sign up',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}