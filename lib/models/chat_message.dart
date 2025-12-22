import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String text;
  final String senderId; // unionId
  final String senderName;
  final DateTime timestamp;
  final List<String> readBy; // unionIds

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    this.readBy = const [],
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      text: data['text'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      readBy: List<String>.from(data['readBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': Timestamp.fromDate(timestamp),
      'readBy': readBy,
    };
  }

  bool isReadBy(String unionId) {
    return readBy.contains(unionId);
  }

  bool isSentByMe(String myUnionId) {
    return senderId == myUnionId;
  }
}

