enum CallType { voice, video }
enum CallStatus { calling, accepted, rejected, ended, missed }

class CallModel {
  final String callId;
  final String callerId; // Renamed from senderId to match existing code usage
  final String receiverId;
  final String senderName;
  final String senderPic;
  final String receiverName;
  final String receiverPic;
  final CallType type;
  final CallStatus status;
  final DateTime timestamp;

  CallModel({
    required this.callId,
    required this.callerId,
    required this.receiverId,
    required this.senderName,
    required this.senderPic,
    required this.receiverName,
    required this.receiverPic,
    required this.type,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'callId': callId,
      'callerId': callerId,
      'receiverId': receiverId,
      'senderName': senderName,
      'senderPic': senderPic,
      'receiverName': receiverName,
      'receiverPic': receiverPic,
      'type': type.name,
      'status': status.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory CallModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return CallModel(
      callId: id ?? map['callId'] ?? '',
      callerId: map['callerId'] ?? map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderPic: map['senderPic'] ?? '',
      receiverName: map['receiverName'] ?? '',
      receiverPic: map['receiverPic'] ?? '',
      type: map['type'] == 'video' ? CallType.video : CallType.voice,
      status: CallStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String? ?? 'calling'),
        orElse: () => CallStatus.calling,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }
}


