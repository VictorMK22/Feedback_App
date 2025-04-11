class Report {
  final int id;
  final String title;
  final String description;
  final String createdAt;
  final int feedbackId; // Links to a specific Feedback
  final int adminId;    // Links to the Admin who created the report

  Report({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.feedbackId,
    required this.adminId,
  });

  // Factory constructor to create a Report instance from JSON
  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      createdAt: json['created_at'],
      feedbackId: json['feedback_id'],
      adminId: json['admin_id'],
    );
  }

  // Convert a Report instance to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created_at': createdAt,
      'feedback_id': feedbackId,
      'admin_id': adminId,
    };
  }
}