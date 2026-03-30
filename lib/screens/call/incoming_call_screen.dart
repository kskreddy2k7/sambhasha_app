import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sambhasha_app/models/user_model.dart';
import 'package:sambhasha_app/screens/call/call_screen.dart';
import 'package:sambhasha_app/services/call_service.dart';
import 'package:sambhasha_app/services/database_service.dart';

class IncomingCallScreen extends StatelessWidget {
  final CallModel call;
  final VoidCallback? onCallEnded;

  const IncomingCallScreen({
    super.key,
    required this.call,
    this.onCallEnded,
  });

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final callService = Provider.of<CallService>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: StreamBuilder<UserModel?>(
          stream: db.getUserData(call.callerId),
          builder: (context, snapshot) {
            final caller = snapshot.data;
            final callerName = caller?.name ?? 'Unknown';
            final callerPhoto = caller?.profilePic;

            return Column(
              children: [
                const Spacer(flex: 2),

                // Caller avatar
                CircleAvatar(
                  radius: 72,
                  backgroundColor: Colors.blueAccent.withOpacity(0.15),
                  backgroundImage: (callerPhoto != null && callerPhoto.isNotEmpty)
                      ? NetworkImage(callerPhoto)
                      : null,
                  child: (callerPhoto == null || callerPhoto.isEmpty)
                      ? Text(
                          callerName.isNotEmpty
                              ? callerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 48, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(height: 24),

                // Caller name
                Text(
                  callerName,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 8),

                // Call type label
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      call.type == CallType.video
                          ? Icons.videocam
                          : Icons.call,
                      color: Colors.white54,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      call.type == CallType.video
                          ? 'Incoming video call'
                          : 'Incoming voice call',
                      style: const TextStyle(
                          fontSize: 16, color: Colors.white54),
                    ),
                  ],
                ),

                const Spacer(flex: 3),

                // Accept / Reject buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Reject
                    _buildActionButton(
                      icon: Icons.call_end,
                      label: 'Decline',
                      color: Colors.redAccent,
                      onTap: () async {
                        await callService.rejectCall(call.callId);
                        onCallEnded?.call();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),

                    // Accept
                    _buildActionButton(
                      icon: call.type == CallType.video
                          ? Icons.videocam
                          : Icons.call,
                      label: 'Accept',
                      color: Colors.green,
                      onTap: () async {
                        await callService.acceptCall(
                          callId: call.callId,
                          type: call.type,
                        );
                        onCallEnded?.call();
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => CallScreen(
                                remoteUser: caller ??
                                    UserModel(
                                      uid: call.callerId,
                                      name: callerName,
                                      phone: '',
                                      profilePic: '',
                                      lastSeen: DateTime.now(),
                                    ),
                                callId: call.callId,
                                callType: call.type,
                                isCaller: false,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 56),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}
