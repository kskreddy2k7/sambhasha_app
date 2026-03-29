import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sambhasha_app/models/message_model.dart';
import 'package:sambhasha_app/models/user_model.dart';
import 'package:sambhasha_app/screens/chat/image_view_screen.dart';
import 'package:sambhasha_app/services/auth_service.dart';
import 'package:sambhasha_app/services/database_service.dart';
import 'package:sambhasha_app/widgets/chat_bubble.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  final UserModel receiver;

  const ChatScreen({super.key, required this.receiver});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late DatabaseService _db;
  late String _currentUserId;
  Timer? _typingTimer;
  double? _uploadProgress;

  @override
  void initState() {
    super.initState();
    _db = DatabaseService();
    _currentUserId = Provider.of<AuthService>(context, listen: false).currentUser!.uid;
  }

  void _onTyping(String value) {
    _db.setTypingStatus(widget.receiver.uid, value.isNotEmpty);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _db.setTypingStatus(widget.receiver.uid, false);
    });
  }

  Future<void> _handleUpload(File file, MessageType type, {String? fileName, String? fileSize}) async {
    final task = _db.uploadMediaTask(file, type == MessageType.image ? 'chat_media/images' : 'chat_media/files');
    
    task.snapshotEvents.listen((event) {
      setState(() {
        _uploadProgress = event.bytesTransferred / event.totalBytes;
      });
    });

    final snapshot = await task;
    final url = await snapshot.ref.getDownloadURL();
    
    setState(() => _uploadProgress = null);
    _sendMessage(type: type, mediaUrl: url, fileName: fileName, fileSize: fileSize);
  }

  void _sendMessage({String? text, MessageType type = MessageType.text, String? mediaUrl, String? fileName, String? fileSize}) async {
    if ((text == null || text.trim().isEmpty) && mediaUrl == null) return;

    final message = MessageModel(
      messageId: const Uuid().v4(),
      senderId: _currentUserId,
      receiverId: widget.receiver.uid,
      message: text ?? '',
      type: type,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      mediaUrl: mediaUrl,
      fileName: fileName,
      fileSize: fileSize,
    );

    _messageController.clear();
    _db.setTypingStatus(widget.receiver.uid, false);
    await _db.sendMessage(message);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () {}, // Could navigate to User Profile
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: widget.receiver.profilePhoto != null ? NetworkImage(widget.receiver.profilePhoto!) : null,
                child: widget.receiver.profilePhoto == null ? Text(widget.receiver.name[0]) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.receiver.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    StreamBuilder<bool>(
                      stream: _db.getTypingStatus(widget.receiver.uid),
                      builder: (context, typingSnapshot) {
                        if (typingSnapshot.data == true) {
                          return const Text('typing...', style: TextStyle(fontSize: 12, color: Colors.blueAccent));
                        }
                        return StreamBuilder<UserModel>(
                          stream: _db.getUserData(widget.receiver.uid),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData) return const SizedBox();
                            final user = userSnapshot.data!;
                            return Text(
                              user.isOnline ? 'Online' : 'Last seen: ${_formatLastSeen(user.lastSeen)}',
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
        ),
      ),
      body: Column(
        children: [
          if (_uploadProgress != null)
            LinearProgressIndicator(value: _uploadProgress, backgroundColor: Colors.transparent, color: Colors.blueAccent),
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _db.getMessages(widget.receiver.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox();
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    if (msg.receiverId == _currentUserId && msg.status != MessageStatus.seen) {
                      _db.markMessageAsSeen(msg.senderId, msg.messageId);
                    }
                    return GestureDetector(
                      onLongPress: () => _showDeleteDialog(msg),
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

  String _formatLastSeen(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showDeleteDialog(MessageModel msg) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: const Text('Delete Message'),
            onTap: () {
              _db.deleteMessage(msg.senderId == _currentUserId ? msg.receiverId : msg.senderId, msg.messageId);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent, size: 28),
              onPressed: _showAttachmentMenu,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                onChanged: _onTyping,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[850],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.blueAccent, size: 28),
              onPressed: () => _sendMessage(text: _messageController.text),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(Icons.image, 'Gallery', Colors.purple, () async {
                  Navigator.pop(context);
                  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (picked != null) _handleUpload(File(picked.path), MessageType.image);
                }),
                _buildAttachmentOption(Icons.camera_alt, 'Camera', Colors.pink, () async {
                  Navigator.pop(context);
                  final picked = await ImagePicker().pickImage(source: ImageSource.camera);
                  if (picked != null) _handleUpload(File(picked.path), MessageType.image);
                }),
                _buildAttachmentOption(Icons.insert_drive_file, 'Document', Colors.indigo, () async {
                  Navigator.pop(context);
                  final result = await FilePicker.platform.pickFiles();
                  if (result != null) {
                    final file = File(result.files.single.path!);
                    _handleUpload(file, MessageType.file, fileName: result.files.single.name, fileSize: '${(result.files.single.size / 1024).toStringAsFixed(1)} KB');
                  }
                }),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: color,
          child: IconButton(icon: Icon(icon, color: Colors.white, size: 28), onPressed: onTap),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
