import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:sambhasha_app/models/message_model.dart';
import 'package:sambhasha_app/models/user_model.dart';
import 'package:uuid/uuid.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<UserModel?> getUserData(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    });
  }

  Future<void> updateProfile({String? username, String? bio, String? photoURL}) async {
    Map<String, dynamic> data = {};
    if (username != null) data['username'] = username;
    if (bio != null) data['bio'] = bio;
    if (photoURL != null) data['photoURL'] = photoURL;

    if (data.isNotEmpty) {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update(data);
    }
  }

  Stream<List<UserModel>> searchUsers(String query) {
    String currentUid = _auth.currentUser!.uid;
    return _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .where((user) => user.uid != currentUid)
            .toList());
  }

  String getChatId(String otherUid) {
    String currentUid = _auth.currentUser!.uid;
    return currentUid.hashCode <= otherUid.hashCode
        ? '${currentUid}_$otherUid'
        : '${otherUid}_$currentUid';
  }

  Future<void> sendMessage(String receiverId, String content, MessageType type, {String? fileName, String? fileSize}) async {
    String senderId = _auth.currentUser!.uid;
    String chatId = getChatId(receiverId);
    String messageId = const Uuid().v4();
    
    MessageModel message = MessageModel(
      messageId: messageId,
      senderId: senderId,
      receiverId: receiverId,
      message: type == MessageType.text ? content : '',
      type: type,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      mediaUrl: type != MessageType.text ? content : null,
      fileName: fileName,
      fileSize: fileSize,
    );

    await _firestore
        .collection('messages')
        .doc(chatId)
        .collection('chat_messages')
        .doc(messageId)
        .set(message.toMap());

    await _firestore.collection('chats').doc(chatId).set({
      'chatId': chatId,
      'users': [senderId, receiverId],
      'lastMessage': message.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<MessageModel>> getMessages(String otherUid) {
    String chatId = getChatId(otherUid);
    return _firestore
        .collection('messages')
        .doc(chatId)
        .collection('chat_messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }

  UploadTask uploadMediaTask(File file, String path) {
    String fileName = const Uuid().v4();
    Reference ref = _storage.ref().child(path).child(fileName);
    return ref.putFile(file);
  }

  Future<String> uploadImage(File file) async {
    String fileName = 'chat_images/${const Uuid().v4()}';
    Reference ref = _storage.ref().child(fileName);
    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> setUserOnlineStatus(bool isOnline) async {
    if (_auth.currentUser == null) return;
    await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markMessageAsSeen(String otherUid, String messageId) async {
    String chatId = getChatId(otherUid);
    await _firestore
        .collection('messages')
        .doc(chatId)
        .collection('chat_messages')
        .doc(messageId)
        .update({'status': MessageStatus.seen.name});
  }

  Future<void> setTypingStatus(String otherUid, bool isTyping) async {
    String chatId = getChatId(otherUid);
    await _firestore.collection('chats').doc(chatId).set({
      'typing': {
        _auth.currentUser!.uid: isTyping,
      }
    }, SetOptions(merge: true));
  }

  Stream<bool> getTypingStatus(String otherUid) {
    String chatId = getChatId(otherUid);
    return _firestore.collection('chats').doc(chatId).snapshots().map((doc) {
      if (!doc.exists) return false;
      Map<String, dynamic>? data = doc.data();
      Map<String, dynamic>? typing = data?['typing'] as Map<String, dynamic>?;
      return typing?[otherUid] ?? false;
    });
  }

  Future<void> deleteMessage(String otherUid, String messageId) async {
    String chatId = getChatId(otherUid);
    await _firestore
        .collection('messages')
        .doc(chatId)
        .collection('chat_messages')
        .doc(messageId)
        .delete();
  }
}
