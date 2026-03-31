import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:sambhasha_app/models/message_model.dart';
import 'package:sambhasha_app/models/user_model.dart';
import 'package:sambhasha_app/services/encryption_service.dart';
import 'package:uuid/uuid.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EncryptionService _encryption = EncryptionService();

  String get currentUid => _auth.currentUser!.uid;

  // --- USER CORE ---
  Stream<UserModel?> getUserData(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    });
  }

  Future<void> updateProfile({String? name, String? profilePic}) async {
    Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (profilePic != null) data['profilePic'] = profilePic;
    if (data.isNotEmpty) {
      await _firestore.collection('users').doc(currentUid).update(data);
    }
  }

  String getChatId(String otherUid) {
    return currentUid.hashCode <= otherUid.hashCode
        ? '${currentUid}_$otherUid'
        : '${otherUid}_$currentUid';
  }

  // --- E2EE KEY EXCHANGE ---
  Future<String> _getOrCreateSessionKey(String chatId, String otherUid) async {
    var chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (chatDoc.exists && chatDoc.data()?['keys'] != null) {
      String? myEncryptedKey = chatDoc.data()!['keys'][currentUid];
      if (myEncryptedKey != null) {
        return await _encryption.decryptRSA(myEncryptedKey);
      }
    }
    String newKey = _encryption.generateAESKey();
    var otherUserDoc = await _firestore.collection('users').doc(otherUid).get();
    String? otherPublicKey = otherUserDoc.data()?['publicKey'];
    var myUserDoc = await _firestore.collection('users').doc(currentUid).get();
    String? myPublicKey = myUserDoc.data()?['publicKey'];
    if (otherPublicKey == null || myPublicKey == null) return "";
    String encryptedForMe = _encryption.encryptRSA(newKey, myPublicKey);
    String encryptedForThem = _encryption.encryptRSA(newKey, otherPublicKey);
    await _firestore.collection('chats').doc(chatId).set({
      'keys': {
        currentUid: encryptedForMe,
        otherUid: encryptedForThem,
      }
    }, SetOptions(merge: true));
    return newKey;
  }

  // --- MESSAGING (E2EE + EXPIRY) ---
  Future<void> sendMessage({
    required String receiverId,
    required String text,
    required MessageType type,
    int? expiryDuration,
    String? replyToId,
  }) async {
    final String chatId = getChatId(receiverId);
    final String messageId = _firestore.collection('chats').doc(chatId).collection('messages').doc().id;
    String sessionKey = await _getOrCreateSessionKey(chatId, receiverId);
    String encryptedText = (type == MessageType.text && sessionKey.isNotEmpty) 
        ? _encryption.encryptAES(text, sessionKey) 
        : text;

    final message = MessageModel(
      messageId: messageId,
      senderId: currentUid,
      text: encryptedText,
      type: type,
      timestamp: DateTime.now(),
      read: false,
      expiryDuration: expiryDuration,
      replyToId: replyToId,
    );

    await _firestore.collection('chats').doc(chatId).collection('messages').doc(messageId).set(message.toMap());
    await _firestore.collection('chats').doc(chatId).set({
      'lastMessage': message.toMap(),
      'participants': [currentUid, receiverId],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final now = DateTime.now();
          String sessionKey = "";
          var chatDoc = await _firestore.collection('chats').doc(chatId).get();
          if (chatDoc.exists && chatDoc.data()?['keys'] != null) {
            String? myEncryptedKey = chatDoc.data()!['keys'][currentUid];
            if (myEncryptedKey != null) sessionKey = await _encryption.decryptRSA(myEncryptedKey);
          }
          List<MessageModel> messages = [];
          for (var doc in snapshot.docs) {
            var msg = MessageModel.fromMap(doc.data());
            if (msg.expiryDuration != null) {
              final expiryTime = msg.timestamp.add(Duration(seconds: msg.expiryDuration!));
              if (now.isAfter(expiryTime)) continue;
            }
            if (!msg.isDeleted) {
              String decryptedText = (msg.type == MessageType.text && sessionKey.isNotEmpty)
                  ? _encryption.decryptAES(msg.text, sessionKey)
                  : msg.text;
              messages.add(MessageModel(
                messageId: msg.messageId, senderId: msg.senderId,
                text: decryptedText, type: msg.type,
                timestamp: msg.timestamp, read: msg.read,
                status: msg.status, isDeleted: msg.isDeleted,
                expiryDuration: msg.expiryDuration, replyToId: msg.replyToId,
              ));
            }
          }
          return messages;
        });
  }

  // --- SOCIAL & DISCOVERY ---
  Future<void> followUser(String targetUid) async {
    await _firestore.collection('users').doc(currentUid).collection('following').doc(targetUid).set({'timestamp': FieldValue.serverTimestamp()});
    await _firestore.collection('users').doc(targetUid).collection('followers').doc(currentUid).set({'timestamp': FieldValue.serverTimestamp()});
  }

  Future<void> unfollowUser(String targetUid) async {
    await _firestore.collection('users').doc(currentUid).collection('following').doc(targetUid).delete();
    await _firestore.collection('users').doc(targetUid).collection('followers').doc(currentUid).delete();
  }

  Stream<bool> isFollowing(String targetUid) => _firestore.collection('users').doc(currentUid).collection('following').doc(targetUid).snapshots().map((doc) => doc.exists);
  Stream<int> getFollowersCount(String uid) => _firestore.collection('users').doc(uid).collection('followers').snapshots().map((s) => s.docs.length);
  Stream<int> getFollowingCount(String uid) => _firestore.collection('users').doc(uid).collection('following').snapshots().map((s) => s.docs.length);

  Future<List<UserModel>> getSuggestedUsers() async {
    final followingSnap = await _firestore.collection('users').doc(currentUid).collection('following').get();
    final blockedSnap = await _firestore.collection('users').doc(currentUid).collection('blocked').get();
    final excludeIds = followingSnap.docs.map((d) => d.id).toSet()..addAll(blockedSnap.docs.map((d) => d.id))..add(currentUid);
    final usersSnap = await _firestore.collection('users').limit(20).get();
    return usersSnap.docs.map((doc) => UserModel.fromMap(doc.data())).where((user) => !excludeIds.contains(user.uid)).toList();
  }

  // --- SAFETY ---
  Future<void> blockUser(String targetUid) async {
    await _firestore.collection('users').doc(currentUid).collection('blocked').doc(targetUid).set({'timestamp': FieldValue.serverTimestamp()});
    await unfollowUser(targetUid);
  }

  Future<void> unblockUser(String targetUid) async {
    await _firestore.collection('users').doc(currentUid).collection('blocked').doc(targetUid).delete();
  }

  Stream<bool> isBlocked(String targetUid) => _firestore.collection('users').doc(currentUid).collection('blocked').doc(targetUid).snapshots().map((doc) => doc.exists);

  // --- UTILS & STATUS ---
  Future<void> setUserOnlineStatus(bool isOnline) async {
    if (_auth.currentUser == null) return;
    await _firestore.collection('users').doc(currentUid).update({'isOnline': isOnline, 'lastSeen': FieldValue.serverTimestamp()});
  }

  Future<void> setTypingStatus(String chatId, bool isTyping) async {
    await _firestore.collection('chats').doc(chatId).update({
      'typing.$currentUid': isTyping,
    });
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final snapshot = await _firestore
        .collection('users')
        .where('nameLowerCase', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('nameLowerCase', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
        .get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  Future<void> markAsDelivered(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'status': MessageStatus.delivered.name});
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'isDeleted': true, 'text': 'This message was deleted'});
  }

  Future<void> updateFCMToken(String token) async {
    await _firestore.collection('users').doc(currentUid).update({'fcmToken': token});
  }


  Stream<DocumentSnapshot> getChatStream(String chatId) => _firestore.collection('chats').doc(chatId).snapshots();
  
  Stream<List<DocumentSnapshot>> getRecentChats() {
    return _firestore.collection('chats').where('participants', arrayContains: currentUid).orderBy('updatedAt', descending: true).snapshots().map((snapshot) => snapshot.docs);
  }

  Future<String> uploadImage(Uint8List bytes, String fileName) async {
    Reference ref = _storage.ref().child('chat_images/${const Uuid().v4()}_$fileName');
    UploadTask uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return await (await uploadTask).ref.getDownloadURL();
  }

  Future<String> uploadFile(Uint8List bytes, String fileName) async {
    Reference ref = _storage.ref().child('chat_files/${const Uuid().v4()}_$fileName');
    UploadTask uploadTask = ref.putData(bytes);
    return await (await uploadTask).ref.getDownloadURL();
  }


  Future<void> markAsRead(String chatId) async {
    var snapshot = await _firestore.collection('chats').doc(chatId).collection('messages').where('senderId', isNotEqualTo: currentUid).where('read', isEqualTo: false).get();
    WriteBatch batch = _firestore.batch();
    for (var doc in snapshot.docs) batch.update(doc.reference, {'read': true, 'status': MessageStatus.seen.name});
    await batch.commit();
  }
}
