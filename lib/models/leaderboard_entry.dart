/// Represents a single entry in a leaderboard
/// 
/// Used for displaying rankings across different leaderboard types:
/// - Lowest Handicap
/// - Biggest Improvement (negative delta)
/// - Best Scores (highest points)
class LeaderboardEntry {
  final String userId;
  final String name;
  final String? homeClubName;
  final double value; // Handicap, delta, or score points
  final int rank;
  final String displayValue; // Formatted for UI display
  final DateTime? date; // For scores (when was the score achieved)
  
  LeaderboardEntry({
    required this.userId,
    required this.name,
    this.homeClubName,
    required this.value,
    required this.rank,
    required this.displayValue,
    this.date,
  });
  
  /// Get trophy emoji for top 3 positions
  String get trophyEmoji {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }
  
  /// Check if this entry is in top 3
  bool get isTopThree => rank <= 3;
  
  /// Get rank display string (e.g., "#4" for ranks > 3)
  String get rankDisplay {
    return isTopThree ? trophyEmoji : '#$rank';
  }
  
  @override
  String toString() {
    return 'LeaderboardEntry(rank: $rank, name: $name, value: $value)';
  }
}

/// Types of leaderboards available
enum LeaderboardType {
  /// Lowest current handicap among friends
  lowestHandicap,
  
  /// Biggest improvement (most negative delta) over period
  biggestImprovement,
  
  /// Best individual scores (highest points)
  bestScores,
}

/// Extension for LeaderboardType display strings
extension LeaderboardTypeExtension on LeaderboardType {
  String get displayName {
    switch (this) {
      case LeaderboardType.lowestHandicap:
        return 'Laveste HCP';
      case LeaderboardType.biggestImprovement:
        return 'Største Fremgang';
      case LeaderboardType.bestScores:
        return 'Bedste Scores';
    }
  }
  
  String get emptyStateMessage {
    switch (this) {
      case LeaderboardType.lowestHandicap:
        return 'Ingen venner fundet';
      case LeaderboardType.biggestImprovement:
        return 'Ingen forbedringer at vise';
      case LeaderboardType.bestScores:
        return 'Ingen scores fundet';
    }
  }
}

