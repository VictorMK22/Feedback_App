import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text(
          'Admin Dashboard',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Feedback Summary Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _FeedbackSummaryCard(
                  label: 'Total Feedback',
                  count: 125,
                  color: Colors.blueAccent,
                ),
                _FeedbackSummaryCard(
                  label: 'Pending Responses',
                  count: 45,
                  color: Colors.orange,
                ),
                _FeedbackSummaryCard(
                  label: 'Resolved Feedback',
                  count: 80,
                  color: Colors.green,
                ),
              ],
            ),
            SizedBox(height: 20),

            // Feedback Management Section
            Text(
              'Feedback Management',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 10),
            _FeedbackDetailCard(
              userName: 'John Smith',
              category: 'Urgent',
              status: 'Pending',
              dateReceived: '2023-10-10',
            ),
            SizedBox(height: 20),

            // Analytics and Reports Section
            Text(
              'Analytics & Reports',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 10),
            _ProgressBar(
              label: 'Response Rate',
              value: 0.75,
              color: Colors.blue,
            ),
            SizedBox(height: 10),
            _ProgressBar(
              label: 'Positive Feedback',
              value: 0.85,
              color: Colors.green,
            ),
            SizedBox(height: 30),

            // Dark Mode Toggle
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Implement dark mode toggle functionality here
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.grey[800],
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(
                  'Toggle Dark Mode',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget for Feedback Summary Cards
class _FeedbackSummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  _FeedbackSummaryCard({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: color),
          ),
        ],
      ),
    );
  }
}

// Widget for Detailed Feedback Card
class _FeedbackDetailCard extends StatelessWidget {
  final String userName;
  final String category;
  final String status;
  final String dateReceived;

  _FeedbackDetailCard({
    required this.userName,
    required this.category,
    required this.status,
    required this.dateReceived,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feedback from $userName',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Category: $category'),
            Text('Status: $status'),
            Text('Received on: $dateReceived'),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(Icons.reply, color: Colors.blue),
                  onPressed: () {
                    // Implement reply functionality
                  },
                ),
                IconButton(
                  icon: Icon(Icons.image, color: Colors.orange),
                  onPressed: () {
                    // Implement view functionality
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // Implement delete functionality
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget for Progress Bars
class _ProgressBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  _ProgressBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16)),
        SizedBox(height: 5),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey[300],
          color: color,
        ),
      ],
    );
  }
}