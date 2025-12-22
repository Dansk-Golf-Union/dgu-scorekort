import 'package:cloud_firestore/cloud_firestore.dart';

/// User Stats Model - Denormalized cache for instant homepage loading
///
/// Updated by Cloud Function triggers when:
/// - Friendships are created/updated/deleted
/// - Chat groups are created/updated/deleted
/// - Messages are sent/read
///
/// Pattern follows: birdie_bonus_cache, user_score_cache, course-cache-metadata
class UserStats {
  final String unionId;
  
  // Friends stats
  final int totalFriends; // All friends (contacts + full friends)
  final int fullFriends;  // relationType == 'friend'
  final int contacts;     // relationType == 'contact'
  
  // Chat stats
  final int unreadChatCount;   // Total unread messages across all groups
  final int totalChatGroups;   // Total visible groups (excluding hidden)
  
  // Metadata
  final DateTime lastUpdated;

  UserStats({
    required this.unionId,
    required this.totalFriends,
    required this.fullFriends,
    required this.contacts,
    required this.unreadChatCount,
    required this.totalChatGroups,
    required this.lastUpdated,
  });

  /// Create from Firestore document
  factory UserStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserStats(
      unionId: data['unionId'] as String,
      totalFriends: data['totalFriends'] as int? ?? 0,
      fullFriends: data['fullFriends'] as int? ?? 0,
      contacts: data['contacts'] as int? ?? 0,
      unreadChatCount: data['unreadChatCount'] as int? ?? 0,
      totalChatGroups: data['totalChatGroups'] as int? ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  /// Create empty stats (fallback when document doesn't exist yet)
  factory UserStats.empty(String unionId) {
    return UserStats(
      unionId: unionId,
      totalFriends: 0,
      fullFriends: 0,
      contacts: 0,
      unreadChatCount: 0,
      totalChatGroups: 0,
      lastUpdated: DateTime.now(),
    );
  }

  /// Check if stats are fresh (less than 5 minutes old)
  bool get isFresh {
    final age = DateTime.now().difference(lastUpdated);
    return age.inMinutes < 5;
  }

  /// Check if user has any friends
  bool get hasFriends => totalFriends > 0;

  /// Check if user has unread messages
  bool get hasUnreadMessages => unreadChatCount > 0;

  @override
  String toString() {
    return 'UserStats($unionId: $totalFriends friends, $unreadChatCount unread)';
  }
}

