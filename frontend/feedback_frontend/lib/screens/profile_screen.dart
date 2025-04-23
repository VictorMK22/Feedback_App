// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String language = 'English';
  bool isEditingName = false;
  bool isEditingEmail = false;

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

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> _refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null) throw Exception('No refresh token found');

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await prefs.setString('access_token', data['access']);
    } else {
      throw Exception('Failed to refresh token');
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    String? token = await _getAccessToken();

    var response = await http.get(
      Uri.parse('http://127.0.0.1:8000/users/profile/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 401) {
      await _refreshAccessToken();
      token = await _getAccessToken(); // get new token
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  void _fetchProfileData() async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/users/profile/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          nameController.text = data['username'];
          emailController.text = data['email'];
          language = _mapCodeToLanguage(data['preferred_language']);
        });
      } else {
        throw Exception('Failed to fetch profile: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        final headers = await _getAuthHeaders();

        final response = await http.put(
          Uri.parse('http://127.0.0.1:8000/users/profile/update/'),
          headers: headers,
          body: jsonEncode({
            "username": nameController.text,
            "email": emailController.text,
            "preferred_language": _mapLanguageToCode(language),
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Profile updated successfully'),
          ));
          setState(() {
            isEditingName = false;
            isEditingEmail = false;
          });
        } else {
          throw Exception('Failed to update profile: ${response.body}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _uploadProfilePicture() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      try {
        final token = await _getAccessToken();
        final request = http.MultipartRequest(
          'PUT',
          Uri.parse('http://127.0.0.1:8000/users/profile/update/'),
        );

        request.headers['Authorization'] = 'Bearer $token';
        request.files.add(await http.MultipartFile.fromPath(
          'profile_picture',
          picked.path,
        ));

        final response = await request.send();

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated')),
          );
        } else {
          throw Exception('Failed to upload picture');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        NetworkImage('https://via.placeholder.com/150'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _uploadProfilePicture,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: language,
                items: ['English', 'French', 'Spanish', 'Swahili']
                    .map((lang) =>
                        DropdownMenuItem(value: lang, child: Text(lang)))
                    .toList(),
                onChanged: (val) => setState(() => language = val!),
                decoration:
                    const InputDecoration(labelText: 'Preferred Language'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Save Changes'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                // ignore: avoid_print
                onPressed: () => print('Logging out...'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Logout'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
