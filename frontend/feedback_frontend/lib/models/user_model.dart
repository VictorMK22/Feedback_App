// user_model.dart
import 'package:flutter/foundation.dart';

enum UserRole {
  patient,
  admin;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.patient;
    }
  }

  bool get isAdmin => this == UserRole.admin;

  @override
  String toString() => name;
}

enum NotificationPreference {
  sms,
  email,
  both;

  static NotificationPreference fromString(String pref) {
    switch (pref.toLowerCase()) {
      case 'sms':
        return NotificationPreference.sms;
      case 'email':
        return NotificationPreference.email;
      default:
        return NotificationPreference.both;
    }
  }

  @override
  String toString() => name;
}

@immutable
class UserProfile {
  final String? phoneNumber;
  final String? profilePicture;
  final String? bio;
  final DateTime? dateOfBirth;
  final NotificationPreference notificationPreference;

  const UserProfile({
    this.phoneNumber,
    this.profilePicture,
    this.bio,
    this.dateOfBirth,
    this.notificationPreference = NotificationPreference.both,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      phoneNumber: json['phone_number']?.toString(),
      profilePicture: json['profile_picture']?.toString(),
      bio: json['bio']?.toString(),
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'].toString())
          : null,
      notificationPreference: NotificationPreference.fromString(
          json['notification_preference']?.toString() ?? 'both'),
    );
  }

  Map<String, dynamic> toJson() => {
        'phone_number': phoneNumber,
        'profile_picture': profilePicture,
        'bio': bio,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'notification_preference': notificationPreference.toString(),
      };

  UserProfile copyWith({
    String? phoneNumber,
    String? profilePicture,
    String? bio,
    DateTime? dateOfBirth,
    NotificationPreference? notificationPreference,
  }) {
    return UserProfile(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      notificationPreference:
          notificationPreference ?? this.notificationPreference,
    );
  }
}

@immutable
class AppUser {
  final String id;
  final String email;
  final String username;
  final UserRole role;
  final String? accessToken;
  final String? refreshToken;
  final UserProfile profile;

  const AppUser({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    this.accessToken,
    this.refreshToken,
    required this.profile,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: UserRole.fromString(json['role']?.toString() ?? 'patient'),
      accessToken: json['access']?.toString(),
      refreshToken: json['refresh']?.toString(),
      profile: UserProfile.fromJson(json['profile'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'role': role.toString(),
        'access': accessToken,
        'refresh': refreshToken,
        'profile': profile.toJson(),
      };

  AppUser copyWith({
    String? id,
    String? email,
    String? username,
    UserRole? role,
    String? accessToken,
    String? refreshToken,
    UserProfile? profile,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      profile: profile ?? this.profile,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          username == other.username &&
          role == other.role &&
          accessToken == other.accessToken &&
          refreshToken == other.refreshToken &&
          profile == other.profile;

  @override
  int get hashCode =>
      id.hashCode ^
      email.hashCode ^
      username.hashCode ^
      role.hashCode ^
      accessToken.hashCode ^
      refreshToken.hashCode ^
      profile.hashCode;
}
