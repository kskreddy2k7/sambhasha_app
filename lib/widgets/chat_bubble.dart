import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sambhasha_app/models/message_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sambhasha_app/services/database_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sambhasha_app/services/ai_service.dart';

class ChatBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final String? groupId;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.groupId,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  String? _translatedText;
  bool _isTranslating = false;

  void _showMessageMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF202C33),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.message.type == MessageType.text)
              ListTile(
                leading: const Icon(Icons.translate, color: Colors.blueAccent),
                title: const Text("Translate to English", style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  setState(() => _isTranslating = true);
                  final ai = Provider.of<AIService>(context, listen: false);
                  final result = await ai.translateText(widget.message.text, "English");
                  setState(() {
                    _translatedText = result;
                    _isTranslating = false;
                  });
                },
              ),
            if (widget.isMe) ...[
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.orangeAccent),
                title: const Text("Delete for Me", style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final db = DatabaseService();
                  String id = widget.groupId ?? db.getChatId(widget.message.senderId);
                  await db.deleteMessage(id, widget.message.messageId, false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                title: const Text("Delete for Everyone", style: TextStyle(color: Colors.white)),
                onTap: () async {
                   Navigator.pop(context);
                   final db = DatabaseService();
                   String id = widget.groupId ?? db.getChatId(widget.message.senderId);
                   await db.deleteMessage(id, widget.message.messageId, true);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.isDeleted) {
       return _buildDeletedBubble();
    }

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageMenu(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Column(
            crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                decoration: BoxDecoration(
                  color: widget.isMe ? const Color(0xFF005C4B) : const Color(0xFF202C33),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: widget.isMe ? const Radius.circular(16) : const Radius.circular(4),
                    bottomRight: widget.isMe ? const Radius.circular(4) : const Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14, right: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildContent(),
                          if (_isTranslating)
                             const Padding(
                               padding: EdgeInsets.only(top: 8.0),
                               child: SizedBox(width: 20, height: 2, child: LinearProgressIndicator(color: Colors.blueAccent)),
                             ),
                          if (_translatedText != null)
                             Padding(
                               padding: const EdgeInsets.only(top: 8.0),
                               child: Container(
                                 padding: const EdgeInsets.all(8),
                                 decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                 ),
                                 child: Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 12),
                                     const SizedBox(width: 6),
                                     Flexible(
                                       child: Text(
                                         _translatedText!,
                                         style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                             ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.message.expiryDuration != null)
                             const Padding(
                               padding: EdgeInsets.only(right: 4.0),
                               child: Icon(Icons.timer_outlined, size: 12, color: Colors.blueAccent),
                             ),
                          Text(
                            DateFormat('hh:mm a').format(widget.message.timestamp),
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                          ),
                          if (widget.isMe) ...[
                            const SizedBox(width: 4),
                            _buildStatusIcon(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.message.type) {
      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: widget.message.text,
            placeholder: (context, url) => Container(
              height: 200, width: 200, color: Colors.grey[800],
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        );
      case MessageType.file:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description, color: Colors.blueAccent, size: 32),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Document File", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text("Click to view", style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white70),
                onPressed: () async {
                   final url = Uri.parse(widget.message.text);
                   if (await canLaunchUrl(url)) await launchUrl(url);
                },
              ),
            ],
          ),
        );
      case MessageType.voice:
        return AudioPlayerWidget(audioUrl: widget.message.text, isMe: widget.isMe);
      default:
        return Text(
          widget.message.text,
          style: const TextStyle(color: Colors.white, fontSize: 15.5),
        );
    }
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color = Colors.white.withOpacity(0.5);

    switch (widget.message.status) {
      case MessageStatus.sent:
        icon = Icons.done;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        break;
      case MessageStatus.seen:
        icon = Icons.done_all;
        color = Colors.blueAccent;
        break;
    }

    return Icon(icon, size: 14, color: color);
  }

  Widget _buildDeletedBubble() {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[900]?.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                widget.isMe ? "You deleted this message" : "This message was deleted",
                style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
