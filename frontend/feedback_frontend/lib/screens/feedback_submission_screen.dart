import 'package:flutter/material.dart';
import 'dart:convert'; // For JSON encoding
import 'package:http/http.dart' as http; // For API calls
import 'package:feedback_frontend/utils/validation.dart'; // Importing centralized validation methods

class FeedbackSubmissionScreen extends StatefulWidget {
  const FeedbackSubmissionScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _FeedbackSubmissionScreenState createState() =>
      _FeedbackSubmissionScreenState();
}

class _FeedbackSubmissionScreenState extends State<FeedbackSubmissionScreen> {
  final TextEditingController feedbackController = TextEditingController();
  double starRating = 0; // Stores the selected star rating
  String selectedCategory = "Complaint"; // Default feedback category
  bool showNotification = true; // Show notification by default in this version
  final String apiUrl =
      "http://127.0.0.1:8000/feedback/create/"; // API endpoint

  Future<void> _submitFeedback() async {
    String feedback = feedbackController.text.trim();

    // Validate inputs using Validator methods
    String? feedbackError = Validator.validateFeedback(feedback);
    String? ratingError = Validator.validateStarRating(starRating);

    // Check for validation errors
    if (feedbackError != null || ratingError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide feedback and a star rating'),
        ),
      );
      return;
    }

    // Prepare feedback data
    Map<String, dynamic> feedbackData = {
      'feedback': feedback,
      'rating': starRating,
      'category': selectedCategory,
    };

    try {
      // API call to submit feedback
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(feedbackData),
      );

      if (response.statusCode == 201) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback submitted successfully')),
        );

        // Reset form
        setState(() {
          feedbackController.clear();
          starRating = 0;
          selectedCategory = "Complaint";
          showNotification = true;
        });
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit feedback. Please try again'),
          ),
        );
      }
    } catch (error) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Could not submit feedback')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Submit Feedback',
          style: TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blueAccent),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text Input for Feedback
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: feedbackController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Describe your experience...',
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Rate Your Experience Section
            const Text(
              'Rate Your Experience:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A4A4A),
              ),
            ),
            const SizedBox(height: 10),

            // Star Rating Row
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(5, (index) {
                return Icon(
                  Icons.star,
                  color:
                      index < starRating ? Colors.orange : Colors.grey.shade300,
                  size: 32,
                );
              }),
            ),
            const SizedBox(height: 20),

            // Microphone and Paperclip Buttons
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.mic, color: Colors.white),
                    onPressed: () {
                      // Voice input functionality
                    },
                  ),
                ),
                const Spacer(),
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.white),
                    onPressed: () {
                      // Attachment functionality
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Feedback Category Dropdown
            const Text(
              'Feedback Category:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A4A4A),
              ),
            ),
            const SizedBox(height: 10),

            // Dropdown styled as shown in the image
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.white,
              ),
              child: DropdownButton<String>(
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
                underline: Container(), // Remove the default underline
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Feedback Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Submit Feedback',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            // Thank You Notification
            if (showNotification)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
