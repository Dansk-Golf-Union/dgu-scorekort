import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_group.dart';
import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== GROUPS ====================

  /// Create new chat group
  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
    required String createdBy,
  }) async {
    final docRef = await _db.collection('chat_groups').add({
      'name': name,
      'members': memberIds,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': null,
      'lastMessageTime': null,
      'unreadCount': {for (var id in memberIds) id: 0},
    });
    return docRef.id;
  }

  /// Stream all groups for a user
  Stream<List<ChatGroup>> streamUserGroups(String unionId) {
    return _db
        .collection('chat_groups')
        .where('members', arrayContains: unionId)
        .snapshots()
        .map((snapshot) {
          final groups = snapshot.docs
              .map((doc) => ChatGroup.fromFirestore(doc))
              .where((group) => !group.hiddenFor.contains(unionId)) // Filter hidden
              .toList();
          
          // Sort in-memory by lastMessageTime (null last), then createdAt
          groups.sort((a, b) {
            if (a.lastMessageTime != null && b.lastMessageTime != null) {
              return b.lastMessageTime!.compareTo(a.lastMessageTime!);
            } else if (a.lastMessageTime != null) {
              return -1; // a has messages, comes first
            } else if (b.lastMessageTime != null) {
              return 1; // b has messages, comes first
            } else {
              // Both null, sort by createdAt
              return b.createdAt.compareTo(a.createdAt);
            }
          });
          
          return groups;
        });
  }

  /// Get single group
  Future<ChatGroup?> getGroup(String groupId) async {
    final doc = await _db.collection('chat_groups').doc(groupId).get();
    if (!doc.exists) return null;
    return ChatGroup.fromFirestore(doc);
  }

  /// Add member to group
  Future<void> addMemberToGroup(String groupId, String unionId) async {
    await _db.collection('chat_groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([unionId]),
      'unreadCount.$unionId': 0,
    });
  }

  /// Remove member from group
  Future<void> removeMemberFromGroup(String groupId, String unionId) async {
    await _db.collection('chat_groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([unionId]),
      'unreadCount.$unionId': FieldValue.delete(),
    });
  }

  /// Hide chat for user (archive)
  Future<void> hideChat(String groupId, String unionId) async {
    await _db.collection('chat_groups').doc(groupId).update({
      'hiddenFor': FieldValue.arrayUnion([unionId])
    });
  }

  /// Unhide chat (when new message arrives)
  Future<void> unhideChat(String groupId, String unionId) async {
    await _db.collection('chat_groups').doc(groupId).update({
      'hiddenFor': FieldValue.arrayRemove([unionId])
    });
  }

  // ==================== MESSAGES ====================

  /// Send message
  Future<void> sendMessage({
    required String groupId,
    required String text,
    required String senderId,
    required String senderName,
  }) async {
    final group = await getGroup(groupId);
    if (group == null) throw Exception('Group not found');

    // Add message to subcollection
    await _db
        .collection('messages')
        .doc(groupId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': [senderId], // Sender has read it
    });

    // Update group's last message + increment unread for others
    final unreadUpdates = <String, dynamic>{};
    for (final memberId in group.members) {
      if (memberId != senderId) {
        unreadUpdates['unreadCount.$memberId'] = FieldValue.increment(1);
      }
    }

    await _db.collection('chat_groups').doc(groupId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      ...unreadUpdates,
    });
  }

  /// Stream messages for a group
  Stream<List<ChatMessage>> streamMessages(String groupId) {
    return _db
        .collection('messages')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String groupId, String unionId) async {
    // Reset unread count for this user
    await _db.collection('chat_groups').doc(groupId).update({
      'unreadCount.$unionId': 0,
    });

    // Update readBy for unread messages (batch)
    final unreadMessages = await _db
        .collection('messages')
        .doc(groupId)
        .collection('messages')
        .where('readBy', whereNotIn: [
      [unionId]
    ]).get();

    if (unreadMessages.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {
        'readBy': FieldValue.arrayUnion([unionId])
      });
    }
    await batch.commit();
  }
}

