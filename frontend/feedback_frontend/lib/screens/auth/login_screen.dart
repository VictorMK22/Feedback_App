import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io'; // For SocketException
import 'package:http/http.dart' as http;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart'; // For PlatformException
import 'package:feedback_frontend/utils/validation.dart';
import 'package:feedback_frontend/utils/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:feedback_frontend/utils/token_service.dart';
import '../config/app_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Authentication Clients
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '1075337596698-4dltejn7eonencbf6gmeu55k7ohlikfn.apps.googleusercontent.com',
    serverClientId:
        '1075337596698-pca16pmr7h29t2lvcv0n4sh87m98o1lq.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  // State Variables
  bool _isLoading = false;
  bool _isFacebookLoading = false;
  bool _isGoogleLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _loginError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(BuildContext context) async {
    setState(() {
      _emailError = Validator.validateEmail(_emailController.text.trim());
      _passwordError = Validator.validatePassword(_passwordController.text);
      _loginError = null;
    });

    if (_emailError != null || _passwordError != null) return;

    setState(() => _isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/users/login/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username_or_email': _emailController.text.trim(),
              'password': _passwordController.text,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        await _storeUserData(responseData);

        if (mounted) {
          _navigateAfterLogin(responseData['role']?.toString().toLowerCase());
        }
      } else {
        setState(() =>
            _loginError = responseData['detail'] ?? 'Invalid credentials');
      }
    } on TimeoutException {
      setState(() => _loginError = 'Connection timeout. Please try again.');
    } on SocketException {
      setState(() => _loginError = 'No internet connection');
    } on http.ClientException catch (e) {
      setState(() => _loginError = 'Connection error: ${e.message}');
    } catch (e) {
      setState(() => _loginError = 'Login failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFacebookLogin() async {
    if (!mounted) return;

    try {
      setState(() {
        _isFacebookLoading = true;
        _loginError = null;
      });

      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        throw Exception(result.status == LoginStatus.cancelled
            ? 'Login cancelled by user'
            : 'Facebook login failed');
      }

      final accessToken = result.accessToken;
      if (accessToken == null) {
        throw Exception('Failed to retrieve access token');
      }

      final tokenMap = accessToken.toJson();
      final userData = await FacebookAuth.instance.getUserData();

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/facebook/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'access_token': tokenMap['token'],
          'user_id': tokenMap['userId'],
          'expires_at': tokenMap['expires'],
          'email': userData['email'],
          'name': userData['name'],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _storeUserData(data);

        if (mounted) {
          _navigateAfterLogin(data['role']?.toString().toLowerCase());
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } on SocketException {
      setState(() => _loginError = 'No internet connection');
    } on PlatformException catch (e) {
      setState(() => _loginError = 'Facebook login failed: ${e.message}');
    } on http.ClientException catch (e) {
      setState(() => _loginError = 'Network error: ${e.message}');
    } catch (e) {
      setState(() => _loginError = 'Facebook login failed. Please try again.');
      debugPrint('Facebook login error: $e');
    } finally {
      if (mounted) setState(() => _isFacebookLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (!mounted) return;

    try {
      setState(() {
        _isGoogleLoading = true;
        _loginError = null;
      });

      final GoogleSignInAccount? user = await _googleSignIn.signIn();
      if (user == null) return;

      final GoogleSignInAuthentication auth = await user.authentication;
      if (auth.accessToken == null || auth.idToken == null) {
        throw Exception('Missing authentication tokens from Google');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/google/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'access_token': auth.accessToken,
          'id_token': auth.idToken,
        }),
      );

      if (!mounted) return;

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        await _storeUserData(responseData);

        if (mounted) {
          _navigateAfterLogin(responseData['role']?.toString().toLowerCase());
        }
      } else {
        throw Exception(
            responseData['detail'] ?? 'Google authentication failed');
      }
    } on SocketException {
      setState(() => _loginError = 'No internet connection');
    } on PlatformException catch (e) {
      setState(() => _loginError = 'Google sign-in failed: ${e.message}');
    } on http.ClientException catch (e) {
      setState(() => _loginError = 'Network error: ${e.message}');
    } catch (e) {
      setState(() => _loginError = 'Google login failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _storeUserData(Map<String, dynamic> data) async {
    await TokenService.storeTokens(
      accessToken: data['access'],
      refreshToken: data['refresh'],
      expiresIn: data['expires_in'],
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', data['username'] ?? '');
  }

  void _navigateAfterLogin(String? role) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      role == 'admin' ? AppRoutes.adminDashboard : AppRoutes.home,
      (route) => false,
    );
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
              if (_loginError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _loginError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email or Username',
                  errorText: _emailError,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() => _emailError = null),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: _passwordError,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
                onChanged: (_) => setState(() => _passwordError = null),
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
                  onPressed: _isLoading ? null : () => _login(context),
                  child: _isLoading
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
                    icon: _isFacebookLoading
                        ? const CircularProgressIndicator(strokeWidth: 3)
                        : const Icon(Icons.facebook, color: Color(0xFF1877F2)),
                    onPressed: _isLoading || _isFacebookLoading
                        ? null
                        : _handleFacebookLogin,
                  ),
                  const SizedBox(width: 20),
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
                    icon: _isGoogleLoading
                        ? const CircularProgressIndicator(strokeWidth: 3)
                        : SvgPicture.asset(
                            'assets/images/google_logo.svg',
                            height: 24,
                          ),
                    onPressed: _isLoading || _isGoogleLoading
                        ? null
                        : _handleGoogleLogin,
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
}
