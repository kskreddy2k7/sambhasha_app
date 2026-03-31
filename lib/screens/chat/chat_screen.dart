import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sambhasha_app/models/message_model.dart';
import 'package:sambhasha_app/models/user_model.dart';
import 'package:sambhasha_app/providers/chat_provider.dart';
import 'package:sambhasha_app/screens/call/call_screen.dart';
import 'package:sambhasha_app/services/ai_service.dart';
import 'package:sambhasha_app/services/call_service.dart';
import 'package:sambhasha_app/services/database_service.dart';
import 'package:sambhasha_app/widgets/chat_bubble.dart';
import 'package:sambhasha_app/widgets/shimmer_skeletons.dart';
import 'package:sambhasha_app/models/call_model.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';


class ChatScreen extends StatefulWidget {
  final UserModel otherUser;

  const ChatScreen({super.key, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseService _db = DatabaseService();
  late String _chatId;
  List<String> _smartReplies = [];
  bool _isAILoading = false;
  int? _selectedDuration;
  
  // New States
  int _limit = 50;
  bool _isRecording = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  MessageModel? _replyingTo;
  MessageModel? _editingMsg;
  String? _lastMsgIdProcessed;

  @override
  void initState() {
    super.initState();
    _chatId = _db.getChatId(widget.otherUser.uid);
    _scrollController.addListener(_onScroll);
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      Provider.of<ChatProvider>(context, listen: false).markAsRead(_chatId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _msgController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (mounted) {
        setState(() {
          _limit += 30; // Load more
        });
      }
    }
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'timer':
        _showTimerDialog();
        break;
      case 'block':
        await _db.blockUser(widget.otherUser.uid);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User Blocked")));
        break;
      case 'report':
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report submitted. We'll review it shortly.")));
        break;
      case 'summarize':
        _summarizeChat();
        break;
    }
  }

  void _summarizeChat() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final messages = await chatProvider.getMessages(_chatId, limit: 30).first;
    final texts = messages.map((m) => "${m.senderId == _db.currentUid ? 'Me' : widget.otherUser.name}: ${m.text}").toList();
    
    if (mounted) {
       showDialog(
         context: context,
         builder: (context) => AlertDialog(
           backgroundColor: const Color(0xFF1A1A1A),
           title: const Text("Chat Summary (AI)", style: TextStyle(color: Colors.blueAccent)),
           content: FutureBuilder<String>(
             future: Provider.of<AIService>(context, listen: false).summarizeChat(texts),
             builder: (context, snapshot) {
               if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
               return Text(snapshot.data ?? "Failed to summarize.", style: const TextStyle(color: Colors.white, fontSize: 14));
             },
           ),
           actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cool!"))],
         ),
       );
    }
  }

  void _showTimerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF202C33),
        title: const Text("Disappearing Messages", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int?>(
              title: const Text("Off", style: TextStyle(color: Colors.white)),
              value: null,
              groupValue: _selectedDuration,
              onChanged: (val) => setState(() { _selectedDuration = val; Navigator.pop(context); }),
            ),
            RadioListTile<int?>(
              title: const Text("1 Hour", style: TextStyle(color: Colors.white)),
              value: 3600,
              groupValue: _selectedDuration,
              onChanged: (val) => setState(() { _selectedDuration = val; Navigator.pop(context); }),
            ),
            RadioListTile<int?>(
              title: const Text("24 Hours", style: TextStyle(color: Colors.white)),
              value: 86400,
              groupValue: _selectedDuration,
              onChanged: (val) => setState(() { _selectedDuration = val; Navigator.pop(context); }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchSmartReplies(String lastMsg) async {
    if (_isAILoading) return;
    setState(() => _isAILoading = true);
    final ai = Provider.of<AIService>(context, listen: false);
    try {
      final replies = await ai.generateSmartReplies(lastMsg);
      if (mounted) setState(() => _smartReplies = replies);
    } catch (e) {
      debugPrint('Smart replies error: $e');
    } finally {
      if (mounted) setState(() => _isAILoading = false);
    }
  }

  void _sendMessage({String? customText}) {
    final text = (customText ?? _msgController.text).trim();
    if (text.isEmpty) return;
    
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    if (_editingMsg != null) {
      chatProvider.editMessage(_chatId, _editingMsg!.messageId, text);
      setState(() => _editingMsg = null);
    } else {
      chatProvider.sendMessage(
        receiverId: widget.otherUser.uid,
        text: text,
        type: MessageType.text,
        expiryDuration: _selectedDuration,
        replyToId: _replyingTo?.messageId,
      );
      setState(() => _replyingTo = null);
    }
    
    _msgController.clear();
    setState(() => _smartReplies = []); // Clear smart replies after send
    _db.setTypingStatus(_chatId, false);
  }

  // Audio Recording Methods
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        const config = RecordConfig();
        await _audioRecorder.start(config, path: path);
        setState(() => _isRecording = true);
      }
    } catch (e) {
       debugPrint("Recording error: $e");
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    if (path != null) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.sendVoiceNote(receiverId: widget.otherUser.uid, filePath: path);
    }
  }

  Future<void> _startCall(BuildContext context, CallType type) async {
    final callService = Provider.of<CallService>(context, listen: false);
    try {
      final callId = await callService.initiateCall(
        receiverId: widget.otherUser.uid,
        type: type,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            remoteUser: widget.otherUser,
            callId: callId,
            callType: type,
            isCaller: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not start call: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _sendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.sendImage(
        receiverId: widget.otherUser.uid,
        fileName: pickedFile.name,
        bytes: bytes,
      );
    }
  }

  void _sendVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.sendVideo(
        receiverId: widget.otherUser.uid,
        fileName: pickedFile.name,
        bytes: bytes,
      );
    }
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
              backgroundColor: Colors.white.withValues(alpha: 0.04),
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.phone_outlined, color: Colors.blueAccent),
                  onPressed: () => _startCall(context, CallType.voice),
                ),
                IconButton(
                  icon: const Icon(Icons.videocam_outlined, color: Colors.blueAccent),
                  onPressed: () => _startCall(context, CallType.video),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.blueAccent),
                  onSelected: (val) => _handleMenuAction(val),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'timer', child: Row(children: [Icon(Icons.timer_outlined, size: 20), SizedBox(width: 10), Text("Disappearing Messages")])),
                    const PopupMenuItem(value: 'summarize', child: Row(children: [Icon(Icons.auto_awesome, size: 20, color: Colors.blueAccent), SizedBox(width: 10), Text("Summarize Chat")])),
                    const PopupMenuItem(value: 'block', child: Row(children: [Icon(Icons.block, size: 20, color: Colors.redAccent), SizedBox(width: 10), Text("Block User", style: TextStyle(color: Colors.redAccent))])),
                    const PopupMenuItem(value: 'report', child: Row(children: [Icon(Icons.report_gmailerrorred, size: 20), SizedBox(width: 10), Text("Report User")])),
                  ],
                ),
                const SizedBox(width: 8),
              ],
              title: GestureDetector(
                 onTap: () {
                   // Go to Profile logic
                 },
                 child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: widget.otherUser.profilePic.isNotEmpty 
                        ? NetworkImage(widget.otherUser.profilePic) 
                        : null,
                      child: widget.otherUser.profilePic.isEmpty ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.otherUser.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          StreamBuilder<UserModel?>(
                            stream: _db.getUserData(widget.otherUser.uid),
                            builder: (context, snapshot) {
                              final user = snapshot.data;
                              return StreamBuilder(
                                stream: chatProvider.getChatStream(_chatId),
                                builder: (context, chatSnapshot) {
                                  Map<String, dynamic>? data = chatSnapshot.data?.data() as Map<String, dynamic>?;
                                  Map<String, dynamic>? typing = data?['typing'] as Map<String, dynamic>?;
                                  bool isTyping = typing?[widget.otherUser.uid] ?? false;
                                  
                                  if (isTyping) {
                                    return const Text("typing...", style: TextStyle(fontSize: 10, color: Colors.blueAccent));
                                  }
                                  return Text(
                                    user?.isOnline == true ? "Online" : "Last seen ${user?.lastSeen != null ? timeago.format(user!.lastSeen) : 'long ago'}",
                                    style: TextStyle(fontSize: 10, color: user?.isOnline == true ? Colors.greenAccent : Colors.grey),
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
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: chatProvider.getMessages(_chatId, limit: _limit),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && _limit == 50) {
                    return const ChatListSkeleton();
                  }
                  final messages = snapshot.data ?? [];
                  if (messages.isEmpty) {
                    return const Center(child: Text("No messages yet. Say hi!", style: TextStyle(color: Colors.white60)));
                  }

                  // Trigger AI Smart Replies if last message is from other user
                  final lastMsg = messages.first;
                  if (lastMsg.senderId != _db.currentUid && lastMsg.messageId != _lastMsgIdProcessed && lastMsg.type == MessageType.text) {
                     _lastMsgIdProcessed = lastMsg.messageId;
                     _fetchSmartReplies(lastMsg.text);
                  }

                  return ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 100, bottom: 20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return ChatBubble(
                        message: message,
                        isMe: message.senderId == _db.currentUid,
                        onReply: (m) => setState(() => _replyingTo = m),
                        onEdit: (m) {
                          setState(() => _editingMsg = m);
                          _msgController.text = m.text;
                        },
                      );
                    },
                  );
                },
              ),
            ),
            
            // Smart Replies UI
            if (_smartReplies.isNotEmpty)
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _smartReplies.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                      side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.3)),
                      label: Text(_smartReplies[i], style: const TextStyle(color: Colors.blueAccent, fontSize: 13)),
                      onPressed: () => _sendMessage(customText: _smartReplies[i]),
                    ),
                  ),
                ),
              ),

            if (chatProvider.isUploading)
               const LinearProgressIndicator(backgroundColor: Colors.transparent, color: Colors.blueAccent),
            
            // Reply/Edit Preview
            if (_replyingTo != null || _editingMsg != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white.withValues(alpha: 0.05),
                child: Row(
                  children: [
                    Icon(_replyingTo != null ? Icons.reply : Icons.edit, size: 16, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _replyingTo != null ? "Replying to: ${_replyingTo!.text}" : "Editing: ${_editingMsg!.text}",
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() { _replyingTo = null; _editingMsg = null; _msgController.clear(); }),
                    ),
                  ],
                ),
              ),

            // Input Row
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.add, color: Colors.blueAccent),
                    onSelected: (val) {
                      if (val == 'image') _sendImage();
                      if (val == 'video') _sendVideo();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'image', child: Row(children: [Icon(Icons.image_outlined, size: 20), SizedBox(width: 10), Text("Image")])),
                      const PopupMenuItem(value: 'video', child: Row(children: [Icon(Icons.videocam_outlined, size: 20), SizedBox(width: 10), Text("Video")])),
                    ],
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: TextField(
                        controller: _msgController,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (val) {
                          _db.setTypingStatus(_chatId, val.isNotEmpty);
                        },
                        onSubmitted: (_) => _sendMessage(),
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
                    onLongPress: _startRecording,
                    onLongPressUp: _stopRecording,
                    onTap: () => _sendMessage(),
                    child: CircleAvatar(
                      backgroundColor: _isRecording ? Colors.redAccent : Colors.blueAccent,
                      child: Icon(
                        _isRecording ? Icons.mic : (_msgController.text.isEmpty ? Icons.mic_none : Icons.send),
                        color: Colors.white,
                        size: 20,
                      ),
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

