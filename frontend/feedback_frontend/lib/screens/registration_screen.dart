import 'package:flutter/material.dart';
import 'utils/validation.dart'; // Importing centralized validation methods

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  String selectedRole = 'Patient'; // Default role
  String notificationPreference = 'Both'; // Default notification preference
  String? profilePicturePath; // Path for selected profile picture

  void _register() {
    // Fetch user inputs
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
    String? confirmPasswordError = Validator.validateConfirmPassword(password, confirmPassword);
    String? phoneError = Validator.validatePhoneNumber(phoneNumber);
    String? bioError = Validator.validateBio(bio);

    // Check for errors
    if (usernameError != null || emailError != null || passwordError != null || confirmPasswordError != null || phoneError != null || bioError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          usernameError ?? emailError ?? passwordError ?? confirmPasswordError ?? phoneError ?? bioError!,
        )),
      );
      return;
    }

    // Validation passed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registration successful')),
    );

    // Call backend API for registration here
  }

  void _pickProfilePicture() {
    // Logic for profile picture picker (e.g., using ImagePicker plugin)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Center(
              child: Text(
                'Create an Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Username Field
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            // Email Field
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            // Password Field
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 10),

            // Confirm Password Field
            TextField(
              controller: confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 10),

            // Role Dropdown
            Row(
              children: [
                Text(
                  'Role:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 10),
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
            SizedBox(height: 10),

            // Phone Number Field
            TextField(
              controller: phoneNumberController,
              decoration: InputDecoration(
                labelText: 'Phone Number (Optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 10),

            // Notification Preference Dropdown
            Row(
              children: [
                Text(
                  'Notification Preference:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 10),
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
            SizedBox(height: 10),

            // Profile Picture Picker
            Row(
              children: [
                Text(
                  'Profile Picture:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 10),
                TextButton.icon(
                  onPressed: _pickProfilePicture,
                  icon: Icon(Icons.add_a_photo, color: Colors.blueAccent),
                  label: Text(
                    'Upload',
                    style: TextStyle(color: Colors.blueAccent),
                  ),
                ),
              ],
            ),
            if (profilePicturePath != null)
              Text(
                'Selected: $profilePicturePath',
                style: TextStyle(color: Colors.green),
              ),
            SizedBox(height: 10),

            // Bio Field
            TextField(
              controller: bioController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Bio (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // Submit Button
            Center(
              child: ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  primary: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                ),
                child: Text('Register'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}