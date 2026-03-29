import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String email;
  final String? photoURL;
  final String? bio;
  final DateTime? createdAt;
  final bool isOnline;
  final DateTime lastSeen;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.photoURL,
    this.bio,
    this.createdAt,
    this.isOnline = false,
    required this.lastSeen,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? map['name'] ?? 'User',
      email: map['email'] ?? '',
      photoURL: map['photoURL'] ?? map['profilePhoto'],
      bio: map['bio'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      isOnline: map['isOnline'] ?? false,
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'photoURL': photoURL,
      'bio': bio,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
    };
  }
}
