/// Model for Birdie Bonus data
/// 
/// Tracks a player's birdie count and ranking position in the Birdie Bonus competition.
/// Supports both mock data (for development) and API integration (for production).
class BirdieBonusData {
  /// Number of birdies the player has scored
  final int birdieCount;
  
  /// Player's current position on the leaderboard
  final int rankingPosition;
  
  /// Whether the player is actively participating in Birdie Bonus
  final bool isParticipant;
  
  /// Player's DGU union ID
  final String? unionId;

  const BirdieBonusData({
    required this.birdieCount,
    required this.rankingPosition,
    this.isParticipant = false,
    this.unionId,
  });

  /// Factory for mock data during development
  /// 
  /// Returns sample data based on Mit Golf screenshot:
  /// - 294 birdies (🐦 icon)
  /// - Position 125 (🏆 icon)
  factory BirdieBonusData.mock({String? unionId}) {
    return BirdieBonusData(
      birdieCount: 294,
      rankingPosition: 125,
      isParticipant: true,
      unionId: unionId,
    );
  }

  /// Factory for non-participant (empty state)
  factory BirdieBonusData.notParticipant({String? unionId}) {
    return BirdieBonusData(
      birdieCount: 0,
      rankingPosition: 0,
      isParticipant: false,
      unionId: unionId,
    );
  }

  /// Factory for API response
  /// 
  /// Expected API structure from GolfBox description:
  /// ```json
  /// {
  ///   "BB_participant": 2,
  ///   "dgUNumber": "147-3270",
  ///   "BirdieBonusPoints": 294,
  ///   "regionLabel": "Sjælland",
  ///   "hcpGroupLabel": "11.5-18.4",
  ///   "rankInRegionGroup": 125
  /// }
  /// ```
  factory BirdieBonusData.fromJson(Map<String, dynamic> json) {
    return BirdieBonusData(
      birdieCount: json['BirdieBonusPoints'] as int? ?? 0,
      rankingPosition: json['rankInRegionGroup'] as int? ?? 0,
      isParticipant: (json['BB_participant'] as int?) == 2,
      unionId: json['dgUNumber'] as String?,
    );
  }

  /// Convert to JSON format for API submission (if needed)
  Map<String, dynamic> toJson() {
    return {
      'BirdieBonusPoints': birdieCount,
      'rankInRegionGroup': rankingPosition,
      'BB_participant': isParticipant ? 2 : 0,
      'dgUNumber': unionId,
    };
  }

  @override
  String toString() {
    return 'BirdieBonusData(birdies: $birdieCount, rank: $rankingPosition, participant: $isParticipant)';
  }
}

