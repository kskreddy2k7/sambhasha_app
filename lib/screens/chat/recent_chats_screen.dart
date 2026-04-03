import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sambhasha_app/models/message_model.dart';
import 'package:sambhasha_app/models/user_model.dart';
import 'package:sambhasha_app/providers/auth_provider.dart' as app_auth;
import 'package:sambhasha_app/providers/chat_provider.dart';
import 'package:sambhasha_app/screens/chat/chat_screen.dart';
import 'package:sambhasha_app/widgets/story_bar.dart';
import 'package:sambhasha_app/providers/navigation_provider.dart';
import 'package:sambhasha_app/widgets/shimmer_skeletons.dart';
import 'package:sambhasha_app/models/group_model.dart';
import 'package:sambhasha_app/screens/chat/create_group_screen.dart';
import 'package:sambhasha_app/screens/chat/group_chat_screen.dart';
import 'package:sambhasha_app/services/database_service.dart';

class RecentChatsScreen extends StatefulWidget {
  const RecentChatsScreen({super.key});

  @override
  State<RecentChatsScreen> createState() => _RecentChatsScreenState();
}

class _RecentChatsScreenState extends State<RecentChatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription? _deliveredSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _setupDeliveredPulse();
  }

  void _setupDeliveredPulse() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final db = DatabaseService();
    _deliveredSub = chatProvider.getRecentChats().listen((chats) async {
       for (var doc in chats) {
          final data = doc.data() as Map<String, dynamic>;
          final lastMsg = data['lastMessage'];
          if (lastMsg != null) {
            final msgId = lastMsg['messageId'];
            final senderId = lastMsg['senderId'];
            if (senderId != db.currentUid) {
              await db.markAsDelivered(doc.id, msgId);
            }
          }
       }
    });

  }

  @override
  void dispose() {
    _tabController.dispose();
    _deliveredSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final userProvider = Provider.of<app_auth.AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: Colors.white.withValues(alpha: 0.04),
              title: const Text(
                "Sambhasha", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 1.2)
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: GestureDetector(
                    onTap: () => userProvider.logout(),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: userProvider.userModel?.profilePic != null && userProvider.userModel!.profilePic.isNotEmpty
                          ? NetworkImage(userProvider.userModel!.profilePic) 
                          : null,
                      child: userProvider.userModel?.profilePic == null || userProvider.userModel!.profilePic.isEmpty
                          ? const Icon(Icons.person, size: 20) 
                          : null,
                    ),
                  ),
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.blueAccent,
                labelColor: Colors.blueAccent,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: "CHATS"),
                  Tab(text: "GROUPS"),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () {
          if (_tabController.index == 0) {
            Provider.of<NavigationProvider>(context, listen: false).setIndex(1); 
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
          }
        },
        child: Icon(_tabController.index == 0 ? Icons.chat : Icons.group_add, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: INDIVIDUAL CHATS
          ListView(
            padding: const EdgeInsets.only(top: 120),
            children: [
              const StoryBar(),
              Divider(color: Colors.grey[900], height: 1),
              StreamBuilder<List<DocumentSnapshot>>(
                stream: chatProvider.getRecentChats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const ChatListSkeleton();
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState(context, "No conversations yet", Icons.chat_bubble_outline);
                  }
                  final chats = snapshot.data!;
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chats.length,
                    separatorBuilder: (context, index) => Divider(color: Colors.grey[900], height: 1, indent: 80),
                    itemBuilder: (context, index) {
                      final chatData = chats[index].data() as Map<String, dynamic>;
                      return ChatListItem(chatData: chatData);
                    },
                  );
                },
              ),
            ],
          ),

          // TAB 2: GROUPS
          Padding(
            padding: const EdgeInsets.only(top: 120),
            child: StreamBuilder<List<GroupModel>>(
              stream: chatProvider.getUserGroups(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ChatListSkeleton();
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(context, "No groups yet", Icons.groups_outlined);
                }
                final groups = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: groups.length,
                  separatorBuilder: (context, index) => Divider(color: Colors.grey[900], height: 1, indent: 80),
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => GroupChatScreen(group: group))
                        );
                      },
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundImage: group.groupPic.isNotEmpty ? NetworkImage(group.groupPic) : null,
                        child: group.groupPic.isEmpty ? const Icon(Icons.group) : null,
                      ),
                      title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        group.lastMessage != null ? group.lastMessage!.text : "New group created",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: Text(
                        group.lastMessage != null 
                          ? DateFormat('hh:mm a').format(group.lastMessage!.timestamp)
                          : DateFormat('hh:mm a').format(group.createdAt),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.grey)),
          if (title.contains("conversations"))
            TextButton(
              onPressed: () => Provider.of<NavigationProvider>(context, listen: false).setIndex(1),
              child: const Text("Find someone to chat with"),
            ),
        ],
      ),
    );
  }
}

class ChatListItem extends StatelessWidget {
  final Map<String, dynamic> chatData;

  const ChatListItem({super.key, required this.chatData});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final List<String> participants = List<String>.from(chatData['participants']);
    final String otherUid = participants.firstWhere((id) => id != currentUid, orElse: () => participants[0]);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(otherUid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) return const SizedBox();
        
        final user = UserModel.fromMap(userSnapshot.data!.data() as Map<String, dynamic>);
        final lastMsg = chatData['lastMessage'] != null 
            ? MessageModel.fromMap(chatData['lastMessage']) 
            : null;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          onTap: () => Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => ChatScreen(otherUser: user))
          ),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: user.profilePic.isNotEmpty 
                  ? NetworkImage(user.profilePic) 
                  : null,
                child: user.profilePic.isEmpty ? const Icon(Icons.person) : null,
              ),
              if (user.isOnline)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
                    child: const CircleAvatar(radius: 5, backgroundColor: Colors.greenAccent),
                  ),
                ),
            ],
          ),
          title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                if (lastMsg != null && lastMsg.senderId == currentUid) ...[
                  Icon(
                    Icons.done_all, 
                    size: 16, 
                    color: lastMsg.read ? Colors.blueAccent : Colors.grey
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    lastMsg != null 
                        ? (lastMsg.type == MessageType.image ? "📷 Photo" : lastMsg.text)
                        : "Start chatting",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: lastMsg != null && !lastMsg.read && lastMsg.senderId != currentUid 
                        ? Colors.white 
                        : Colors.grey,
                      fontWeight: lastMsg != null && !lastMsg.read && lastMsg.senderId != currentUid 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (lastMsg != null)
                Text(
                  DateFormat('hh:mm a').format(lastMsg.timestamp),
                  style: TextStyle(
                    fontSize: 12, 
                    color: !lastMsg.read && lastMsg.senderId != currentUid 
                      ? Colors.blueAccent 
                      : Colors.grey
                  ),
                ),
              const SizedBox(height: 4),
              if (lastMsg != null && !lastMsg.read && lastMsg.senderId != currentUid)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                  child: const Text("", style: TextStyle(fontSize: 0)), // Small dot
                ),
            ],
          ),
        );
      },
    );
  }
}

