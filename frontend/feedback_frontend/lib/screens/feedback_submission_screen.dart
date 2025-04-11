import 'package:flutter/material.dart';
import 'utils/validation.dart'; // Importing centralized validation methods

class FeedbackSubmissionScreen extends StatefulWidget {
  @override
  _FeedbackSubmissionScreenState createState() =>
      _FeedbackSubmissionScreenState();
}

class _FeedbackSubmissionScreenState extends State<FeedbackSubmissionScreen> {
  final TextEditingController feedbackController = TextEditingController();
  double starRating = 0; // Stores the selected star rating
  String selectedCategory = "Complaint"; // Default feedback category
  bool showNotification = false; // Controls the notification bar visibility

  void _submitFeedback() {
    String feedback = feedbackController.text.trim();

    // Validate inputs using Validator methods
    String? feedbackError = Validator.validateFeedback(feedback);
    String? ratingError = Validator.validateStarRating(starRating);

    // Check for errors
    if (feedbackError != null || ratingError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          feedbackError ?? ratingError!,
        )),
      );
      return;
    }

    // Validation passed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Feedback submitted successfully')),
    );

    // Call backend API for feedback submission here

    // Simulate notification display
    setState(() {
      showNotification = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Submit Feedback'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text Input for Feedback
            TextField(
              controller: feedbackController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Describe your experience...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // Star Rating Section
            Row(
              children: [
                Text(
                  'Rate your experience:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 10),
                Row(
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        Icons.star,
                        color: index < starRating ? Colors.orange : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          starRating = index + 1; // Set the rating
                        });
                      },
                    );
                  }),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Voice and Attachment Icons
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.mic, color: Colors.blue),
                  onPressed: () {
                    // Implement voice feedback functionality
                  },
                ),
                IconButton(
                  icon: Icon(Icons.attachment, color: Colors.blue),
                  onPressed: () {
                    // Implement attachment functionality
                  },
                ),
              ],
            ),
            SizedBox(height: 20),

            // Dropdown for Feedback Category
            Row(
              children: [
                Text(
                  'Feedback Category:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedCategory,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCategory = newValue!;
                    });
                  },
                  items: <String>['Complaint', 'Suggestion', 'Praise']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Submit Feedback Button
            Center(
              child: ElevatedButton(
                onPressed: _submitFeedback,
                style: ElevatedButton.styleFrom(
                  primary: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                ),
                child: Text('Submit Feedback'),
              ),
            ),

            // Thank You Notification
            if (showNotification)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Container(
                  padding: EdgeInsets.all(12),
                  color: Colors.green,
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Thank you! Your feedback has been received.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}