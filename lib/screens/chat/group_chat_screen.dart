import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sambhasha_app/models/group_model.dart';
import 'package:sambhasha_app/models/message_model.dart';
import 'package:sambhasha_app/providers/chat_provider.dart';
import 'package:sambhasha_app/screens/chat/group_details_screen.dart';
import 'package:sambhasha_app/services/database_service.dart';
import 'package:sambhasha_app/widgets/chat_bubble.dart';

class GroupChatScreen extends StatefulWidget {
  final GroupModel group;

  const GroupChatScreen({super.key, required this.group});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseService _db = DatabaseService();

  void _sendGroupMessage() {
    if (_msgController.text.trim().isEmpty) return;
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.sendGroupMessage(
      groupId: widget.group.groupId,
      text: _msgController.text.trim(),
      type: MessageType.text,
    );
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.04),
              elevation: 0,
              title: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetailsScreen(group: widget.group))),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: widget.group.groupPic.isNotEmpty 
                        ? CachedNetworkImageProvider(widget.group.groupPic) 
                        : null,
                      child: widget.group.groupPic.isEmpty ? const Icon(Icons.group) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.group.name, style: const TextStyle(fontSize: 16)),
                          Text(
                            "${widget.group.members.length} members",
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage('https://user-images.githubusercontent.com/15075759/28719144-86dc0f70-73b1-11e7-911d-60d70fcded21.png'),
            opacity: 0.05,
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // Message List
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: chatProvider.getGroupMessages(widget.group.groupId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No messages yet. Say hi!", style: TextStyle(color: Colors.white)));
                  }
                  final messages = snapshot.data!;
                  return ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 100, bottom: 20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      // In groups, we show the sender's name for clarity
                      return ChatBubble(
                        message: message,
                        isMe: message.senderId == _db.currentUid,
                      );
                    },
                  );
                },
              ),
            ),
            // Input Row
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                   IconButton(
                    icon: const Icon(Icons.add, color: Colors.blueAccent),
                    onPressed: () {
                      // Generic File Pick logic will be added in DatabaseService
                    },
                  ),
                   Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: TextField(
                        controller: _msgController,
                        style: const TextStyle(color: Colors.white),
                        onSubmitted: (_) => _sendGroupMessage(),
                        decoration: const InputDecoration(
                          hintText: "Message",
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendGroupMessage(),
                    child: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
