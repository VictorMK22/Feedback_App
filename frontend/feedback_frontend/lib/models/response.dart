class Response {
  final int id;
  final int feedbackId;
  final int adminId;
  final String responseText;
  final String createdAt;

  Response({
    required this.id,
    required this.feedbackId,
    required this.adminId,
    required this.responseText,
    required this.createdAt,
  });

  // Factory constructor to create Response instance from JSON
  factory Response.fromJson(Map<String, dynamic> json) {
    return Response(
      id: json['id'],
      feedbackId: json['feedback_id'],
      adminId: json['admin_id'],
      responseText: json['response_text'],
      createdAt: json['created_at'],
    );
  }

  // Convert Response instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'feedback_id': feedbackId,
      'admin_id': adminId,
      'response_text': responseText,
      'created_at': createdAt,
    };
  }
}