import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sambhasha_app/models/group_model.dart';
import 'package:sambhasha_app/models/message_model.dart';
import 'package:uuid/uuid.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUid => _auth.currentUser!.uid;

  // Create Group
  Future<void> createGroup({
    required String name,
    required String description,
    required String groupPic,
    required List<String> members,
  }) async {
    String groupId = const Uuid().v4();
    List<String> allMembers = [currentUid, ...members];
    
    GroupModel group = GroupModel(
      groupId: groupId,
      name: name,
      description: description,
      groupPic: groupPic,
      members: allMembers,
      admins: [currentUid], // Creator is the first admin
      createdAt: DateTime.now(),
    );

    await _firestore.collection('groups').doc(groupId).set(group.toMap());
  }

  // Get User Groups
  Stream<List<GroupModel>> getUserGroups() {
    return _firestore
        .collection('groups')
        .where('members', arrayContains: currentUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Send Group Message
  Future<void> sendGroupMessage({
    required String groupId,
    required String text,
    required MessageType type,
  }) async {
    String messageId = const Uuid().v4();
    
    MessageModel message = MessageModel(
      messageId: messageId,
      senderId: currentUid,
      text: text,
      type: type,
      timestamp: DateTime.now(),
      read: false,
    );

    // 1. Add message to group's sub-collection
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .doc(messageId)
        .set(message.toMap());

    // 2. Update group lastMessage
    await _firestore.collection('groups').doc(groupId).update({
      'lastMessage': message.toMap(),
    });
  }

  // Stream Group Messages
  Stream<List<MessageModel>> getGroupMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }

  // Update Group Details
  Future<void> updateGroupDetails({
    required String groupId,
    String? name,
    String? description,
    String? groupPic,
  }) async {
    Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (groupPic != null) data['groupPic'] = groupPic;

    if (data.isNotEmpty) {
      await _firestore.collection('groups').doc(groupId).update(data);
    }
  }

  // Add Member
  Future<void> addMember(String groupId, String memberUid) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([memberUid]),
    });
  }

  // Remove Member
  Future<void> removeMember(String groupId, String memberUid) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([memberUid]),
      'admins': FieldValue.arrayRemove([memberUid]), // Also remove from admins if they were one
    });
  }

  // Promote to Admin
  Future<void> promoteToAdmin(String groupId, String memberUid) async {
    await _firestore.collection('groups').doc(groupId).update({
      'admins': FieldValue.arrayUnion([memberUid]),
    });
  }

  // Demote from Admin
  Future<void> demoteFromAdmin(String groupId, String memberUid) async {
    await _firestore.collection('groups').doc(groupId).update({
      'admins': FieldValue.arrayRemove([memberUid]),
    });
  }
}
