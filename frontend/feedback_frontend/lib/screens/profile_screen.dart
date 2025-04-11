import 'package:flutter/material.dart';
import 'utils/validation.dart'; // Importing centralized validation methods

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool emailNotifications = true; // Controls the email notifications toggle
  String theme = "Light"; // Default theme
  String language = "English"; // Default language

  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  void _saveProfile() {
    String phoneNumber = phoneNumberController.text.trim();
    String bio = bioController.text.trim();

    // Validate inputs using Validator methods
    String? phoneNumberError = Validator.validatePhoneNumber(phoneNumber);
    String? bioError = Validator.validateBio(bio);

    // Check for errors
    if (phoneNumberError != null || bioError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          phoneNumberError ?? bioError!,
        )),
      );
      return;
    }

    // Validation passed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile changes saved successfully')),
    );

    // Call backend API for saving profile changes here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture Section
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                      AssetImage('assets/images/profile_picture.png'), // Replace with actual image
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          // Implement edit profile picture functionality
                        },
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.edit, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // User Details
              Text(
                'Sarah Connor', // Replace with dynamic name
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                'sarah.connor@example.com', // Replace with dynamic email
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 20),

              // Change Password Button
              ElevatedButton(
                onPressed: () {
                  // Navigate to Change Password screen
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: TextStyle(fontSize: 16),
                ),
                child: Text('Change Password'),
              ),
              SizedBox(height: 20),

              // Email Notifications Section
              ListTile(
                title: Text(
                  'Email Notifications',
                  style: TextStyle(fontSize: 16),
                ),
                trailing: Switch(
                  value: emailNotifications,
                  onChanged: (bool value) {
                    setState(() {
                      emailNotifications = value;
                    });
                  },
                ),
              ),
              Divider(),

              // Theme Section
              ListTile(
                title: Text(
                  'Theme',
                  style: TextStyle(fontSize: 16),
                ),
                trailing: DropdownButton<String>(
                  value: theme,
                  onChanged: (String? newValue) {
                    setState(() {
                      theme = newValue!;
                    });
                  },
                  items: <String>['Light', 'Dark']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
              Divider(),

              // Language Section
              ListTile(
                title: Text(
                  'Language',
                  style: TextStyle(fontSize: 16),
                ),
                trailing: DropdownButton<String>(
                  value: language,
                  onChanged: (String? newValue) {
                    setState(() {
                      language = newValue!;
                    });
                  },
                  items: <String>['English', 'Spanish', 'French']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
              Divider(),

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

              // Bottom Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to Edit Profile screen
                    },
                    style: ElevatedButton.styleFrom(primary: Colors.blueAccent),
                    child: Text('Edit Profile'),
                  ),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(primary: Colors.green),
                    child: Text('Save Changes'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Log out functionality
                    },
                    style: ElevatedButton.styleFrom(primary: Colors.red),
                    child: Text('Log Out'),
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