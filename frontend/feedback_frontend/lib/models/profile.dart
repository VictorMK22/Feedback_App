class Profile {
  final int id;
  final int userId;
  final String phoneNumber;
  final String notificationPreference;
  final String profilePicture;
  final String bio;

  Profile({
    required this.id,
    required this.userId,
    required this.phoneNumber,
    required this.notificationPreference,
    required this.profilePicture,
    required this.bio,
  });

  // Factory constructor to create Profile instance from JSON
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      userId: json['user_id'],
      phoneNumber: json['phone_number'] ?? '',
      notificationPreference: json['notification_preference'] ?? 'Both',
      profilePicture: json['profile_picture'] ?? '',
      bio: json['bio'] ?? '',
    );
  }

  // Convert Profile instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'phone_number': phoneNumber,
      'notification_preference': notificationPreference,
      'profile_picture': profilePicture,
      'bio': bio,
    };
  }
}