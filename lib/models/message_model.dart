import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, file }

enum MessageStatus { sending, delivered, seen }

class MessageModel {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String message;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final String? mediaUrl;
  final String? fileName;
  final String? fileSize;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.status,
    this.mediaUrl,
    this.fileName,
    this.fileSize,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      type: MessageType.values.byName(map['type'] ?? 'text'),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      status: MessageStatus.values.byName(map['status'] ?? 'delivered'),
      mediaUrl: map['mediaUrl'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.name,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'fileSize': fileSize,
    };
  }
}
