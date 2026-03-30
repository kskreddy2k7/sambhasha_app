import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sambhasha_app/models/message_model.dart';

class ChatModel {
  final String chatId;
  final List<String> participants;
  final MessageModel? lastMessage;
  final Map<String, bool> typing;

  ChatModel({
    required this.chatId,
    required this.participants,
    this.lastMessage,
    required this.typing,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      chatId: map['chatId'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] != null 
          ? MessageModel.fromMap(map['lastMessage']) 
          : null,
      typing: Map<String, bool>.from(map['typing'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'participants': participants,
      'lastMessage': lastMessage?.toMap(),
      'typing': typing,
    };
  }
}
