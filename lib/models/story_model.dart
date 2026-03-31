import 'package:cloud_firestore/cloud_firestore.dart';

enum StoryType { image, video }

class StoryModel {
  final String storyId;
  final String uid;
  final String name;
  final String profilePic;
  final String contentUrl;
  final StoryType type;
  final DateTime createdAt;
  final List<String> viewers;

  StoryModel({
    required this.storyId,
    required this.uid,
    required this.name,
    required this.profilePic,
    required this.contentUrl,
    required this.type,
    required this.createdAt,
    this.viewers = const [],
  });

  factory StoryModel.fromMap(Map<String, dynamic> map, String id) {
    return StoryModel(
      storyId: id,
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      profilePic: map['profilePic'] ?? '',
      contentUrl: map['contentUrl'] ?? '',
      type: map['type'] == 'video' ? StoryType.video : StoryType.image,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      viewers: List<String>.from(map['viewers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'profilePic': profilePic,
      'contentUrl': contentUrl,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'viewers': viewers,
    };
  }
}

