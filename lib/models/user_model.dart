import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? profilePhoto;
  final String? bio;
  final bool isOnline;
  final DateTime lastSeen;
  final String? pushToken;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.profilePhoto,
    this.bio,
    this.isOnline = false,
    required this.lastSeen,
    this.pushToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profilePhoto: map['profilePhoto'],
      bio: map['bio'],
      isOnline: map['isOnline'] ?? false,
      lastSeen: (map['lastSeen'] as Timestamp).toDate(),
      pushToken: map['pushToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profilePhoto': profilePhoto,
      'bio': bio,
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'pushToken': pushToken,
    };
  }
}
