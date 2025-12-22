import 'package:cloud_firestore/cloud_firestore.dart';

class ChatGroup {
  final String id;
  final String name;
  final List<String> members; // unionIds
  final String createdBy; // unionId
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount; // unionId -> count
  final List<String> hiddenFor; // unionIds who archived this chat

  ChatGroup({
    required this.id,
    required this.name,
    required this.members,
    required this.createdBy,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = const {},
    this.hiddenFor = const [],
  });

  factory ChatGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatGroup(
      id: doc.id,
      name: data['name'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      hiddenFor: List<String>.from(data['hiddenFor'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'members': members,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'unreadCount': unreadCount,
      'hiddenFor': hiddenFor,
    };
  }

  int getUnreadCountForUser(String unionId) {
    return unreadCount[unionId] ?? 0;
  }

  bool hasUnreadMessages(String unionId) {
    return getUnreadCountForUser(unionId) > 0;
  }
}

