import '../models/handicap_trend_model.dart';
import '../models/score_record_model.dart';

/// Composite model for a friend's profile with handicap data
///
/// Combines data from:
/// - GetPlayer API (current handicap, name, club)
/// - WHS Statistik API (score history)
/// - Calculated trends
///
/// Used for displaying friend cards and friend detail views.
class FriendProfile {
  final String unionId;
  final String name;
  final String? homeClubName;
  final double currentHandicap;
  final HandicapTrend trend;
  final List<ScoreRecord> recentScores;
  final DateTime lastUpdated;

  FriendProfile({
    required this.unionId,
    required this.name,
    this.homeClubName,
    required this.currentHandicap,
    required this.trend,
    required this.recentScores,
    required this.lastUpdated,
  });

  /// Get display name (fallback to "Ukendt" if name is empty)
  String get displayName => name.isNotEmpty ? name : 'Ukendt';

  /// Get home club display (fallback to "Ingen klub")
  String get homeClubDisplay => homeClubName ?? 'Ingen klub';

  /// Get handicap display string
  String get handicapDisplay => 'HCP ${currentHandicap.toStringAsFixed(1)}';

  /// Get trend indicator with delta
  String get trendIndicator {
    if (trend.delta == null) return '';
    return '${trend.trendEmoji} ${trend.deltaDisplay}';
  }

  /// Get full trend summary
  String get trendSummary {
    return '$trendIndicator ${trend.trendLabel}';
  }

  /// Get recent scores count
  int get recentScoresCount => recentScores.length;

  /// Check if profile data is fresh (< 1 hour old)
  bool get isFresh {
    final now = DateTime.now();
    return now.difference(lastUpdated).inHours < 1;
  }

  /// Check if profile data is stale (> 24 hours old)
  bool get isStale {
    final now = DateTime.now();
    return now.difference(lastUpdated).inHours > 24;
  }

  @override
  String toString() {
    return 'FriendProfile(name: $name, unionId: $unionId, hcp: $currentHandicap, '
        'trend: ${trend.trendDirection}, scores: ${recentScores.length})';
  }
}

