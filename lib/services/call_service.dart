import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

enum CallType { voice, video }

enum CallStatus { calling, accepted, rejected, ended, missed }

class CallModel {
  final String callId;
  final String callerId;
  final String receiverId;
  final CallType type;
  final CallStatus status;

  const CallModel({
    required this.callId,
    required this.callerId,
    required this.receiverId,
    required this.type,
    required this.status,
  });

  factory CallModel.fromMap(Map<String, dynamic> map, String id) {
    return CallModel(
      callId: id,
      callerId: map['callerId'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      type: map['type'] == 'video' ? CallType.video : CallType.voice,
      status: CallStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String? ?? 'calling'),
        orElse: () => CallStatus.calling,
      ),
    );
  }
}

class CallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  bool _remoteDescriptionSet = false;

  StreamSubscription<DocumentSnapshot>? _callDocSub;
  StreamSubscription<QuerySnapshot>? _remoteCandidatesSub;

  final _localStreamCtrl = StreamController<MediaStream?>.broadcast();
  final _remoteStreamCtrl = StreamController<MediaStream?>.broadcast();

  Stream<MediaStream?> get localStream => _localStreamCtrl.stream;
  Stream<MediaStream?> get remoteStream => _remoteStreamCtrl.stream;

  bool _isMuted = false;
  bool _isCameraOff = false;

  bool get isMuted => _isMuted;
  bool get isCameraOff => _isCameraOff;

  // ICE / STUN configuration
  static const Map<String, dynamic> _rtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  // ─── Incoming call stream ────────────────────────────────────────────────

  Stream<CallModel?> listenForIncomingCalls() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('calls')
        .where('receiverId', isEqualTo: uid)
        .where('status', isEqualTo: 'calling')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return CallModel.fromMap(doc.data(), doc.id);
    });
  }

  // ─── Initiate a call (caller side) ──────────────────────────────────────

  Future<String> initiateCall({
    required String receiverId,
    required CallType type,
  }) async {
    final callId = const Uuid().v4();
    final callerId = _auth.currentUser!.uid;

    // Create Firestore call document
    await _firestore.collection('calls').doc(callId).set({
      'callerId': callerId,
      'receiverId': receiverId,
      'type': type == CallType.video ? 'video' : 'voice',
      'status': 'calling',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Set up peer connection + local media
    await _setupPeerConnection(callId: callId, isCaller: true, type: type);

    // Create and store offer
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    await _firestore.collection('calls').doc(callId).update({
      'offer': {'type': offer.type, 'sdp': offer.sdp},
    });

    // Watch for answer + status changes
    _callDocSub = _firestore
        .collection('calls')
        .doc(callId)
        .snapshots()
        .listen((doc) async {
      if (!doc.exists) return;
      final data = doc.data()!;

      final answerData = data['answer'] as Map<String, dynamic>?;
      if (answerData != null && !_remoteDescriptionSet) {
        _remoteDescriptionSet = true;
        await _peerConnection?.setRemoteDescription(
          RTCSessionDescription(
              answerData['sdp'] as String, answerData['type'] as String),
        );
      }

      final status = data['status'] as String?;
      if (status == 'rejected' || status == 'ended') {
        await _cleanup();
      }
    });

    // Watch for remote (receiver) ICE candidates
    _remoteCandidatesSub = _firestore
        .collection('calls')
        .doc(callId)
        .collection('receiverCandidates')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final d = change.doc.data()!;
          _peerConnection?.addCandidate(RTCIceCandidate(
            d['candidate'] as String?,
            d['sdpMid'] as String?,
            d['sdpMLineIndex'] as int?,
          ));
        }
      }
    });

    return callId;
  }

  // ─── Accept an incoming call (receiver side) ────────────────────────────

  Future<void> acceptCall({
    required String callId,
    required CallType type,
  }) async {
    await _setupPeerConnection(callId: callId, isCaller: false, type: type);

    final callDoc = await _firestore.collection('calls').doc(callId).get();
    final offerData = callDoc.data()?['offer'] as Map<String, dynamic>?;
    if (offerData == null) return;

    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(
          offerData['sdp'] as String, offerData['type'] as String),
    );

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    await _firestore.collection('calls').doc(callId).update({
      'answer': {'type': answer.type, 'sdp': answer.sdp},
      'status': 'accepted',
    });

    // Watch for caller ICE candidates
    _remoteCandidatesSub = _firestore
        .collection('calls')
        .doc(callId)
        .collection('callerCandidates')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final d = change.doc.data()!;
          _peerConnection?.addCandidate(RTCIceCandidate(
            d['candidate'] as String?,
            d['sdpMid'] as String?,
            d['sdpMLineIndex'] as int?,
          ));
        }
      }
    });

    // Watch for call-end status
    _callDocSub = _firestore
        .collection('calls')
        .doc(callId)
        .snapshots()
        .listen((doc) async {
      if (!doc.exists) return;
      final status = doc.data()?['status'] as String?;
      if (status == 'ended') await _cleanup();
    });
  }

  // ─── Reject ─────────────────────────────────────────────────────────────

  Future<void> rejectCall(String callId) async {
    await _firestore
        .collection('calls')
        .doc(callId)
        .update({'status': 'rejected'});
    await _cleanup();
  }

  // ─── End (either side) ──────────────────────────────────────────────────

  Future<void> endCall(String callId) async {
    try {
      await _firestore
          .collection('calls')
          .doc(callId)
          .update({'status': 'ended'});
    } catch (_) {}
    await _cleanup();
  }

  // ─── Controls ───────────────────────────────────────────────────────────

  void toggleMute() {
    if (_localStream == null) return;
    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = !track.enabled;
    }
    _isMuted = !_isMuted;
  }

  void toggleCamera() {
    if (_localStream == null) return;
    for (final track in _localStream!.getVideoTracks()) {
      track.enabled = !track.enabled;
    }
    _isCameraOff = !_isCameraOff;
  }

  Future<void> switchCamera() async {
    if (_localStream == null) return;
    final videoTracks = _localStream!.getVideoTracks();
    if (videoTracks.isNotEmpty) {
      await Helper.switchCamera(videoTracks.first);
    }
  }

  // ─── Private helpers ─────────────────────────────────────────────────────

  Future<void> _setupPeerConnection({
    required String callId,
    required bool isCaller,
    required CallType type,
  }) async {
    _peerConnection = await createPeerConnection(_rtcConfig);

    // Get local media
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': type == CallType.video
          ? {'facingMode': 'user', 'width': 640, 'height': 480}
          : false,
    });
    _localStreamCtrl.add(_localStream);

    for (final track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }

    // Remote stream
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStreamCtrl.add(event.streams.first);
      }
    };

    // Send local ICE candidates to Firestore
    final candidatesCollection =
        isCaller ? 'callerCandidates' : 'receiverCandidates';
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        _firestore
            .collection('calls')
            .doc(callId)
            .collection(candidatesCollection)
            .add({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    _peerConnection!.onConnectionState =
        (RTCPeerConnectionState state) async {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state ==
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        await _cleanup();
      }
    };
  }

  Future<void> _cleanup() async {
    _callDocSub?.cancel();
    _remoteCandidatesSub?.cancel();
    _callDocSub = null;
    _remoteCandidatesSub = null;

    await _localStream?.dispose();
    _localStream = null;
    _isMuted = false;
    _isCameraOff = false;
    _remoteDescriptionSet = false;

    await _peerConnection?.close();
    _peerConnection = null;

    _localStreamCtrl.add(null);
    _remoteStreamCtrl.add(null);
  }

  void dispose() {
    _callDocSub?.cancel();
    _remoteCandidatesSub?.cancel();
    _localStream?.dispose();
    _peerConnection?.close();
    _localStreamCtrl.close();
    _remoteStreamCtrl.close();
  }
}
