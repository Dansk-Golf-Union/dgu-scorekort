import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for a friend request sent from one user to another
///
/// Requests are pending until accepted or declined.
/// After 30 days, pending requests are automatically deleted.
class FriendRequest {
  final String id;
  final String fromUserId; // unionId of requester
  final String fromUserName; // Cached for display
  final String toUserId; // unionId of recipient
  final String toUserName; // Cached for display
  final String status; // 'pending' | 'accepted' | 'declined'
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String consentMessage;

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    required this.consentMessage,
  });

  /// Check if request is still pending
  bool get isPending => status == 'pending';

  /// Check if request was accepted
  bool get isAccepted => status == 'accepted';

  /// Check if request was declined
  bool get isDeclined => status == 'declined';

  /// Check if request has expired (>30 days old)
  bool get isExpired {
    final now = DateTime.now();
    return now.difference(createdAt).inDays > 30;
  }

  /// Parse from Firestore document
  factory FriendRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendRequest(
      id: doc.id,
      fromUserId: data['fromUserId'] as String,
      fromUserName: data['fromUserName'] as String,
      toUserId: data['toUserId'] as String,
      toUserName: data['toUserName'] as String,
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      consentMessage: data['consentMessage'] as String? ?? _defaultConsentMessage,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'consentMessage': consentMessage,
    };
  }

  /// Default consent message (Danish)
  static const String _defaultConsentMessage =
      'Ved at acceptere giver du samtykke til at dele:\n'
      '• Dit nuværende handicap\n'
      '• Din handicap historik\n'
      '• Dine seneste scorekort\n\n'
      'Du kan til enhver tid trække dit samtykke tilbage i Privacy indstillinger.';

  /// Create a consent message for a specific user
  static String createConsentMessage(String fromUserName) {
    return '$fromUserName vil følge dit handicap\n\n$_defaultConsentMessage';
  }

  @override
  String toString() {
    return 'FriendRequest(id: $id, from: $fromUserName → to: $toUserName, status: $status)';
  }
}


