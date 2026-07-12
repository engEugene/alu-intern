import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserRole { student, startup, admin }

final class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? username;
  final String? photoUrl;
  final String? startupId;
  final UserRole role;
  final List<String> skills;
  final bool onboardingComplete;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.username,
    this.photoUrl,
    this.startupId,
    this.role = UserRole.student,
    this.skills = const [],
    this.onboardingComplete = false,
    this.createdAt,
  });

  factory AppUser.fromFirebase(User? user) {
    if (user == null) {
      throw ArgumentError.notNull('user');
    }
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] as String?,
      displayName: map['fullname'] as String?,
      username: map['username'] as String?,
      photoUrl: map['avatar'] as String?,
      startupId: map['startupId'] as String?,
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.student,
      ),
      skills: List<String>.from(map['skills'] as List? ?? []),
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullname': displayName,
      'username': username,
      'avatar': photoUrl,
      'startupId': startupId,
      'role': role.name,
      'skills': skills,
      'onboardingComplete': onboardingComplete,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
