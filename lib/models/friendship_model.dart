import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for a friendship relationship between two users
///
/// Friendships are bidirectional and stored with userId1 < userId2 alphabetically
/// to ensure only one friendship document exists per pair.
class Friendship {
  final String id;
  final String userId1; // Lower unionId alphabetically
  final String userId2; // Higher unionId alphabetically
  final String status; // 'active' | 'removed'
  final DateTime createdAt;
  final bool user1ConsentGiven; // Always true for requester
  final bool user2ConsentGiven; // True when accepted
  final String relationType; // 'contact' | 'friend'

  Friendship({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.status,
    required this.createdAt,
    required this.user1ConsentGiven,
    required this.user2ConsentGiven,
    this.relationType = 'friend', // Default for backward compatibility
  });

  /// Get the friend's userId given the current user's userId
  String getFriendId(String currentUserId) {
    return currentUserId == userId1 ? userId2 : userId1;
  }

  /// Check if current user has given consent
  bool hasUserConsent(String currentUserId) {
    return currentUserId == userId1 ? user1ConsentGiven : user2ConsentGiven;
  }

  /// Check if both users have given consent
  bool get hasMutualConsent => user1ConsentGiven && user2ConsentGiven;

  /// Check if this is a full friendship (not just contact)
  bool get isFriend => relationType == 'friend';

  /// Check if this is just a contact
  bool get isContact => relationType == 'contact';

  /// Get relation type icon
  String getRelationIcon() => relationType == 'friend' ? '👥' : '💬';

  /// Get relation type label
  String getRelationLabel() => relationType == 'friend' ? 'Ven' : 'Kontakt';

  /// Parse from Firestore document
  factory Friendship.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Friendship(
      id: doc.id,
      userId1: data['userId1'] as String,
      userId2: data['userId2'] as String,
      status: data['status'] as String? ?? 'active',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      user1ConsentGiven: data['user1ConsentGiven'] as bool? ?? true,
      user2ConsentGiven: data['user2ConsentGiven'] as bool? ?? false,
      relationType: data['relationType'] as String? ?? 'friend', // Default for backward compatibility
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId1': userId1,
      'userId2': userId2,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'user1ConsentGiven': user1ConsentGiven,
      'user2ConsentGiven': user2ConsentGiven,
      'relationType': relationType,
    };
  }

  /// Create normalized user IDs (alphabetically sorted)
  static List<String> normalizeUserIds(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0
        ? [userId1, userId2]
        : [userId2, userId1];
  }

  @override
  String toString() {
    return 'Friendship(id: $id, $userId1 <-> $userId2, status: $status, mutual: $hasMutualConsent)';
  }
}


