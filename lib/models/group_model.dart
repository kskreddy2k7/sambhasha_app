import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sambhasha_app/models/message_model.dart';

class GroupModel {
  final String groupId;
  final String name;
  final String description;
  final String groupPic;
  final List<String> members;
  final List<String> admins;
  final MessageModel? lastMessage;
  final DateTime createdAt;

  GroupModel({
    required this.groupId,
    required this.name,
    this.description = '',
    this.groupPic = '',
    required this.members,
    required this.admins,
    this.lastMessage,
    required this.createdAt,
  });

  factory GroupModel.fromMap(Map<String, dynamic> map, String id) {
    return GroupModel(
      groupId: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      groupPic: map['groupPic'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      admins: List<String>.from(map['admins'] ?? []),
      lastMessage: map['lastMessage'] != null 
          ? MessageModel.fromMap(map['lastMessage']) 
          : null,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'groupPic': groupPic,
      'members': members,
      'admins': admins,
      'lastMessage': lastMessage?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
