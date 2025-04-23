// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:feedback_frontend/utils/app_routes.dart';
import 'package:intl/intl.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  bool isLoading = true;
  String userName = '';
  String profileImageUrl = '';
  List<Map<String, dynamic>> feedbackList = [];
  List<Map<String, dynamic>> filteredFeedbackList = [];
  String notifications = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _refreshAccessToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null) {
        throw Exception('No refresh token found. Please log in again.');
      }
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('access_token', data['access']);
      } else {
        throw Exception('Failed to refresh token.');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing token: $error')),
        );
      }
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');
      if (accessToken == null) throw Exception('No access token found');
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/feedback/home-dashboard/'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final allFeedback = List<Map<String, dynamic>>.from(data['feedback']);
        allFeedback.sort((a, b) => DateTime.parse(b['created_at'])
            .compareTo(DateTime.parse(a['created_at'])));
        setState(() {
          userName = data['username'] ?? 'User';
          profileImageUrl = data['profile_image_url'] ?? '';
          feedbackList = allFeedback;
          filteredFeedbackList = allFeedback;
          notifications = data['notifications'] ?? '';
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        await _refreshAccessToken();
        await _fetchDashboardData();
      } else {
        throw Exception('Failed to load dashboard data');
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (_selectedIndex) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.feedbackHistory);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.notifications);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.profile);
        break;
    }
  }

  void _logoutUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear user data
    Navigator.pushReplacementNamed(
        context, AppRoutes.login); // Navigate to login screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentFeedback = filteredFeedbackList.take(3).toList();
    final totalPending =
        feedbackList.where((f) => f['status'] == 'Pending').length;
    final totalResponded =
        feedbackList.where((f) => f['status'] == 'Responded').length;
    final totalFeedback = feedbackList.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text(
          'Home Dashboard',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Hello, $userName!',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            PopupMenuButton(
                              onSelected: (value) {
                                if (value == 'settings') {
                                  Navigator.pushNamed(
                                      context, AppRoutes.settings);
                                } else if (value == 'logout') {
                                  _logoutUser();
                                }
                              },
                              tooltip: 'Profile Options',
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry>[
                                const PopupMenuItem(
                                  value: 'settings',
                                  child: ListTile(
                                    leading: Icon(Icons.settings),
                                    title: Text('Settings'),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'logout',
                                  child: ListTile(
                                    leading: Icon(Icons.logout),
                                    title: Text('Logout'),
                                  ),
                                ),
                              ],
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(25),
                                child: profileImageUrl.isNotEmpty
                                    ? Image.network(
                                        profileImageUrl,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Colors.grey,
                                          );
                                        },
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return const CircularProgressIndicator();
                                        },
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text('Total Feedback: $totalFeedback',
                            style: const TextStyle(fontSize: 16)),
                        Text('Pending: $totalPending',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.orange)),
                        Text('Responded: $totalResponded',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.green)),
                        const SizedBox(height: 10),
                        Center(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamed(
                                context, AppRoutes.feedbackSubmission),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                              textStyle: const TextStyle(fontSize: 18),
                            ),
                            child: const Text('Submit Feedback'),
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text('Recent Feedback',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        const SizedBox(height: 10),
                        recentFeedback.isEmpty
                            ? const Text('No feedback available.',
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey))
                            : Column(
                                children: recentFeedback.map((feedback) {
                                  return FeedbackCard(
                                    title: feedback['title'],
                                    status: feedback['status'],
                                    timestamp: feedback['created_at'],
                                    statusColor:
                                        feedback['status'] == 'Responded'
                                            ? Colors.green
                                            : Colors.orange,
                                  );
                                }).toList(),
                              ),
                        if (feedbackList.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, AppRoutes.feedbackHistory),
                                child: const Text('See All'),
                              ),
                            ),
                          ),
                        const SizedBox(height: 30),
                        const Text('Notifications',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: notifications.isNotEmpty
                                ? Colors.red.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.notifications,
                                  color: Colors.red),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  notifications.isNotEmpty
                                      ? notifications
                                      : 'No new notifications.',
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

class FeedbackCard extends StatelessWidget {
  final String title;
  final String status;
  final Color statusColor;
  final String timestamp;

  const FeedbackCard(
      {super.key,
      required this.title,
      required this.status,
      required this.statusColor,
      required this.timestamp});

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(timestamp));

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(status,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formattedDate,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
