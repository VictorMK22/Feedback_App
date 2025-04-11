import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  void _loginWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In cancelled')),
        );
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final isSuccess = await AuthService().loginWithGoogle(googleAuth.idToken);

      if (isSuccess) {
        Navigator.pushNamed(context, '/home'); // Navigate to Home screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In failed')),
        );
      }
    } catch (e) {
      print('Error during Google Sign-In: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _loginWithGoogle(context),
          child: Text('Sign in with Google'),
        ),
      ),
    );
  }
}