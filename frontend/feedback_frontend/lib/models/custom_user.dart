class CustomUser {
  final int id;
  final String username;
  final String email;
  final String role;

  CustomUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
  });

  // Factory constructor to create CustomUser instance from JSON
  factory CustomUser.fromJson(Map<String, dynamic> json) {
    return CustomUser(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
    );
  }

  // Convert CustomUser instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
    };
  }
}