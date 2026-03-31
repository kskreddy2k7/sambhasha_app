import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, file, voice, video }

enum MessageStatus { sent, delivered, seen }

class MessageModel {
  final String messageId;
  final String senderId;
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final bool read;
  final MessageStatus status;
  final bool isDeleted;
  final bool isEdited;
  final String? replyToId;
  final int? expiryDuration;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.text,
    required this.type,
    required this.timestamp,
    required this.read,
    this.status = MessageStatus.sent,
    this.isDeleted = false,
    this.isEdited = false,
    this.replyToId,
    this.expiryDuration,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: map['read'] ?? false,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      isDeleted: map['isDeleted'] ?? false,
      isEdited: map['isEdited'] ?? false,
      replyToId: map['replyToId'],
      expiryDuration: map['expiryDuration'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'text': text,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
      'status': status.name,
      'isDeleted': isDeleted,
      'isEdited': isEdited,
      'replyToId': replyToId,
      'expiryDuration': expiryDuration,
    };
  }
}
