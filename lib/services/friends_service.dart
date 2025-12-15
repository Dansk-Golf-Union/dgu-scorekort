import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/friendship_model.dart';
import '../models/friend_request_model.dart';

/// Service for managing friendships and friend requests in Firestore
///
/// Handles CRUD operations for:
/// - friendships collection
/// - friend_requests collection
/// - user_privacy_settings collection
class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _friendshipsRef => _firestore.collection('friendships');
  CollectionReference get _friendRequestsRef => _firestore.collection('friend_requests');
  CollectionReference get _privacySettingsRef => _firestore.collection('user_privacy_settings');

  /// Get all active friendships for a user
  Future<List<Friendship>> getFriendships(String userId) async {
    try {
      // Query friendships where user is userId1 OR userId2
      final query1 = await _friendshipsRef
          .where('userId1', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      final query2 = await _friendshipsRef
          .where('userId2', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      // Combine results
      final allDocs = [...query1.docs, ...query2.docs];

      return allDocs.map((doc) => Friendship.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch friendships: $e');
    }
  }

  /// Get pending friend requests sent TO a user
  Future<List<FriendRequest>> getPendingRequests(String userId) async {
    try {
      final query = await _friendRequestsRef
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => FriendRequest.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch pending requests: $e');
    }
  }

  /// Get a specific friend request by ID
  Future<FriendRequest?> getFriendRequest(String requestId) async {
    try {
      final doc = await _friendRequestsRef.doc(requestId).get();
      if (!doc.exists) return null;
      return FriendRequest.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch friend request: $e');
    }
  }

  /// Send a friend request from one user to another
  ///
  /// Validates:
  /// - Not sending to self
  /// - Not already friends
  /// - No pending request exists
  Future<String> sendFriendRequest({
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
  }) async {
    try {
      // Validate: Not sending to self
      if (fromUserId == toUserId) {
        throw Exception('Du kan ikke tilføje dig selv som ven');
      }

      // Check if already friends
      final existingFriendship = await _checkExistingFriendship(fromUserId, toUserId);
      if (existingFriendship != null) {
        throw Exception('I er allerede venner');
      }

      // Check for existing pending request (in either direction)
      final existingRequest = await _checkExistingRequest(fromUserId, toUserId);
      if (existingRequest != null) {
        if (existingRequest.fromUserId == fromUserId) {
          throw Exception('Du har allerede sendt en anmodning til denne spiller');
        } else {
          throw Exception('Denne spiller har allerede sendt dig en anmodning');
        }
      }

      // Create consent message
      final consentMessage = FriendRequest.createConsentMessage(fromUserName);

      // Create friend request
      final request = FriendRequest(
        id: '', // Will be set by Firestore
        fromUserId: fromUserId,
        fromUserName: fromUserName,
        toUserId: toUserId,
        toUserName: toUserName,
        status: 'pending',
        createdAt: DateTime.now(),
        consentMessage: consentMessage,
      );

      final docRef = await _friendRequestsRef.add(request.toFirestore());

      // Send push notification via Cloud Function
      try {
        final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('sendNotification');

        await callable.call({
          'type': 'FRIEND_REQUEST',
          'fromUserName': fromUserName,
          'toUnionId': toUserId,
          'requestId': docRef.id,
        });
        print('✅ Friend request notification sent to $toUserId');
      } catch (e) {
        print('⚠️ Failed to send notification: $e');
        // Don't throw - Firestore write succeeded, notification is optional
      }

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Accept a friend request
  ///
  /// Creates a friendship and marks request as accepted.
  Future<void> acceptFriendRequest(String requestId) async {
    try {
      final request = await getFriendRequest(requestId);
      if (request == null) {
        throw Exception('Venneanmodning ikke fundet');
      }

      if (request.status != 'pending') {
        throw Exception('Denne anmodning er allerede behandlet');
      }

      // Normalize user IDs (alphabetically)
      final normalizedIds = Friendship.normalizeUserIds(
        request.fromUserId,
        request.toUserId,
      );

      // Create friendship
      final friendship = Friendship(
        id: '', // Will be set by Firestore
        userId1: normalizedIds[0],
        userId2: normalizedIds[1],
        status: 'active',
        createdAt: DateTime.now(),
        user1ConsentGiven: true, // Requester always consents
        user2ConsentGiven: true, // Accepter consents by accepting
      );

      // Update request status
      await _friendRequestsRef.doc(requestId).update({
        'status': 'accepted',
        'respondedAt': Timestamp.now(),
      });

      // Create friendship
      await _friendshipsRef.add(friendship.toFirestore());
    } catch (e) {
      throw Exception('Failed to accept friend request: $e');
    }
  }

  /// Decline a friend request
  Future<void> declineFriendRequest(String requestId) async {
    try {
      final request = await getFriendRequest(requestId);
      if (request == null) {
        throw Exception('Venneanmodning ikke fundet');
      }

      if (request.status != 'pending') {
        throw Exception('Denne anmodning er allerede behandlet');
      }

      // Mark as declined
      await _friendRequestsRef.doc(requestId).update({
        'status': 'declined',
        'respondedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to decline friend request: $e');
    }
  }

  /// Remove a friendship
  ///
  /// Marks friendship as 'removed' (soft delete for audit trail)
  Future<void> removeFriend(String friendshipId) async {
    try {
      await _friendshipsRef.doc(friendshipId).update({
        'status': 'removed',
      });
    } catch (e) {
      throw Exception('Failed to remove friend: $e');
    }
  }

  /// Remove all friendships for a user
  Future<void> removeAllFriends(String userId) async {
    try {
      final friendships = await getFriendships(userId);
      for (final friendship in friendships) {
        await removeFriend(friendship.id);
      }
    } catch (e) {
      throw Exception('Failed to remove all friends: $e');
    }
  }

  /// Get privacy settings for a user
  Future<Map<String, dynamic>> getPrivacySettings(String userId) async {
    try {
      final doc = await _privacySettingsRef.doc(userId).get();
      if (!doc.exists) {
        // Return defaults
        return {
          'shareHandicapWithFriends': true, // Default: ON
          'updatedAt': DateTime.now(),
        };
      }
      final data = doc.data() as Map<String, dynamic>;
      return {
        'shareHandicapWithFriends': data['shareHandicapWithFriends'] as bool? ?? true,
        'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      };
    } catch (e) {
      throw Exception('Failed to fetch privacy settings: $e');
    }
  }

  /// Update privacy settings for a user
  Future<void> updatePrivacySettings(String userId, bool shareHandicap) async {
    try {
      await _privacySettingsRef.doc(userId).set({
        'shareHandicapWithFriends': shareHandicap,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update privacy settings: $e');
    }
  }

  /// Check if two users are already friends
  Future<Friendship?> _checkExistingFriendship(String userId1, String userId2) async {
    final normalizedIds = Friendship.normalizeUserIds(userId1, userId2);
    final query = await _friendshipsRef
        .where('userId1', isEqualTo: normalizedIds[0])
        .where('userId2', isEqualTo: normalizedIds[1])
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return Friendship.fromFirestore(query.docs.first);
  }

  /// Check if there's an existing request between two users
  Future<FriendRequest?> _checkExistingRequest(String userId1, String userId2) async {
    // Check both directions
    final query1 = await _friendRequestsRef
        .where('fromUserId', isEqualTo: userId1)
        .where('toUserId', isEqualTo: userId2)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (query1.docs.isNotEmpty) {
      return FriendRequest.fromFirestore(query1.docs.first);
    }

    final query2 = await _friendRequestsRef
        .where('fromUserId', isEqualTo: userId2)
        .where('toUserId', isEqualTo: userId1)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (query2.docs.isNotEmpty) {
      return FriendRequest.fromFirestore(query2.docs.first);
    }

    return null;
  }

  /// Clean up expired friend requests (>30 days old)
  Future<int> cleanupExpiredRequests() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      final query = await _friendRequestsRef
          .where('status', isEqualTo: 'pending')
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      int deleted = 0;
      for (final doc in query.docs) {
        await doc.reference.delete();
        deleted++;
      }

      return deleted;
    } catch (e) {
      throw Exception('Failed to cleanup expired requests: $e');
    }
  }
}

