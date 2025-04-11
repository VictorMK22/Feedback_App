import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String filterOption = "All Notifications"; // Default filter

  // Example notifications list
  final List<Map<String, String>> notifications = [
    {
      "type": "Response Alert",
      "message": "Your feedback has been responded to.",
      "date": "Today, 10:30 AM",
    },
    {
      "type": "System Message",
      "message": "Your feedback has been reviewed.",
      "date": "Yesterday, 5:45 PM",
    },
    {
      "type": "Response Alert",
      "message": "Your feedback has been responded to.",
      "date": "2 days ago, 3:00 PM",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text('Notifications'),
        actions: [
          // Filter Dropdown
          DropdownButton<String>(
            value: filterOption,
            onChanged: (String? newValue) {
              setState(() {
                filterOption = newValue!;
              });
            },
            items: <String>['Unread Only', 'All Notifications']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            icon: Icon(Icons.filter_list, color: Colors.white),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Icon(
                notification["type"] == "Response Alert"
                    ? Icons.notifications
                    : Icons.info,
                color: notification["type"] == "Response Alert"
                    ? Colors.blueAccent
                    : Colors.grey,
              ),
              title: Text(
                notification["type"]!,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification["message"]!),
                  Text(
                    notification["date"]!,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}