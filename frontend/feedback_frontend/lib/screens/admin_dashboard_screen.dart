// ignore_for_file: use_build_context_synchronously, unnecessary_to_list_in_spreads

import 'package:feedback_frontend/utils/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io' show Platform;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  bool isDarkMode = false;
  bool isLoading = true;
  bool hasError = false;
  TextEditingController searchController = TextEditingController();

  // Data that will be fetched from backend
  int totalFeedback = 0;
  int pendingResponses = 0;
  int resolvedFeedback = 0;
  double responseRate = 0.0;
  List<FeedbackItem> feedbackItems = [];
  List<ResponseItem> responseItems = [];

  final _secureStorage = const FlutterSecureStorage();

  // Bottom navigation bar screens
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardContent(
        isDarkMode: isDarkMode,
        isLoading: isLoading,
        hasError: hasError,
        totalFeedback: totalFeedback,
        pendingResponses: pendingResponses,
        resolvedFeedback: resolvedFeedback,
        responseRate: responseRate,
        feedbackItems: feedbackItems,
        responseItems: responseItems,
        onRefresh: _fetchDashboardData,
        onReply: replyToFeedback,
        onViewDetails: viewFeedbackDetails,
        searchController: searchController,
      ),
      ResponsesScreen(responseItems: responseItems),
      const NotificationsScreen(),
      const _ProfileScreen(), // Using renamed local version
    ];
    _fetchDashboardData();
  }

  String getBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000';
    }
    return 'http://localhost:8000';
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final headers = await _getAuthHeaders();

      // Fetch dashboard summary
      final dashboardResponse = await http.get(
        Uri.parse('${getBaseUrl()}/feedback/home-dashboard/'),
        headers: headers,
      );

      if (dashboardResponse.statusCode == 200) {
        final dashboardData = json.decode(dashboardResponse.body);
        setState(() {
          totalFeedback = dashboardData['total_feedback'] ?? 0;
          pendingResponses = dashboardData['pending_responses'] ?? 0;
          resolvedFeedback = dashboardData['resolved_feedback'] ?? 0;
          responseRate =
              totalFeedback > 0 ? resolvedFeedback / totalFeedback : 0;
        });
      } else if (dashboardResponse.statusCode == 401) {
        _handleTokenExpired();
        return;
      } else {
        throw Exception('Failed to load dashboard data');
      }

      // Fetch feedback items
      final feedbackResponse = await http.get(
        Uri.parse('${getBaseUrl()}/feedback/list/'),
        headers: headers,
      );

      if (feedbackResponse.statusCode == 200) {
        final feedbackData = json.decode(feedbackResponse.body) as List;
        setState(() {
          feedbackItems = feedbackData
              .map((item) => FeedbackItem(
                    id: item['id'].toString(),
                    userName: item['user']?['name'] ?? 'Anonymous',
                    category: item['category'] ?? 'General',
                    status: item['status'] ?? 'Pending',
                    dateReceived: DateTime.parse(item['created_at']),
                    content: item['content'] ?? '',
                  ))
              .toList();
        });
      } else if (feedbackResponse.statusCode == 401) {
        _handleTokenExpired();
        return;
      } else {
        throw Exception('Failed to load feedback items');
      }

      // Fetch responses
      final responseResponse = await http.get(
        Uri.parse('${getBaseUrl()}/response/list/'),
        headers: headers,
      );

      if (responseResponse.statusCode == 200) {
        final responseData = json.decode(responseResponse.body) as List;
        setState(() {
          responseItems = responseData
              .map((item) => ResponseItem(
                    id: item['id'].toString(),
                    feedbackId: item['feedback_id'].toString(),
                    content: item['content'] ?? '',
                    createdAt: DateTime.parse(item['created_at']),
                  ))
              .toList();
          responseRate =
              totalFeedback > 0 ? responseItems.length / totalFeedback : 0;
        });
      } else if (responseResponse.statusCode == 401) {
        _handleTokenExpired();
        return;
      }
    } catch (e) {
      setState(() {
        hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          _screens[0] = DashboardContent(
            isDarkMode: isDarkMode,
            isLoading: isLoading,
            hasError: hasError,
            totalFeedback: totalFeedback,
            pendingResponses: pendingResponses,
            resolvedFeedback: resolvedFeedback,
            responseRate: responseRate,
            feedbackItems: feedbackItems,
            responseItems: responseItems,
            onRefresh: _fetchDashboardData,
            onReply: replyToFeedback,
            onViewDetails: viewFeedbackDetails,
            searchController: searchController,
          );
        });
      }
    }
  }

  Future<void> _handleTokenExpired() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) {
        _logout();
        return;
      }

      final response = await http.post(
        Uri.parse('${getBaseUrl()}/users/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', responseData['access']);
        await _fetchDashboardData();
      } else {
        _logout();
      }
    } catch (e) {
      _logout();
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('username');
    await _secureStorage.delete(key: 'refresh_token');

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  Future<void> replyToFeedback(String id) async {
    final replyController = TextEditingController();
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reply to Feedback'),
        content: TextField(
          controller: replyController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Type your response here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (result == true && replyController.text.isNotEmpty) {
      setState(() => isLoading = true);

      try {
        final headers = await _getAuthHeaders();
        final response = await http.post(
          Uri.parse('${getBaseUrl()}/response/create/'),
          headers: headers,
          body: json.encode({
            'feedback_id': int.parse(id),
            'content': replyController.text,
          }),
        );

        if (response.statusCode == 201) {
          await _fetchDashboardData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reply sent successfully')),
          );
        } else if (response.statusCode == 401) {
          await _handleTokenExpired();
        } else {
          throw Exception('Failed to send reply');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending reply: ${e.toString()}')),
        );
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  Future<void> viewFeedbackDetails(String id) async {
    try {
      final feedback = feedbackItems.firstWhere((item) => item.id == id);
      final responsesForFeedback =
          responseItems.where((r) => r.feedbackId == id).toList();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Feedback from ${feedback.userName}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                feedback.content,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Category: '),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      feedback.category,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              Text('Status: ${feedback.status}'),
              Text(
                'Date Received: ${DateFormat('yyyy-MM-dd').format(feedback.dateReceived)}',
              ),
              const SizedBox(height: 16),
              if (responsesForFeedback.isNotEmpty) ...[
                const Text(
                  'Responses:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...responsesForFeedback
                    .map((response) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Response on ${DateFormat('yyyy-MM-dd').format(response.createdAt)}:',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(response.content),
                            const SizedBox(height: 8),
                          ],
                        ))
                    .toList(),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error showing details: ${e.toString()}')),
      );
    }
  }

  void toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
      _screens[0] = DashboardContent(
        isDarkMode: isDarkMode,
        isLoading: isLoading,
        hasError: hasError,
        totalFeedback: totalFeedback,
        pendingResponses: pendingResponses,
        resolvedFeedback: resolvedFeedback,
        responseRate: responseRate,
        feedbackItems: feedbackItems,
        responseItems: responseItems,
        onRefresh: _fetchDashboardData,
        onReply: replyToFeedback,
        onViewDetails: viewFeedbackDetails,
        searchController: searchController,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = isDarkMode
        ? ThemeData.dark().copyWith(
            primaryColor: const Color(0xFF5C6BF1),
            scaffoldBackgroundColor: const Color(0xFF121212),
          )
        : ThemeData.light().copyWith(
            primaryColor: const Color(0xFF5C6BF1),
          );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar:
            _currentIndex == 0 ? _buildDashboardAppBar() : _buildBasicAppBar(),
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF5C6BF1),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.reply_all),
              label: 'Responses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildDashboardAppBar() {
    return AppBar(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.menu, color: isDarkMode ? Colors.white : Colors.black),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu pressed')),
          );
        },
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          onSubmitted: (query) => _fetchDashboardData(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 10),
          child: ElevatedButton(
            onPressed: () => _fetchDashboardData(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C6BF1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Search'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
              color: Color(0xFF5C6BF1)),
          onPressed: () {
            setState(() => _currentIndex = 2); // Navigate to notifications
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _logout,
        ),
        const SizedBox(width: 15),
      ],
    );
  }

  AppBar _buildBasicAppBar() {
    return AppBar(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 0,
      title: Text(
        _getAppBarTitle(),
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _logout,
        ),
      ],
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Responses';
      case 2:
        return 'Notifications';
      case 3:
        return 'Profile';
      default:
        return 'Admin Panel';
    }
  }
}

class DashboardContent extends StatelessWidget {
  final bool isDarkMode;
  final bool isLoading;
  final bool hasError;
  final int totalFeedback;
  final int pendingResponses;
  final int resolvedFeedback;
  final double responseRate;
  final List<FeedbackItem> feedbackItems;
  final List<ResponseItem> responseItems;
  final VoidCallback onRefresh;
  final Function(String) onReply;
  final Function(String) onViewDetails;
  final TextEditingController searchController;

  const DashboardContent({
    super.key,
    required this.isDarkMode,
    required this.isLoading,
    required this.hasError,
    required this.totalFeedback,
    required this.pendingResponses,
    required this.resolvedFeedback,
    required this.responseRate,
    required this.feedbackItems,
    required this.responseItems,
    required this.onRefresh,
    required this.onReply,
    required this.onViewDetails,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : hasError
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Failed to load data'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: onRefresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => onRefresh(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Feedback Summary Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF1F2B5F)
                              : const Color(0xFFF0F3FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Feedback',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$totalFeedback',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF5C6BF1),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF3F3728)
                              : const Color(0xFFFFF9E6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pending Responses',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$pendingResponses',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFFC107),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF1C3B1C)
                              : const Color(0xFFE6FFE6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Resolved Feedback',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$resolvedFeedback',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Feedback Management Section
                      const Text(
                        'Feedback Management',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: feedbackItems.length,
                        itemBuilder: (context, index) {
                          final feedback = feedbackItems[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF2C2C2C)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.grey.withValues(alpha: 0.2 * 255),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    feedback.userName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text('Category: '),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          feedback.category,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text('Status: ${feedback.status}'),
                                  Row(
                                    children: [
                                      const Text('Date Received: '),
                                      Text(
                                        DateFormat('yyyy-MM-dd')
                                            .format(feedback.dateReceived),
                                        style: const TextStyle(
                                          color: Color(0xFF5C6BF1),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            const Color(0xFF5C6BF1),
                                        child: IconButton(
                                          icon: const Icon(Icons.reply,
                                              color: Colors.white),
                                          onPressed: () => onReply(feedback.id),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      CircleAvatar(
                                        backgroundColor:
                                            const Color(0xFFFFC107),
                                        child: IconButton(
                                          icon: const Icon(Icons.mail_outline,
                                              color: Colors.white),
                                          onPressed: () =>
                                              onViewDetails(feedback.id),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      // Analytics and Reports Section
                      const Text(
                        'Analytics & Reports',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF1F2B5F)
                              : const Color(0xFFF0F3FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Response Rate',
                                style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 5),
                            Container(
                              height: 10,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.grey[300],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: (responseRate * 100).round(),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: const Color(0xFF5C6BF1),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 100 - (responseRate * 100).round(),
                                    child: const SizedBox(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${(responseRate * 100).toStringAsFixed(1)}% response rate',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
  }
}

class ResponsesScreen extends StatelessWidget {
  final List<ResponseItem> responseItems;

  const ResponsesScreen({super.key, required this.responseItems});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: responseItems.length,
      itemBuilder: (context, index) {
        final response = responseItems[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Response to Feedback #${response.feedbackId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(response.content),
                const SizedBox(height: 8),
                Text(
                  'Posted on ${DateFormat('yyyy-MM-dd').format(response.createdAt)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No New Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll see notifications here when you have them',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final prefs = snapshot.data!;
        final username = prefs.getString('username') ?? 'Admin';

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFF5C6BF1),
                child: Text(
                  username[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                username,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Administrator',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  // Navigate to settings
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                onTap: () {
                  // Navigate to help
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign Out'),
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class FeedbackItem {
  final String id;
  final String userName;
  final String category;
  String status;
  DateTime dateReceived;
  String content;

  FeedbackItem({
    required this.id,
    required this.userName,
    required this.category,
    required this.status,
    required this.dateReceived,
    required this.content,
  });
}

class ResponseItem {
  final String id;
  final String feedbackId;
  final String content;
  final DateTime createdAt;

  ResponseItem({
    required this.id,
    required this.feedbackId,
    required this.content,
    required this.createdAt,
  });
}
