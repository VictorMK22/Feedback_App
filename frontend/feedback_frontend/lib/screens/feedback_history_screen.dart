import 'package:flutter/material.dart';

class FeedbackHistoryScreen extends StatefulWidget {
  @override
  _FeedbackHistoryScreenState createState() => _FeedbackHistoryScreenState();
}

class _FeedbackHistoryScreenState extends State<FeedbackHistoryScreen> {
  final TextEditingController searchController = TextEditingController();
  String sortBy = "Date"; // Default sort option
  String statusFilter = "All"; // Default status filter
  String categoryFilter = "All"; // Default category filter

  List<Map<String, String>> feedbacks = [
    {
      "title": "Feedback Title 1",
      "status": "Pending",
      "date": "12 Jan 2023",
    },
    {
      "title": "Feedback Title 2",
      "status": "Responded",
      "date": "5 Jan 2023",
    },
    {
      "title": "Feedback Title 3",
      "status": "Pending",
      "date": "20 Dec 2022",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text('Feedback History'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search feedback...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                // Implement search logic here
              },
            ),
            SizedBox(height: 20),

            // Filter Options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Implement sort by date logic
                  },
                  icon: Icon(Icons.date_range),
                  label: Text('Sort by Date'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blueAccent,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Implement filter by status logic
                  },
                  icon: Icon(Icons.filter_list),
                  label: Text('Filter by Status'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blueAccent,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Implement filter by category logic
                  },
                  icon: Icon(Icons.category),
                  label: Text('Filter by Category'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blueAccent,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Feedback Entries
            Expanded(
              child: ListView.builder(
                itemCount: feedbacks.length,
                itemBuilder: (context, index) {
                  final feedback = feedbacks[index];
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(feedback['title']!),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ${feedback['status']}'),
                          Text('Date: ${feedback['date']}'),
                        ],
                      ),
                      trailing: TextButton(
                        onPressed: () {
                          // Implement expand functionality here
                        },
                        child: Text(
                          'Expand',
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}