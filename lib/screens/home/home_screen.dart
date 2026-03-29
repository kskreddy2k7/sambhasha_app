import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sambhasha_app/models/message_model.dart';
import 'package:sambhasha_app/models/user_model.dart';
import 'package:sambhasha_app/screens/chat/chat_screen.dart';
import 'package:sambhasha_app/services/database_service.dart';
import 'package:sambhasha_app/widgets/skeleton_loading.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sambhasha", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          IconButton(icon: const Icon(Icons.camera_alt_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ChatSkeleton();
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final chatDocs = snapshot.data!.docs;
          chatDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = (aData['lastMessage']?['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
            final bTime = (bData['lastMessage']?['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatData = chatDocs[index].data() as Map<String, dynamic>;
              final lastMsgMap = chatData['lastMessage'] as Map<String, dynamic>?;
              if (lastMsgMap == null) return const SizedBox();

              final lastMsg = MessageModel.fromMap(lastMsgMap);
              final otherUserId = (chatData['users'] as List).firstWhere((id) => id != currentUserId);

              return StreamBuilder<UserModel?>(
                stream: db.getUserData(otherUserId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || userSnapshot.data == null) return const SizedBox();
                  final user = userSnapshot.data!;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blueAccent.withOpacity(0.1),
                          backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                          child: user.photoURL == null ? Text(user.username[0], style: const TextStyle(fontSize: 20)) : null,
                        ),
                        if (user.isOnline)
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 2.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    subtitle: Row(
                      children: [
                        if (lastMsg.senderId == currentUserId) ...[
                          Icon(
                            lastMsg.status == MessageStatus.seen ? Icons.done_all : Icons.done,
                            size: 16,
                            color: lastMsg.status == MessageStatus.seen ? Colors.blueAccent : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            lastMsg.type == MessageType.text ? lastMsg.message : '📎 Media',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: lastMsg.status != MessageStatus.seen && lastMsg.receiverId == currentUserId ? Colors.white : Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTimestamp(lastMsg.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: lastMsg.status != MessageStatus.seen && lastMsg.receiverId == currentUserId ? Colors.blueAccent : Colors.grey
                          ),
                        ),
                        if (lastMsg.status != MessageStatus.seen && lastMsg.receiverId == currentUserId)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                            child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChatScreen(receiver: user)),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // You might want to navigate to SearchScreen or Contacts here
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (msgDate == today) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (msgDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('dd/MM/yy').format(timestamp);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 100, color: Colors.grey[800]),
          const SizedBox(height: 24),
          const Text("No conversations yet", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Search for people to start chatting", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
