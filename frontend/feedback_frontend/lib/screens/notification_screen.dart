import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  NotificationScreenState createState() => NotificationScreenState();
}

class NotificationScreenState extends State<NotificationScreen> {
  String filterOption = "All Notifications";
  List<dynamic> notifications = [];
  bool isLoading = true;
  bool isRefreshing = false;
  String? authToken;
  String? errorMessage;
  int currentPage = 1;
  bool hasMore = true;

  String getBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000';
    }
    return 'http://localhost:8000';
  }

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications({bool refresh = false}) async {
    try {
      if (refresh) {
        setState(() => isRefreshing = true);
        currentPage = 1;
        hasMore = true;
      } else {
        setState(() => isLoading = true);
      }

      errorMessage = null;
      final prefs = await SharedPreferences.getInstance();
      authToken = prefs.getString('auth_token');

      if (authToken == null) {
        setState(() => errorMessage = 'Please login to view notifications');
        return;
      }

      final response = await http.get(
        Uri.parse('${getBaseUrl()}/notifications/?page=$currentPage'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (refresh || currentPage == 1) {
            notifications = data['results'];
          } else {
            notifications.addAll(data['results']);
          }
          hasMore = data['next'] != null;
        });
      } else if (response.statusCode == 401) {
        setState(() => errorMessage = 'Session expired. Please login again');
      } else {
        setState(() => errorMessage = 'Failed to load notifications');
      }
    } catch (e) {
      setState(() => errorMessage = 'Connection error. Please try again');
      debugPrint('Error fetching notifications: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
      }
    }
  }

  Future<void> loadMoreNotifications() async {
    if (!hasMore || isLoading) return;

    setState(() => isLoading = true);
    currentPage++;
    await fetchNotifications();
  }

  Future<void> markAsRead(String notificationId) async {
    if (authToken == null) return;

    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/notifications/$notificationId/read/'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        // Update local state instead of full refresh for better performance
        setState(() {
          final index = notifications
              .indexWhere((n) => n['id'].toString() == notificationId);
          if (index != -1) {
            notifications[index]['status'] = 'Read';
          }
        });
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  List<dynamic> get filteredNotifications {
    if (filterOption == "Unread Only") {
      return notifications.where((n) => n['status'] == 'Unread').toList();
    }
    return notifications;
  }

  Widget _buildNotificationItem(BuildContext context, int index) {
    final notification = filteredNotifications[index];
    final isUnread = notification['status'] == 'Unread';

    return Card(
      color: isUnread ? Colors.blue.shade50 : Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          notification["type"] == "Response Alert"
              ? Icons.notifications_active
              : Icons.info,
          color: notification["type"] == "Response Alert"
              ? Colors.blueAccent
              : Colors.grey,
        ),
        title: Text(
          notification["type"] ?? 'Notification',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isUnread ? Colors.blue.shade900 : Colors.grey.shade800,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification["message"] ?? ''),
            const SizedBox(height: 4),
            Text(
              notification["date"] ?? '',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        trailing: isUnread ? const NewBadge() : null,
        onTap: () => markAsRead(notification['id'].toString()),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            filterOption == 'Unread Only'
                ? 'No unread notifications'
                : 'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          if (filterOption == 'Unread Only') ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  setState(() => filterOption = 'All Notifications'),
              child: const Text('Show all notifications'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButton<String>(
              value: filterOption,
              underline: Container(),
              dropdownColor: Colors.white,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => filterOption = newValue);
                }
              },
              items: ['Unread Only', 'All Notifications']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: filterOption == value
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
              icon: const Icon(Icons.filter_list, color: Colors.white),
            ),
          ),
        ],
      ),
      body: errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: fetchNotifications,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : isLoading && notifications.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : filteredNotifications.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () => fetchNotifications(refresh: true),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (scrollNotification) {
                          if (scrollNotification.metrics.pixels ==
                                  scrollNotification.metrics.maxScrollExtent &&
                              hasMore &&
                              !isLoading) {
                            loadMoreNotifications();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount:
                              filteredNotifications.length + (hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == filteredNotifications.length) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: hasMore
                                      ? const CircularProgressIndicator()
                                      : const Text('No more notifications'),
                                ),
                              );
                            }
                            return _buildNotificationItem(context, index);
                          },
                        ),
                      ),
                    ),
    );
  }
}

class NewBadge extends StatelessWidget {
  const NewBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'NEW',
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
