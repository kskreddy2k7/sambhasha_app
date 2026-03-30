import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String phone;
  final String name;
  final String nameLowerCase;
  final String profilePic;
  final String bio;
  final DateTime lastSeen;
  final bool isOnline;
  final String publicKey;

  UserModel({
    required this.uid,
    this.phone = '',
    required this.name,
    required this.nameLowerCase,
    this.profilePic = '',
    this.bio = '',
    required this.lastSeen,
    required this.isOnline,
    this.publicKey = '',
  });

  // Backward-compatible getters
  String get username => name;
  String get photoURL => profilePic;
  String get email => ""; 

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      phone: map['phone'] ?? '',
      name: map['name'] ?? '',
      nameLowerCase: map['nameLowerCase'] ?? (map['name'] ?? '').toString().toLowerCase(),
      profilePic: map['profilePic'] ?? '',
      bio: map['bio'] ?? '',
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOnline: map['isOnline'] ?? false,
      publicKey: map['publicKey'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phone': phone,
      'name': name,
      'nameLowerCase': nameLowerCase,
      'profilePic': profilePic,
      'bio': bio,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'isOnline': isOnline,
      'publicKey': publicKey,
    };
  }
}
