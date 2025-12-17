import 'package:flutter/material.dart';
import '../models/friendship_model.dart';
import '../models/friend_request_model.dart';
import '../models/friend_profile_model.dart';
import '../models/handicap_trend_model.dart';
import '../models/leaderboard_entry.dart';
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

  // Getters
  List<Friendship> get friendships => _friendships;
  List<FriendProfile> get friends => _friends;
  List<FriendRequest> get pendingRequests => _pendingRequests;
  Map<String, FriendProfile> get friendProfiles => _friendProfiles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get shareHandicapWithFriends => _shareHandicapWithFriends;
  int get pendingRequestsCount => _pendingRequests.length;

  /// Load friendships for current user
  Future<void> loadFriendships(String userId) async {
    try {
      _isLoading = true;
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
    _isLoading = true;
    notifyListeners();
    
    try {
      _friendships = await _friendsService.getFriendships(userId);
      
      // Build friend profiles list
      _friends.clear();
      for (var friendship in _friendships) {
        try {
          // Get friend's union ID
          final friendId = friendship.getFriendId(userId);
          
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
        } catch (e) {
          print('Failed to fetch friend $e');
          // Continue with other friends even if one fails
        }
      }
      
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load pending friend requests for current user
  Future<void> loadPendingRequests(String userId) async {
    try {
      _pendingRequests = await _friendsService.getPendingRequests(userId);
      notifyListeners();
    } catch (e) {
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
      await _friendsService.sendFriendRequest(
        fromUserId: fromUserId,
        fromUserName: fromUserName,
        toUserId: targetUnionId,
        toUserName: targetUserName,
      );

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
  
  /// Get leaderboard of friends with lowest handicaps
  /// 
  /// Returns list sorted by currentHandicap (ascending), with top N entries.
  /// Each entry includes rank, name, handicap, and home club.
  List<LeaderboardEntry> getLowestHandicapLeaderboard({int limit = 10}) {
    // Sort friends by currentHandicap (ascending - lowest first)
    final sorted = _friends.toList()
      ..sort((a, b) => a.currentHandicap.compareTo(b.currentHandicap));
    
    // Take top N and create leaderboard entries with ranks
    return sorted.take(limit).toList().asMap().entries.map((entry) {
      final rank = entry.key + 1;
      final friend = entry.value;
      return LeaderboardEntry(
        userId: friend.unionId,
        name: friend.name,
        homeClubName: friend.homeClubName,
        value: friend.currentHandicap,
        rank: rank,
        displayValue: 'HCP ${friend.currentHandicap.toStringAsFixed(1)}',
      );
    }).toList();
  }
  
  /// Get leaderboard of friends with biggest handicap improvement
  /// 
  /// Returns list sorted by delta (most negative = best improvement).
  /// Only includes friends with negative delta (improvement).
  List<LeaderboardEntry> getBiggestImprovementLeaderboard({int limit = 10}) {
    // Filter friends with negative delta (improvement)
    // Sort by delta (most negative = best improvement)
    final improved = _friends
        .where((f) => f.trend.delta != null && f.trend.delta! < 0)
        .toList()
      ..sort((a, b) => a.trend.delta!.compareTo(b.trend.delta!));
    
    return improved.take(limit).toList().asMap().entries.map((entry) {
      final rank = entry.key + 1;
      final friend = entry.value;
      return LeaderboardEntry(
        userId: friend.unionId,
        name: friend.name,
        homeClubName: friend.homeClubName,
        value: friend.trend.delta!,
        rank: rank,
        displayValue: friend.trend.deltaDisplay,
      );
    }).toList();
  }
  
  /// Get leaderboard of best individual scores from all friends
  /// 
  /// Returns list sorted by points (descending - highest first).
  /// Flattens all recent scores from all friends into single ranked list.
  List<LeaderboardEntry> getBestScoresLeaderboard({int limit = 10}) {
    // Flatten all recent scores from all friends
    List<({String userId, String name, String? club, dynamic score})> allScores = [];
    
    for (var friend in _friends) {
      for (var score in friend.recentScores) {
        allScores.add((
          userId: friend.unionId,
          name: friend.name,
          club: friend.homeClubName,
          score: score,
        ));
      }
    }
    
    // Sort by points (descending - highest first)
    allScores.sort((a, b) => b.score.points.compareTo(a.score.points));
    
    return allScores.take(limit).toList().asMap().entries.map((entry) {
      final rank = entry.key + 1;
      final item = entry.value;
      return LeaderboardEntry(
        userId: item.userId,
        name: item.name,
        homeClubName: item.club,
        value: item.score.points.toDouble(),
        rank: rank,
        displayValue: '${item.score.points} points',
        date: item.score.date,
      );
    }).toList();
  }

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

