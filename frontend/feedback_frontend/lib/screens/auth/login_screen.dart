import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:feedback_frontend/utils/validation.dart';
import 'package:feedback_frontend/utils/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final _secureStorage = const FlutterSecureStorage();

  bool isLoading = false;
  String? emailError;
  String? passwordError;
  String? loginError;

  String getBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000';
    }
    return 'http://localhost:8000';
  }

  Future<void> _login(BuildContext context) async {
    setState(() {
      emailError = null;
      passwordError = null;
      loginError = null;
    });

    String emailOrUsername = emailController.text.trim();
    String password = passwordController.text;

    setState(() {
      emailError = Validator.validateEmail(emailOrUsername);
      passwordError = Validator.validatePassword(password);
    });

    if (emailError != null || passwordError != null) return;

    setState(() => isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse('${getBaseUrl()}/users/login/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username_or_email': emailOrUsername,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', responseData['access']);
        await _secureStorage.write(
            key: 'refresh_token', value: responseData['refresh']);
        await prefs.setString('username', responseData['username']);

        final role = responseData['role'].toString().toLowerCase();
        Navigator.pushNamedAndRemoveUntil(
          context,
          role == 'admin' ? AppRoutes.adminDashboard : AppRoutes.home,
          (route) => false,
        );
      } else {
        setState(() {
          loginError = responseData['detail'] ?? 'Invalid credentials';
        });
      }
    } on TimeoutException catch (_) {
      setState(() => loginError = 'Connection timeout. Please try again.');
    } on http.ClientException catch (e) {
      setState(() => loginError = 'Connection error: ${e.message}');
    } catch (e) {
      setState(() => loginError = 'An unexpected error occurred');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleFacebookLogin() async {
    try {
      setState(() => isLoading = true);
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', userData['name'] ?? 'User');

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        }
      } else {
        setState(() => loginError = 'Facebook login cancelled');
      }
    } catch (e) {
      setState(() => loginError = 'Facebook login failed');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    try {
      setState(() => isLoading = true);
      final GoogleSignInAccount? user = await _googleSignIn.signIn();

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', user.displayName ?? 'User');

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        }
      } else {
        setState(() => loginError = 'Google login cancelled');
      }
    } catch (e) {
      setState(() => loginError = 'Google login failed');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const FlutterLogo(size: 100),
              const SizedBox(height: 20),
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please sign in to continue',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 40),
              if (loginError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    loginError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email or Username',
                  errorText: emailError,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() => emailError = null),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: passwordError,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
                onChanged: (_) => setState(() => passwordError = null),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.forgotPassword),
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _login(context),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('LOGIN'),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Facebook Button
                  IconButton(
                    iconSize: 50,
                    padding: const EdgeInsets.all(12),
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    icon: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          )
                        : const Icon(Icons.facebook,
                            color: Color(0xFF1877F2)), // Official Facebook blue
                    onPressed: isLoading ? null : _handleFacebookLogin,
                  ),

                  const SizedBox(width: 20),

                  // Google Button
                  IconButton(
                    iconSize: 50,
                    padding: const EdgeInsets.all(12),
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    icon: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          )
                        : SvgPicture.asset(
                            'assets/images/google_logo.svg',
                            height: 24,
                            semanticsLabel: 'Google logo',
                          ),
                    onPressed: isLoading ? null : _handleGoogleLogin,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.register),
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
