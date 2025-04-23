// ignore_for_file: use_build_context_synchronously, duplicate_ignore

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:feedback_frontend/utils/validation.dart';
import 'package:feedback_frontend/utils/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String? emailError;
  String? passwordError;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  String getBaseUrl() {
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  Future<void> _login(BuildContext context) async {
    String emailOrUsername = emailController.text.trim();
    String password = passwordController.text;

    setState(() {
      emailError = Validator.validateEmail(emailOrUsername);
      passwordError = Validator.validatePassword(password);
    });

    if (emailError != null || passwordError != null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/users/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username_or_email': emailOrUsername,
          'password': password,
        }),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', responseData['access']);
        await prefs.setString('refresh_token', responseData['refresh']);
        final role = responseData['role'];
        final username = responseData['username'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Welcome $username!")),
        );

        if (role.toLowerCase() == 'admin') {
          Navigator.pushNamed(context, AppRoutes.adminDashboard);
        } else if (role.toLowerCase() == 'patient') {
          Navigator.pushNamed(context, AppRoutes.home);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unknown role detected.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Invalid credentials. Please try again.')),
        );
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60),
          child: Column(
            children: [
              const Icon(Icons.ac_unit, size: 60, color: Colors.blueAccent),
              const SizedBox(height: 10),
              const Text(
                'AppLogo',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent),
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome Back!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              const SizedBox(height: 5),
              const Text(
                'Log in to continue.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Email or Username',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  errorText: emailError,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  errorText: passwordError,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.forgotPassword),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                        color: Colors.blueAccent, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _login(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : const Text('Login'),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: const [
                  Expanded(child: Divider(thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("or continue with"),
                  ),
                  Expanded(child: Divider(thickness: 1)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton("Google", _signInWithGoogle),
                  const SizedBox(width: 20),
                  _buildSocialButton("Facebook", _signInWithFacebook),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don’t have an account?"),
                  const SizedBox(width: 5),
                  InkWell(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.register),
                    child: const Text(
                      "Sign up",
                      style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 4,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome ${userData['name']}')),
        );
        Navigator.pushNamed(context, AppRoutes.home);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Facebook login failed')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? user = await _googleSignIn.signIn();
      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome ${user.displayName}')),
        );
        Navigator.pushNamed(context, AppRoutes.home);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google login canceled')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }
}
