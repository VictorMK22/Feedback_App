import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // For profile picture upload
import 'package:feedback_frontend/utils/validation.dart'; // Centralized validation methods

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  String selectedRole = 'Patient'; // Default role
  String notificationPreference = 'Both'; // Default notification preference
  XFile? profilePicture; // Selected profile picture
  bool isLoading = false; // Controls loading indicator

  Future<void> _register() async {
    // Gather user inputs
    String username = usernameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;
    String phoneNumber = phoneNumberController.text.trim();
    String bio = bioController.text.trim();

    // Validate inputs using Validator methods
    String? usernameError = Validator.validateUsername(username);
    String? emailError = Validator.validateEmail(email);
    String? passwordError = Validator.validatePassword(password);
    String? confirmPasswordError =
        Validator.validateConfirmPassword(password, confirmPassword);
    String? phoneError = Validator.validatePhoneNumber(phoneNumber);
    String? bioError = Validator.validateBio(bio);

    // Show validation errors dynamically
    if (usernameError != null ||
        emailError != null ||
        passwordError != null ||
        confirmPasswordError != null ||
        phoneError != null ||
        bioError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(usernameError ??
              emailError ??
              passwordError ??
              confirmPasswordError ??
              phoneError ??
              bioError!),
        ),
      );
      return; // Stop registration process
    }

    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      // Prepare form data for API
      Map<String, dynamic> userData = {
        'username': username,
        'email': email,
        'password': password,
        'phone_number': phoneNumber,
        'bio': bio,
        'role': selectedRole,
        'notification_preference': notificationPreference,
      };

      // Include profile picture if selected
      if (profilePicture != null) {
        userData['profile_picture'] =
            base64Encode(await profilePicture!.readAsBytes());
      }

      // API call for registration
      final response = await http.post(
        Uri.parse(
            'http://127.0.0.1:8000/users/register/'), // Replace with your endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      setState(() {
        isLoading = false; // Stop loading indicator
      });

      if (response.statusCode == 201) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // Redirect to login screen
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')),
        );
      }
    } catch (error) {
      setState(() {
        isLoading = false; // Stop loading indicator
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  void _pickProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        profilePicture = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            const Center(
              child: Text(
                'Create an Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Username Field
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // Email Field
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // Password Field
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),

            // Confirm Password Field
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),

            // Role Dropdown
            Row(
              children: [
                const Text(
                  'Role:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedRole,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedRole = newValue!;
                    });
                  },
                  items: <String>['Patient', 'Admin']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Phone Number Field
            TextField(
              controller: phoneNumberController,
              decoration: const InputDecoration(
                labelText: 'Phone Number (Optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),

            // Notification Preference Dropdown
            Row(
              children: [
                const Text(
                  'Notification Preference:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: notificationPreference,
                  onChanged: (String? newValue) {
                    setState(() {
                      notificationPreference = newValue!;
                    });
                  },
                  items: <String>['SMS', 'Email', 'Both']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Profile Picture Picker
            Row(
              children: [
                const Text(
                  'Profile Picture:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                TextButton.icon(
                  onPressed: _pickProfilePicture,
                  icon: const Icon(Icons.add_a_photo, color: Colors.blueAccent),
                  label: const Text(
                    'Upload',
                    style: TextStyle(color: Colors.blueAccent),
                  ),
                ),
              ],
            ),
            if (profilePicture != null)
              Text(
                'Selected: ${profilePicture!.name}',
                style: const TextStyle(color: Colors.green),
              ),
            const SizedBox(height: 10),

            // Bio Field
            TextField(
              controller: bioController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Bio (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text('Register'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
