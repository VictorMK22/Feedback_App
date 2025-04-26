// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:feedback_frontend/utils/token_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();

  // Original values from server
  String originalUsername = '';
  String originalEmail = '';
  String originalLanguageCode = 'en';
  bool originalIsVerified = false;

  // Current UI state
  String language = 'English';
  String? profilePictureUrl;
  String? bio;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);
    try {
      final headers = await TokenService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/users/profile/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        final profile = data['profile'];

        setState(() {
          // Set controller values
          nameController.text = user['username'];
          emailController.text = user['email'];

          // Store original values
          originalUsername = user['username'];
          originalEmail = user['email'];
          originalLanguageCode = user['preferred_language'];
          originalIsVerified = user['is_verified'] ?? false;

          // Set UI state
          language = _mapCodeToLanguage(user['preferred_language']);
          profilePictureUrl = profile['profile_picture'] != null
              ? 'http://127.0.0.1:8000${profile['profile_picture']}'
              : null;
          bio = profile['bio'];
        });
      } else {
        throw Exception('Failed to fetch profile: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final headers = await TokenService.getAuthHeaders();
      final Map<String, dynamic> body = {};

      // Only include changed fields
      if (nameController.text != originalUsername) {
        body['username'] = nameController.text;
      }
      if (emailController.text != originalEmail && originalIsVerified) {
        body['email'] = emailController.text;
      }
      if (_mapLanguageToCode(language) != originalLanguageCode) {
        body['preferred_language'] = _mapLanguageToCode(language);
      }

      // Skip API call if nothing changed
      if (body.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No changes to save')),
        );
        return;
      }

      final response = await http.put(
        Uri.parse('http://127.0.0.1:8000/users/profile/update/'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // Update original values after successful save
          originalUsername = data['user']['username'] ?? originalUsername;
          originalEmail = data['user']['email'] ?? originalEmail;
          originalLanguageCode =
              data['user']['preferred_language'] ?? originalLanguageCode;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Update failed';
        throw Exception(error);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadProfilePicture() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null) return;

    setState(() => _isLoading = true);
    try {
      final token = await TokenService.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token is missing');
      }

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('http://127.0.0.1:8000/users/profile/update/'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath(
        'profile_picture',
        picked.path,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile picture updated successfully!')),
        );
        _fetchProfileData();
      } else {
        throw Exception('Failed to upload picture: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/auth/resend-verification/'),
        headers: await TokenService.getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully!')),
    );
  }

  String _mapLanguageToCode(String lang) {
    switch (lang) {
      case 'French':
        return 'fr';
      case 'Spanish':
        return 'es';
      case 'Swahili':
        return 'sw';
      default:
        return 'en';
    }
  }

  String _mapCodeToLanguage(String code) {
    switch (code) {
      case 'fr':
        return 'French';
      case 'es':
        return 'Spanish';
      case 'sw':
        return 'Swahili';
      default:
        return 'English';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: profilePictureUrl != null
                              ? NetworkImage(profilePictureUrl!)
                              : const NetworkImage(
                                  'https://via.placeholder.com/150'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: _uploadProfilePicture,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Name cannot be empty';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: emailController,
                      enabled: originalIsVerified,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        suffixIcon: originalIsVerified
                            ? const Icon(Icons.verified, color: Colors.green)
                            : IconButton(
                                icon: const Icon(Icons.warning,
                                    color: Colors.orange),
                                onPressed: _resendVerificationEmail,
                                tooltip: 'Resend verification email',
                              ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email cannot be empty';
                        } else if (!value.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: language,
                      items: ['English', 'French', 'Spanish', 'Swahili']
                          .map((lang) => DropdownMenuItem(
                                value: lang,
                                child: Text(lang),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => language = val!),
                      decoration: const InputDecoration(
                          labelText: 'Preferred Language'),
                    ),
                    if (bio != null) ...[
                      const SizedBox(height: 10),
                      Text('Bio: $bio'),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Save Changes'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
