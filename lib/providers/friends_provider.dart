import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull
import '../models/friendship_model.dart';
import '../models/friend_request_model.dart';
import '../models/friend_profile_model.dart';
import '../models/handicap_trend_model.dart';
import '../services/friends_service.dart';
import '../services/player_service.dart';
import '../services/whs_statistik_service.dart';

/// Provider for managing friends, friend requests, and friend profiles
///
/// Handles:
/// - Loading friendships
/// - Sending/accepting/declining friend requests
/// - Fetching friend profiles (with handicap data)
/// - Privacy settings
class FriendsProvider extends ChangeNotifier {
  final FriendsService _friendsService = FriendsService();
  final PlayerService _playerService = PlayerService();
  final WhsStatistikService _whsService = WhsStatistikService();

  List<Friendship> _friendships = [];
  List<FriendRequest> _pendingRequests = [];
  List<FriendProfile> _friends = []; // List of friend profiles
  Map<String, FriendProfile> _friendProfiles = {}; // Cache
  bool _isLoading = false;
  String? _errorMessage;
  bool _shareHandicapWithFriends = true; // Default
  String? _currentUserId; // Track current user for getFriendship()

  // Getters
  List<Friendship> get friendships => _friendships;
  List<FriendProfile> get friends => _friends;
  List<FriendRequest> get pendingRequests => _pendingRequests;
  Map<String, FriendProfile> get friendProfiles => _friendProfiles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get shareHandicapWithFriends => _shareHandicapWithFriends;
  int get pendingRequestsCount => _pendingRequests.length;

  /// Get only full friends (not contacts)
  List<FriendProfile> get fullFriends {
    print('🔍 [FriendsProvider] fullFriends getter called');
    print('🔍 [FriendsProvider]   _friends.length: ${_friends.length}');
    print('🔍 [FriendsProvider]   _currentUserId: $_currentUserId');
    print('🔍 [FriendsProvider]   _friendships.length: ${_friendships.length}');
    
    final filtered = _friends.where((friend) {
      final friendship = getFriendship(friend.unionId);
      final isFriend = friendship?.isFriend ?? false;
      print('🔍 [FriendsProvider]   ${friend.name}: friendship=${friendship != null}, isFriend=$isFriend');
      return isFriend;
    }).toList();
    
    print('🔍 [FriendsProvider] fullFriends result: ${filtered.length} friends');
    return filtered;
  }

  /// Get only contacts (not full friends)
  List<FriendProfile> get contactsOnly {
    // Filter _friends to only include those with relationType == 'contact'
    return _friends.where((friend) {
      final friendship = getFriendship(friend.unionId);
      return friendship?.isContact ?? false;
    }).toList();
  }

  /// Get friendship for a specific friend
  Friendship? getFriendship(String friendUnionId) {
    // Need to check that BOTH currentUser AND friendUnionId are part of friendship
    if (_currentUserId == null) return null;
    
    return _friendships.firstWhereOrNull(
      (fs) => (fs.userId1 == _currentUserId && fs.userId2 == friendUnionId) ||
              (fs.userId2 == _currentUserId && fs.userId1 == friendUnionId),
    );
  }

  /// Load friendships for current user
  Future<void> loadFriendships(String userId) async {
    try {
      _isLoading = true;
      _currentUserId = userId; // Set current user for getFriendship()
      _errorMessage = null;
      notifyListeners();

      _friendships = await _friendsService.getFriendships(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Load friends with basic info for list view
  ///
  /// Fetches friendships and creates FriendProfile objects with:
  /// - Player info from GetPlayer API
  /// - Current handicap
  /// - Basic trend data (delta from last score if available)
  Future<void> loadFriends(String userId) async {
    print('🔍 [FriendsProvider] loadFriends START for userId: $userId');
    _isLoading = true;
    _currentUserId = userId; // Set current user for getFriendship()
    notifyListeners();
    
    try {
      print('🔍 [FriendsProvider] Fetching friendships from Firestore...');
      _friendships = await _friendsService.getFriendships(userId);
      print('🔍 [FriendsProvider] Found ${_friendships.length} friendships');
      
      // Build friend profiles list
      _friends.clear();
      print('🔍 [FriendsProvider] Building friend profiles...');
      
      for (var friendship in _friendships) {
        try {
          // Get friend's union ID
          final friendId = friendship.getFriendId(userId);
          print('🔍 [FriendsProvider]   - Loading friend: $friendId (relationType: ${friendship.relationType})');
          
          // Fetch player info
          final player = await _playerService.fetchPlayerByUnionId(friendId);
          
          // Create basic profile (without full trend calculation for performance)
          final profile = FriendProfile(
            friendshipId: friendship.id,
            unionId: friendId,
            name: player.name,
            homeClubName: player.homeClubName,
            homeClubId: player.homeClubId,
            currentHandicap: player.hcp,
            trend: HandicapTrend.empty(currentHcp: player.hcp), // Empty trend for now
            recentScores: const [],
            lastUpdated: DateTime.now(),
            createdAt: friendship.createdAt,
          );
          
          _friends.add(profile);
          print('🔍 [FriendsProvider]   ✅ Added: ${player.name}');
        } catch (e) {
          print('❌ [FriendsProvider]   Failed to fetch friend: $e');
          // Continue with other friends even if one fails
        }
      }
      
    print('🔍 [FriendsProvider] Total profiles loaded: ${_friends.length}');
    print('🔍 [FriendsProvider] loadFriends COMPLETE');
    _errorMessage = null;
  } catch (e) {
    print('❌ [FriendsProvider] loadFriends ERROR: $e');
    _errorMessage = e.toString();
  } finally {
    _isLoading = false;
    print('🔔 [FriendsProvider] Calling notifyListeners() to rebuild UI');
    notifyListeners();
    print('🔔 [FriendsProvider] notifyListeners() called');
  }
  }

  /// Load pending friend requests for current user
  Future<void> loadPendingRequests(String userId) async {
    print('🔍 [FriendsProvider] loadPendingRequests START for userId: $userId');
    try {
      _pendingRequests = await _friendsService.getPendingRequests(userId);
      print('🔍 [FriendsProvider] Found ${_pendingRequests.length} pending requests');
      for (var request in _pendingRequests) {
        print('   - Request from ${request.fromUserName} (${request.fromUserId})');
        print('     requestedRelationType: ${request.requestedRelationType}');
      }
      notifyListeners();
      print('✅ [FriendsProvider] loadPendingRequests COMPLETE');
    } catch (e) {
      print('❌ [FriendsProvider] loadPendingRequests ERROR: $e');
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Load friend profile with handicap data
  ///
  /// Fetches:
  /// - Player info from GetPlayer API
  /// - Score history from WHS Statistik API
  /// - Calculates handicap trend
  ///
  /// Results are cached in _friendProfiles
  Future<FriendProfile> loadFriendProfile(
    String friendshipId,
    String friendUnionId,
    String friendHomeClubId, {
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache
      if (!forceRefresh && _friendProfiles.containsKey(friendUnionId)) {
        final cached = _friendProfiles[friendUnionId]!;
        if (cached.isFresh) {
          return cached;
        }
      }

      // Fetch player info
      final player = await _playerService.fetchPlayerByUnionId(friendUnionId);

      // Fetch score history
      final scores = await _whsService.getPlayerScores(
        unionId: friendUnionId,
        clubId: friendHomeClubId,
        limit: 20, // Get last 20 scores for trend analysis
      );

      // Calculate handicap trend (6 months by default)
      final trend = HandicapTrend.fromScores(
        currentHcp: player.hcp,
        scores: scores,
        periodMonths: 6,
      );

      // Get recent scores (last 3)
      final recentScores = scores.take(3).toList();

      // Create profile
      final profile = FriendProfile(
        friendshipId: friendshipId,
        unionId: friendUnionId,
        name: player.name,
        homeClubName: player.homeClubName,
        homeClubId: player.homeClubId,
        currentHandicap: player.hcp,
        trend: trend,
        recentScores: recentScores,
        lastUpdated: DateTime.now(),
      );

      // Cache it
      _friendProfiles[friendUnionId] = profile;
      notifyListeners();

      return profile;
    } catch (e) {
      throw Exception('Kunne ikke hente ven profil: $e');
    }
  }

  /// Send friend request
  ///
  /// Validates friend via GetPlayer API, then creates request
  /// Supports both old signature (toUnionId) and new signature (toUserId, toUserName)
  Future<void> sendFriendRequest({
    required String fromUserId,
    required String fromUserName,
    String? toUnionId, // Old signature for backward compatibility
    String? toUserId, // New signature
    String? toUserName, // New signature
    String relationType = 'friend', // NEW: 'contact' | 'friend'
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Support both old and new signatures
      final targetUnionId = toUserId ?? toUnionId;
      if (targetUnionId == null) {
        throw Exception('toUserId or toUnionId must be provided');
      }

      // If toUserName not provided, fetch from API
      String targetUserName;
      if (toUserName != null) {
        targetUserName = toUserName;
      } else {
        final toPlayer = await _playerService.fetchPlayerByUnionId(targetUnionId);
        targetUserName = toPlayer.name;
      }

      // Send request
      print('🔍 [FriendsProvider] Sending friend request with relationType: $relationType');
      
      await _friendsService.sendFriendRequest(
        fromUserId: fromUserId,
        fromUserName: fromUserName,
        toUserId: targetUnionId,
        toUserName: targetUserName,
        relationType: relationType, // NEW: Pass relation type
      );

      print('✅ [FriendsProvider] Friend request sent successfully');
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Accept friend request
  Future<void> acceptFriendRequest(String requestId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _friendsService.acceptFriendRequest(requestId);

      // Remove from pending list
      _pendingRequests.removeWhere((r) => r.id == requestId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Decline friend request
  Future<void> declineFriendRequest(String requestId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _friendsService.declineFriendRequest(requestId);

      // Remove from pending list
      _pendingRequests.removeWhere((r) => r.id == requestId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Remove a friend
  Future<void> removeFriend(String friendshipId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _friendsService.removeFriend(friendshipId);

      // Remove from list
      _friendships.removeWhere((f) => f.id == friendshipId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Remove all friends
  Future<void> removeAllFriends(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _friendsService.removeAllFriends(userId);

      // Clear lists
      _friendships.clear();
      _friendProfiles.clear();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Load privacy settings
  Future<void> loadPrivacySettings(String userId) async {
    try {
      final settings = await _friendsService.getPrivacySettings(userId);
      _shareHandicapWithFriends = settings['shareHandicapWithFriends'] as bool;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings(String userId, bool shareHandicap) async {
    try {
      await _friendsService.updatePrivacySettings(userId, shareHandicap);
      _shareHandicapWithFriends = shareHandicap;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Get friend profile from cache (if available)
  FriendProfile? getCachedProfile(String unionId) {
    return _friendProfiles[unionId];
  }

  // ========== LEADERBOARD METHODS ==========

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear all data (on logout)
  void clear() {
    _friendships.clear();
    _friends.clear();
    _pendingRequests.clear();
    _friendProfiles.clear();
    _isLoading = false;
    _errorMessage = null;
    _shareHandicapWithFriends = true;
    notifyListeners();
  }
}

