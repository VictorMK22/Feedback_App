class Feedback {
  final int id;
  final int userId;
  final String content;
  final String category;
  final String createdAt;

  Feedback({
    required this.id,
    required this.userId,
    required this.content,
    required this.category,
    required this.createdAt,
  });

  // Factory constructor to create Feedback instance from JSON
  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['id'],
      userId: json['user_id'],
      content: json['content'],
      category: json['category'],
      createdAt: json['created_at'],
    );
  }

  // Convert Feedback instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'category': category,
      'created_at': createdAt,
    };
  }
}