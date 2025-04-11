import 'package:flutter/material.dart';

class HomeDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        title: Text(
          'Dashboard',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              Text(
                'Welcome, [User Name]',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Here’s what’s happening today:',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 20),

              // Submit Feedback Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Submit Feedback screen
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                  child: Text('Submit Feedback'),
                ),
              ),
              SizedBox(height: 30),

              // Recent Feedback Section
              Text(
                'Recent Feedback',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),

              // Feedback Cards
              Column(
                children: [
                  FeedbackCard(
                    title: 'Feedback on appointment scheduling',
                    status: 'Pending',
                    statusColor: Colors.orange,
                  ),
                  FeedbackCard(
                    title: 'Feedback on hospital cleanliness',
                    status: 'Responded',
                    statusColor: Colors.green,
                  ),
                  FeedbackCard(
                    title: 'Feedback on doctor consultation',
                    status: 'Pending',
                    statusColor: Colors.orange,
                  ),
                ],
              ),
              SizedBox(height: 30),

              // Notifications Section
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'You have 2 unread responses to your feedback.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 30),

              // Search and Filter Section
              Text(
                'Search & Filter Feedback',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  // Open Search and Filter Options
                },
                icon: Icon(Icons.search, color: Colors.white),
                label: Text('Search Feedback'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Feedback Card Widget
class FeedbackCard extends StatelessWidget {
  final String title;
  final String status;
  final Color statusColor;

  FeedbackCard({
    required this.title,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                status,
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}