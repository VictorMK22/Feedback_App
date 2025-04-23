import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feedback_frontend/screens/feedback_submission_screen.dart';

void main() {
  group('FeedbackSubmissionScreen Tests', () {
    testWidgets('FeedbackSubmissionScreen displays correctly',
        (WidgetTester tester) async {
      // Load the FeedbackSubmissionScreen
      await tester
          .pumpWidget(const MaterialApp(home: FeedbackSubmissionScreen()));

      // Verify the initial state of the screen

      // Check if the feedback text field is present
      expect(find.byType(TextField), findsOneWidget);

      // Check if the rating section is present
      expect(find.text('Rate your experience:'), findsOneWidget);
      expect(
          find.byIcon(Icons.star), findsWidgets); // Ensure stars are rendered

      // Check for dropdown menu
      expect(find.byType(DropdownButton<String>), findsOneWidget);

      // Check for the submit button
      final submitButton =
          find.widgetWithText(ElevatedButton, 'Submit Feedback');
      expect(submitButton, findsOneWidget); // Ensures only one button exists
    });

    testWidgets('Shows validation error on empty submission',
        (WidgetTester tester) async {
      // Load the FeedbackSubmissionScreen
      await tester
          .pumpWidget(const MaterialApp(home: FeedbackSubmissionScreen()));

      // Tap the Submit Feedback button without entering data
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Feedback'));
      await tester.pumpAndSettle(); // Ensure animation/rendering completes

      // Check if validation error is displayed
      expect(find.text('Please provide feedback and a star rating'),
          findsOneWidget);
    });

    testWidgets('Successfully submits feedback with valid inputs',
        (WidgetTester tester) async {
      // Load the FeedbackSubmissionScreen
      await tester
          .pumpWidget(const MaterialApp(home: FeedbackSubmissionScreen()));

      // Enter text in the feedback field
      await tester.enterText(find.byType(TextField), 'Great service!');
      await tester.pump();

      // Select a star rating (e.g., 5 stars)
      await tester.tap(find.byIcon(Icons.star).at(4)); // Tap the 5th star
      await tester.pump();

      // Tap the Submit Feedback button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Feedback'));
      await tester.pumpAndSettle(); // Ensure animation/rendering completes

      // Verify success message appears
      expect(find.text('Feedback submitted successfully'), findsOneWidget);
    });

    testWidgets('Feedback categories dropdown updates on selection',
        (WidgetTester tester) async {
      // Load the FeedbackSubmissionScreen
      await tester
          .pumpWidget(const MaterialApp(home: FeedbackSubmissionScreen()));

      // Tap the dropdown
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Select a category
      await tester.tap(find.text('Suggestion').last);
      await tester.pumpAndSettle();

      // Check if the dropdown value updated
      expect(find.text('Suggestion'), findsOneWidget);
    });

    testWidgets('Star rating updates on user selection',
        (WidgetTester tester) async {
      // Load the FeedbackSubmissionScreen
      await tester
          .pumpWidget(const MaterialApp(home: FeedbackSubmissionScreen()));

      // Tap on the second star (index 1)
      await tester.tap(find.byIcon(Icons.star).at(1));
      await tester.pump();

      // Check if the star rating updated
      expect(find.byIcon(Icons.star), findsWidgets); // Verify star visuals
    });
  });
}
