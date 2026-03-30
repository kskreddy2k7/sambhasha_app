import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:sambhasha_app/models/user_model.dart';
import 'package:sambhasha_app/services/call_service.dart';

class CallScreen extends StatefulWidget {
  final UserModel remoteUser;
  final String callId;
  final CallType callType;
  /// True when this device initiated the call.
  final bool isCaller;

  const CallScreen({
    super.key,
    required this.remoteUser,
    required this.callId,
    required this.callType,
    required this.isCaller,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final CallService _callService;

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  StreamSubscription<MediaStream?>? _localSub;
  StreamSubscription<MediaStream?>? _remoteSub;

  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isConnected = false;
  bool _speakerOn = true;

  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _callService = Provider.of<CallService>(context, listen: false);
    _initRenderers();
    _listenStreams();
    _startTimer();
    // Default to speakerphone on during calls
    Helper.setSpeakerphoneOn(true);
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _listenStreams() {
    _localSub = _callService.localStream.listen((stream) {
      if (mounted) {
        setState(() {
          _localRenderer.srcObject = stream;
        });
      }
    });

    _remoteSub = _callService.remoteStream.listen((stream) {
      if (mounted) {
        final wasConnected = _isConnected;
        setState(() {
          _remoteRenderer.srcObject = stream;
          _isConnected = stream != null;
        });
        // Auto-pop when remote hangs up (stream clears after being connected)
        if (wasConnected && stream == null && mounted) {
          Helper.setSpeakerphoneOn(false);
          Navigator.of(context).pop();
        }
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  String get _formattedDuration {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _endCall() async {
    Helper.setSpeakerphoneOn(false);
    await _callService.endCall(widget.callId);
    if (mounted) Navigator.of(context).pop();
  }

  void _toggleMute() {
    _callService.toggleMute();
    setState(() => _isMuted = _callService.isMuted);
  }

  void _toggleCamera() {
    _callService.toggleCamera();
    setState(() => _isCameraOff = _callService.isCameraOff);
  }

  void _switchCamera() {
    _callService.switchCamera();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _localSub?.cancel();
    _remoteSub?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: widget.callType == CallType.video
            ? _buildVideoCall()
            : _buildVoiceCall(),
      ),
    );
  }

  // ─── Video call layout ───────────────────────────────────────────────────

  Widget _buildVideoCall() {
    return Stack(
      children: [
        // Remote video (full screen)
        Positioned.fill(
          child: _isConnected
              ? RTCVideoView(_remoteRenderer,
                  objectFit:
                      RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
              : _buildConnectingOverlay(),
        ),

        // Local video (small, top-right)
        Positioned(
          top: 16,
          right: 16,
          width: 100,
          height: 140,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: RTCVideoView(_localRenderer, mirror: true),
          ),
        ),

        // Caller info + timer (top-left)
        Positioned(
          top: 16,
          left: 16,
          child: _buildCallInfo(light: true),
        ),

        // Controls (bottom)
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: _buildVideoControls(),
        ),
      ],
    );
  }

  // ─── Voice call layout ───────────────────────────────────────────────────

  Widget _buildVoiceCall() {
    return Column(
      children: [
        const Spacer(flex: 2),
        CircleAvatar(
          radius: 72,
          backgroundColor: Colors.blueAccent.withOpacity(0.15),
        backgroundImage: widget.remoteUser.profilePic.isNotEmpty
            ? NetworkImage(widget.remoteUser.profilePic)
            : null,
        child: widget.remoteUser.profilePic.isEmpty
            ? Text(widget.remoteUser.name[0].toUpperCase(),
                style: const TextStyle(fontSize: 48, color: Colors.white))
            : null,
      ),
      const SizedBox(height: 24),
      Text(widget.remoteUser.name,
          style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white)),
        const SizedBox(height: 8),
        Text(
          _isConnected ? _formattedDuration : 'Connecting…',
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
        const Spacer(flex: 3),
        _buildVoiceControls(),
        const SizedBox(height: 40),
      ],
    );
  }

  // ─── Shared widgets ──────────────────────────────────────────────────────

  Widget _buildConnectingOverlay() {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 56,
              backgroundImage: widget.remoteUser.profilePic.isNotEmpty
                  ? NetworkImage(widget.remoteUser.profilePic)
                  : null,
              child: widget.remoteUser.profilePic.isEmpty
                  ? Text(widget.remoteUser.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 36))
                  : null,
            ),
            const SizedBox(height: 16),
            Text(widget.remoteUser.name,
                style: const TextStyle(fontSize: 22, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Connecting…',
                style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildCallInfo({bool light = false}) {
    final textColor = light ? Colors.white : Colors.black87;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.remoteUser.name,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor)),
        Text(
          _isConnected ? _formattedDuration : 'Connecting…',
          style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildVideoControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _controlButton(
          icon: _isMuted ? Icons.mic_off : Icons.mic,
          label: _isMuted ? 'Unmute' : 'Mute',
          onTap: _toggleMute,
          active: _isMuted,
        ),
        _controlButton(
          icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
          label: _isCameraOff ? 'Show' : 'Hide',
          onTap: _toggleCamera,
          active: _isCameraOff,
        ),
        _controlButton(
          icon: Icons.flip_camera_ios,
          label: 'Flip',
          onTap: _switchCamera,
        ),
        _endCallButton(),
      ],
    );
  }

  Widget _buildVoiceControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _controlButton(
          icon: _isMuted ? Icons.mic_off : Icons.mic,
          label: _isMuted ? 'Unmute' : 'Mute',
          onTap: _toggleMute,
          active: _isMuted,
        ),
        _endCallButton(),
        _controlButton(
          icon: _speakerOn ? Icons.volume_up : Icons.hearing,
          label: _speakerOn ? 'Speaker' : 'Earpiece',
          onTap: () {
            final newValue = !_speakerOn;
            Helper.setSpeakerphoneOn(newValue);
            setState(() => _speakerOn = newValue);
          },
          active: _speakerOn,
        ),
      ],
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor:
                active ? Colors.white24 : Colors.white.withOpacity(0.1),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _endCallButton() {
    return GestureDetector(
      onTap: _endCall,
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.redAccent,
            child: const Icon(Icons.call_end, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 6),
          const Text('End',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
