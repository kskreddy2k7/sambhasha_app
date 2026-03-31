import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sambhasha_app/models/group_model.dart';
import 'package:sambhasha_app/models/message_model.dart';
import 'package:sambhasha_app/services/database_service.dart';
import 'package:sambhasha_app/services/group_service.dart';

class ChatProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final GroupService _groupService = GroupService();
  
  bool _isUploading = false;
  bool get isUploading => _isUploading;

  // Send Individual Message
  Future<void> sendMessage({
    required String receiverId,
    required String text,
    required MessageType type,
    int? expiryDuration,
    String? replyToId,
  }) async {
    await _db.sendMessage(
      receiverId: receiverId,
      text: text,
      type: type,
      expiryDuration: expiryDuration,
      replyToId: replyToId,
    );
  }

  // Send Group Message
  Future<void> sendGroupMessage({
    required String groupId,
    required String text,
    required MessageType type,
  }) async {
    await _groupService.sendGroupMessage(groupId: groupId, text: text, type: type);
  }

  // Send Image (Individual)
  Future<void> sendImage({
    required String receiverId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    _isUploading = true;
    notifyListeners();
    
    try {
      String imageUrl = await _db.uploadImage(bytes, fileName);
      await _db.sendMessage(receiverId: receiverId, text: imageUrl, type: MessageType.image);
    } catch (e) {
      debugPrint("Error uploading image: $e");
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  // Send Image (Group)
  Future<void> sendGroupImage({
    required String groupId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    _isUploading = true;
    notifyListeners();
    
    try {
      String imageUrl = await _db.uploadImage(bytes, fileName);
      await _groupService.sendGroupMessage(groupId: groupId, text: imageUrl, type: MessageType.image);
    } catch (e) {
      debugPrint("Error uploading group image: $e");
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  // Send File (Individual)
  Future<void> sendFile({
    required String receiverId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    _isUploading = true;
    notifyListeners();
    
    try {
      String fileUrl = await _db.uploadFile(bytes, fileName);
      await _db.sendMessage(receiverId: receiverId, text: fileUrl, type: MessageType.file);
    } catch (e) {
      debugPrint("Error uploading file: $e");
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  // Send File (Group)
  Future<void> sendGroupFile({
    required String groupId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    _isUploading = true;
    notifyListeners();
    
    try {
      String fileUrl = await _db.uploadFile(bytes, fileName);
      await _groupService.sendGroupMessage(groupId: groupId, text: fileUrl, type: MessageType.file);
    } catch (e) {
      debugPrint("Error uploading group file: $e");
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  // Send Video
  Future<void> sendVideo({
    required String receiverId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    _isUploading = true;
    notifyListeners();
    try {
      String videoUrl = await _db.uploadFile(bytes, fileName);
      await _db.sendMessage(receiverId: receiverId, text: videoUrl, type: MessageType.video);
    } catch (e) {
      debugPrint("Error sending video message: $e");
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  // Send Voice Note
  Future<void> sendVoiceNote({
    required String receiverId,
    required String filePath,
  }) async {
    _isUploading = true;
    notifyListeners();
    try {
      String audioUrl = await _db.uploadAudio(filePath, "voice_msg.m4a");
      await _db.sendMessage(receiverId: receiverId, text: audioUrl, type: MessageType.voice); 
    } catch (e) {
      debugPrint("Error sending voice note: $e");
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  // Message Management
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _db.deleteMessage(chatId, messageId);
  }

  Future<void> editMessage(String chatId, String messageId, String newText) async {
    await _db.editMessage(chatId, messageId, newText);
  }

  // Mark all messages as read
  Future<void> markAsRead(String chatId) async {
    await _db.markAsRead(chatId);
  }

  // Individual Streams
  Stream<List<MessageModel>> getMessages(String chatId, {int limit = 50}) => _db.getMessages(chatId, limit: limit);
  Stream<DocumentSnapshot> getChatStream(String chatId) => _db.getChatStream(chatId);
  Stream<List<DocumentSnapshot>> getRecentChats() => _db.getRecentChats();

  // Group Streams
  Stream<List<GroupModel>> getUserGroups() => _groupService.getUserGroups();
  Stream<List<MessageModel>> getGroupMessages(String groupId) => _groupService.getGroupMessages(groupId);
}

