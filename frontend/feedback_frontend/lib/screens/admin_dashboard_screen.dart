import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool isDarkMode = false;
  TextEditingController searchController = TextEditingController();
  DateTime selectedDate = DateTime(2025, 10, 10);

  // Sample data
  int totalFeedback = 125;
  int pendingResponses = 45;
  int resolvedFeedback = 80;
  double responseRate = 0.75;
  double positiveFeedback = 0.60;

  List<FeedbackItem> feedbackItems = [
    FeedbackItem(
      id: '1',
      userName: 'John Smith',
      category: 'Urgent',
      status: 'Pending',
      dateReceived: DateTime(2025, 10, 10),
    ),
  ];

  void toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
    // In a real app, you'd apply this theme change globally
  }

  void showSearchResults(String query) {
    // Implement search functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Searching for: $query')),
    );
  }

  void replyToFeedback(String id) {
    // Show reply dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reply to Feedback'),
        content: const TextField(
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Type your response here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reply sent successfully')),
              );

              // Update the feedback status
              setState(() {
                final index = feedbackItems.indexWhere((item) => item.id == id);
                if (index != -1) {
                  feedbackItems[index].status = 'Responded';
                  pendingResponses--;
                  resolvedFeedback++;
                  responseRate = resolvedFeedback / totalFeedback;
                }
              });
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void viewFeedbackDetails(String id) {
    // Show feedback details
    final feedback = feedbackItems.firstWhere((item) => item.id == id);
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Feedback from ${feedback.userName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sample feedback content: I had difficulty scheduling an appointment through the online portal. The system kept showing errors when I tried to select a time slot.',
              style: TextStyle(fontSize: 16),
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
                'Date Received: ${DateFormat('yyyy-MM-dd').format(feedback.dateReceived)}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void deleteFeedback(String id) {
    // Confirm deletion
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feedback'),
        content: const Text('Are you sure you want to delete this feedback?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                final item = feedbackItems.firstWhere((item) => item.id == id);
                if (item.status == 'Pending') {
                  pendingResponses--;
                } else {
                  resolvedFeedback--;
                }
                totalFeedback--;
                feedbackItems.removeWhere((item) => item.id == id);
                responseRate =
                    totalFeedback > 0 ? resolvedFeedback / totalFeedback : 0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feedback deleted successfully')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> selectDate(BuildContext context, FeedbackItem feedback) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: feedback.dateReceived,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != feedback.dateReceived) {
      setState(() {
        feedback.dateReceived = picked;
      });
    }
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
        appBar: AppBar(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.menu,
                color: isDarkMode ? Colors.white : Colors.black),
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
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 10),
              child: ElevatedButton(
                onPressed: () => showSearchResults(searchController.text),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications pressed')),
                );
              },
            ),
            const SizedBox(width: 15),
          ],
        ),
        body: SingleChildScrollView(
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
                      color:
                          isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
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
                          GestureDetector(
                            onTap: () => selectDate(context, feedback),
                            child: Row(
                              children: [
                                const Text('Date Received: '),
                                Text(
                                  DateFormat('yyyy-MM-dd')
                                      .format(feedback.dateReceived),
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Color(0xFF5C6BF1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF5C6BF1),
                                child: IconButton(
                                  icon: const Icon(Icons.reply,
                                      color: Colors.white),
                                  onPressed: () => replyToFeedback(feedback.id),
                                ),
                              ),
                              const SizedBox(width: 15),
                              CircleAvatar(
                                backgroundColor: const Color(0xFFFFC107),
                                child: IconButton(
                                  icon: const Icon(Icons.mail_outline,
                                      color: Colors.white),
                                  onPressed: () =>
                                      viewFeedbackDetails(feedback.id),
                                ),
                              ),
                              const SizedBox(width: 15),
                              CircleAvatar(
                                backgroundColor: Colors.red,
                                child: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.white),
                                  onPressed: () => deleteFeedback(feedback.id),
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
                    const Text('Response Rate', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 5),
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
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
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF3F3728)
                      : const Color(0xFFFFFBE6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Positive Feedback',
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 5),
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: (positiveFeedback * 100).round(),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: const Color(0xFF4CAF50),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 100 - (positiveFeedback * 100).round(),
                            child: const SizedBox(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Dark Mode Toggle
              Center(
                child: Container(
                  width: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C6BF1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ElevatedButton.icon(
                    icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                    onPressed: toggleDarkMode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    label: Text(
                      isDarkMode ? 'Light Mode' : 'Dark Mode',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeedbackItem {
  final String id;
  final String userName;
  final String category;
  String status;
  DateTime dateReceived;

  FeedbackItem({
    required this.id,
    required this.userName,
    required this.category,
    required this.status,
    required this.dateReceived,
  });
}
