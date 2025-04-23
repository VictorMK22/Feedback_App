import 'dart:convert'; // For encoding JSON data
import 'package:http/http.dart' as http;

class FeedbackService {
  final String apiUrl = "http://127.0.0.1:8000/feedback/";

  Future<bool> submitFeedback(
      String feedback, double rating, String category) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'feedback': feedback,
          'rating': rating,
          'category': category,
        }),
      );

      if (response.statusCode == 201) {
        // Feedback successfully submitted
        return true;
      } else {
        // Failed to submit feedback
        return false;
      }
    } catch (error) {
      // Handle error
      // ignore: avoid_print
      print("Error submitting feedback: $error");
      return false;
    }
  }
}
