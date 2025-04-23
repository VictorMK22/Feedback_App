import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool emailNotifications = true; // Default for email notifications
  bool smsNotifications = true; // Default for SMS notifications
  String selectedLanguage = 'en'; // Default language code (English)
  double fontSize = 16.0; // Default font size
  String selectedTheme = 'Light'; // Default theme
  Map<String, String> translations = {}; // Store translations
  bool isLoadingTranslations = true; // Track translation loading state

  final List<Map<String, String>> languages = [
    {'code': 'en', 'label': 'English'},
    {'code': 'sw', 'label': 'Swahili'},
    {'code': 'fr', 'label': 'French'},
    {'code': 'es', 'label': 'Spanish'},
    {'code': 'de', 'label': 'German'},
    {'code': 'zh', 'label': 'Chinese'},
    {'code': 'ar', 'label': 'Arabic'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      emailNotifications = prefs.getBool('email_notifications') ?? true;
      smsNotifications = prefs.getBool('sms_notifications') ?? true;
      selectedLanguage = prefs.getString('selected_language') ?? 'en';
      fontSize = prefs.getDouble('font_size') ?? 16.0;
      selectedTheme = prefs.getString('selected_theme') ?? 'Light';
    });
    await _loadTranslations(selectedLanguage);
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('email_notifications', emailNotifications);
    await prefs.setBool('sms_notifications', smsNotifications);
    await prefs.setString('selected_language', selectedLanguage);
    await prefs.setDouble('font_size', fontSize);
    await prefs.setString('selected_theme', selectedTheme);
  }

  // Fetch translations dynamically from the Django backend
  Future<void> _loadTranslations(String languageCode) async {
    setState(() {
      isLoadingTranslations = true;
    });
    try {
      final response = await http.get(
        Uri.parse('http://your-backend-url/api/translations/$languageCode/'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          translations =
              data.map((key, value) => MapEntry(key, value.toString()));
          isLoadingTranslations = false;
        });
      } else {
        throw Exception('Failed to load translations');
      }
    } catch (error) {
      setState(() {
        translations = {};
        isLoadingTranslations = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading translations: $error')),
      );
    }
  }

  void _changeFontSize(double value) {
    setState(() {
      fontSize = value;
    });
    _saveSettings(); // Save the updated font size
  }

  void _changeTheme(String? newValue) {
    setState(() {
      selectedTheme = newValue!;
    });
    _saveSettings(); // Save the updated theme
  }

  void _changeLanguage(String? newValue) async {
    setState(() {
      selectedLanguage = newValue!;
    });
    await _saveSettings();
    await _loadTranslations(newValue!); // Reload translations
  }

  void _toggleEmailNotifications(bool value) {
    setState(() {
      emailNotifications = value;
    });
    _saveSettings(); // Save the updated email notifications preference
  }

  void _toggleSmsNotifications(bool value) {
    setState(() {
      smsNotifications = value;
    });
    _saveSettings(); // Save the updated SMS notifications preference
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingTranslations) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          title: const Text('Settings'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Helper method to get a translated string
    String t(String key) {
      return translations[key] ??
          key; // Fallback to key if translation is missing
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text(
          t('settings'),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email Notifications
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(
                t('email_notifications'),
                style: TextStyle(fontSize: fontSize),
              ),
              trailing: Switch(
                value: emailNotifications,
                onChanged: _toggleEmailNotifications,
              ),
            ),

            const Divider(),

            // SMS Notifications
            ListTile(
              leading: const Icon(Icons.sms),
              title: Text(
                t('sms_notifications'),
                style: TextStyle(fontSize: fontSize),
              ),
              trailing: Switch(
                value: smsNotifications,
                onChanged: _toggleSmsNotifications,
              ),
            ),

            const Divider(),

            // Theme Selection
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: Text(
                t('theme'),
                style: TextStyle(fontSize: fontSize),
              ),
              trailing: DropdownButton<String>(
                value: selectedTheme,
                items: ['Light', 'Dark'].map((String theme) {
                  return DropdownMenuItem<String>(
                    value: theme,
                    child: Text(theme),
                  );
                }).toList(),
                onChanged: _changeTheme,
              ),
            ),

            const Divider(),

            // Language Selection
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(
                t('language'),
                style: TextStyle(fontSize: fontSize),
              ),
              trailing: DropdownButton<String>(
                value: selectedLanguage,
                items: languages.map((lang) {
                  return DropdownMenuItem<String>(
                    value: lang['code'],
                    child: Text(lang['label']!),
                  );
                }).toList(),
                onChanged: _changeLanguage,
              ),
            ),

            const Divider(),

            // Font Size Settings
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: Text(
                t('font_size'),
                style: TextStyle(fontSize: fontSize),
              ),
              subtitle: Slider(
                value: fontSize,
                min: 12.0,
                max: 24.0,
                divisions: 6,
                label: '${fontSize.round()}',
                onChanged: _changeFontSize,
              ),
            ),

            const Spacer(),

            // Back Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Return to the previous screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: Text(t('back_to_dashboard')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
