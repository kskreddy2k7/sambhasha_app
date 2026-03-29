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

  Stream<UserModel> getUserData(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => UserModel.fromMap(doc.data()!));
  }

  Future<void> updateUserData(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
  }

  Future<void> setUserOnlineStatus(bool isOnline) async {
    if (_auth.currentUser == null) return;
    await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<UserModel>> searchUsers(String query) {
    return _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  Future<String> uploadMedia(File file, String path) async {
    String fileName = const Uuid().v4();
    Reference ref = _storage.ref().child(path).child(fileName);
    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  UploadTask uploadMediaTask(File file, String path) {
    String fileName = const Uuid().v4();
    Reference ref = _storage.ref().child(path).child(fileName);
    return ref.putFile(file);
  }

  String getChatId(String user1, String user2) {
    return user1.hashCode <= user2.hashCode ? '${user1}_$user2' : '${user2}_$user1';
  }

  Future<void> sendMessage(MessageModel message) async {
    String chatId = getChatId(message.senderId, message.receiverId);
    
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.messageId)
        .set(message.toMap());

    await _firestore.collection('chats').doc(chatId).set({
      'lastMessage': message.toMap(),
      'users': [message.senderId, message.receiverId],
    }, SetOptions(merge: true));
  }

  Stream<List<MessageModel>> getMessages(String receiverId, {int limit = 20}) {
    String chatId = getChatId(_auth.currentUser!.uid, receiverId);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MessageModel.fromMap(doc.data())).toList());
  }

  Future<void> markMessageAsSeen(String receiverId, String messageId) async {
    String chatId = getChatId(_auth.currentUser!.uid, receiverId);
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'status': MessageStatus.seen.name});
  }

  Future<void> setTypingStatus(String receiverId, bool isTyping) async {
    String chatId = getChatId(_auth.currentUser!.uid, receiverId);
    await _firestore.collection('chats').doc(chatId).set({
      'typing': {
        _auth.currentUser!.uid: isTyping,
      }
    }, SetOptions(merge: true));
  }

  Stream<bool> getTypingStatus(String receiverId) {
    String chatId = getChatId(_auth.currentUser!.uid, receiverId);
    return _firestore.collection('chats').doc(chatId).snapshots().map((doc) {
      if (!doc.exists) return false;
      Map<String, dynamic>? data = doc.data();
      Map<String, dynamic>? typing = data?['typing'] as Map<String, dynamic>?;
      return typing?[receiverId] ?? false;
    });
  }

  Future<void> deleteMessage(String receiverId, String messageId) async {
    String chatId = getChatId(_auth.currentUser!.uid, receiverId);
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }
}
