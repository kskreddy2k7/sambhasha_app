import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sambhasha_app/models/message_model.dart';
import 'package:sambhasha_app/models/user_model.dart';
import 'package:sambhasha_app/screens/call/call_screen.dart';
import 'package:sambhasha_app/services/auth_service.dart';
import 'package:sambhasha_app/services/call_service.dart';
import 'package:sambhasha_app/services/database_service.dart';
import 'package:sambhasha_app/widgets/chat_bubble.dart';
import 'package:sambhasha_app/screens/chat/image_view_screen.dart';

class ChatScreen extends StatefulWidget {
  final UserModel receiver;

  const ChatScreen({super.key, required this.receiver});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String _currentUserId;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _currentUserId = Provider.of<AuthService>(context, listen: false).currentUser!.uid;
  }

  void _onTyping(String value) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    db.setTypingStatus(widget.receiver.uid, value.isNotEmpty);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      db.setTypingStatus(widget.receiver.uid, false);
    });
  }

  void _sendMessage({String? text, MessageType type = MessageType.text, String? mediaUrl}) async {
    if ((text == null || text.trim().isEmpty) && mediaUrl == null) return;

    final db = Provider.of<DatabaseService>(context, listen: false);
    await db.sendMessage(
      widget.receiver.uid,
      mediaUrl ?? text!.trim(),
      type,
    );

    _messageController.clear();
    db.setTypingStatus(widget.receiver.uid, false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      final db = Provider.of<DatabaseService>(context, listen: false);
      String url = await db.uploadImage(File(pickedFile.path));
      _sendMessage(type: MessageType.image, mediaUrl: url);
    }
  }

  Future<void> _startCall(CallType type) async {
    final callService = Provider.of<CallService>(context, listen: false);
    try {
      final callId = await callService.initiateCall(
        receiverId: widget.receiver.uid,
        type: type,
      );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallScreen(
              remoteUser: widget.receiver,
              callId: callId,
              callType: type,
              isCaller: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start call: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.receiver.photoURL != null ? NetworkImage(widget.receiver.photoURL!) : null,
              child: widget.receiver.photoURL == null ? Text(widget.receiver.username[0].toUpperCase()) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.receiver.username, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  StreamBuilder<bool>(
                    stream: db.getTypingStatus(widget.receiver.uid),
                    builder: (context, typingSnapshot) {
                      if (typingSnapshot.data == true) {
                        return const Text('typing...', style: TextStyle(fontSize: 12, color: Colors.blueAccent));
                      }
                      return StreamBuilder<UserModel?>(
                        stream: db.getUserData(widget.receiver.uid),
                        builder: (context, userSnapshot) {
                          final user = userSnapshot.data;
                          if (user == null) return const SizedBox();
                          return Text(
                            user.isOnline ? 'Online' : 'Offline',
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () => _startCall(CallType.voice),
            tooltip: 'Voice call',
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () => _startCall(CallType.video),
            tooltip: 'Video call',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: db.getMessages(widget.receiver.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox();
                final messages = snapshot.data ?? [];
                
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[800]),
                        const SizedBox(height: 16),
                        const Text('No messages yet', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return GestureDetector(
                      onTap: msg.type == MessageType.image
                          ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => ImageViewScreen(imageUrl: msg.mediaUrl!)))
                          : null,
                      child: ChatBubble(message: msg, isMe: msg.senderId == _currentUserId),
                    );
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image_outlined, color: Colors.blueAccent),
              onPressed: _pickImage,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                onChanged: _onTyping,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[900],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.blueAccent),
              onPressed: () => _sendMessage(text: _messageController.text),
            ),
          ],
        ),
      ),
    );
  }
}
