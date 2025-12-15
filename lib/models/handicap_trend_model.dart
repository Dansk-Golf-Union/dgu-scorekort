import '../models/score_record_model.dart';

/// Data point for handicap trend graph
class HandicapDataPoint {
  final DateTime date;
  final double handicap;

  HandicapDataPoint({
    required this.date,
    required this.handicap,
  });

  @override
  String toString() => 'HandicapDataPoint(date: $date, hcp: $handicap)';
}

/// Model for analyzing a player's handicap trend over time
///
/// Calculates deltas, improvement rates, and provides data for trend graphs.
/// All calculations are based on WHS Statistik API score history.
class HandicapTrend {
  final double currentHcp;
  final double? previousHcp; // From last score
  final double? delta; // current - previous (negative = improving)
  final double? bestHcp; // Lowest HCP in history
  final double? deltaFromBest; // current - best
  final int totalRounds;
  final String trendDirection; // 'improving', 'worsening', 'stable'
  final double? improvementRate; // HCP change per month (negative = improving)
  final List<HandicapDataPoint> historyPoints; // For graph

  HandicapTrend({
    required this.currentHcp,
    this.previousHcp,
    this.delta,
    this.bestHcp,
    this.deltaFromBest,
    required this.totalRounds,
    required this.trendDirection,
    this.improvementRate,
    required this.historyPoints,
  });

  /// Calculate trend from score history and current handicap
  ///
  /// [currentHcp] - Current handicap from GetPlayer API
  /// [scores] - List of ScoreRecord from WHS API (sorted by date, newest first)
  /// [periodMonths] - Period to analyze (default: 6 months)
  factory HandicapTrend.fromScores({
    required double currentHcp,
    required List<ScoreRecord> scores,
    int periodMonths = 6,
  }) {
    if (scores.isEmpty) {
      return HandicapTrend(
        currentHcp: currentHcp,
        totalRounds: 0,
        trendDirection: 'stable',
        historyPoints: [],
      );
    }

    // Filter scores by period
    final cutoffDate = DateTime.now().subtract(Duration(days: periodMonths * 30));
    final periodScores = scores
        .where((s) => s.roundDate.isAfter(cutoffDate))
        .toList();

    // 1. Previous Handicap (from most recent score)
    final previousHcp = scores.first.handicapBefore;

    // 2. Delta (current - previous)
    final delta = currentHcp - previousHcp;

    // 3. Best Handicap (lowest in ALL history)
    final bestHcp = scores
        .map((s) => s.handicapBefore)
        .reduce((a, b) => a < b ? a : b);

    // 4. Delta from Best
    final deltaFromBest = currentHcp - bestHcp;

    // 5. Trend Direction
    String trendDirection = 'stable';
    if (delta < -0.5) {
      trendDirection = 'improving';
    } else if (delta > 0.5) {
      trendDirection = 'worsening';
    }

    // 6. Improvement Rate (per month) over period
    double? improvementRate;
    if (periodScores.length >= 2) {
      final oldestScore = periodScores.last;
      final newestScore = periodScores.first;
      final daysDiff = newestScore.roundDate.difference(oldestScore.roundDate).inDays;
      if (daysDiff > 0) {
        final hcpChange = oldestScore.handicapBefore - newestScore.handicapBefore;
        improvementRate = (hcpChange / daysDiff) * 30; // Per month
      }
    }

    // 7. History Data Points (for chart)
    final historyPoints = periodScores
        .map((score) => HandicapDataPoint(
              date: score.roundDate,
              handicap: score.handicapBefore,
            ))
        .toList()
        .reversed // Oldest first for chart
        .toList();

    return HandicapTrend(
      currentHcp: currentHcp,
      previousHcp: previousHcp,
      delta: delta,
      bestHcp: bestHcp,
      deltaFromBest: deltaFromBest,
      totalRounds: scores.length,
      trendDirection: trendDirection,
      improvementRate: improvementRate,
      historyPoints: historyPoints,
    );
  }

  /// Get trend emoji for display
  String get trendEmoji {
    switch (trendDirection) {
      case 'improving':
        return '📉';
      case 'worsening':
        return '📈';
      default:
        return '➡️';
    }
  }

  /// Get trend label (Danish)
  String get trendLabel {
    switch (trendDirection) {
      case 'improving':
        return 'Forbedret';
      case 'worsening':
        return 'Forværret';
      default:
        return 'Stabil';
    }
  }

  /// Get delta display string (with sign and color indicator)
  String get deltaDisplay {
    if (delta == null) return '';
    final sign = delta! >= 0 ? '+' : '';
    return '$sign${delta!.toStringAsFixed(1)}';
  }

  /// Get improvement rate display string
  String get improvementRateDisplay {
    if (improvementRate == null) return 'Ingen data';
    final sign = improvementRate! >= 0 ? '+' : '';
    return '$sign${improvementRate!.toStringAsFixed(1)} HCP/måned';
  }

  /// Get best handicap display string
  String get bestHcpDisplay {
    if (bestHcp == null) return 'Ingen data';
    return bestHcp!.toStringAsFixed(1);
  }

  /// Get delta from best display string
  String get deltaFromBestDisplay {
    if (deltaFromBest == null) return '';
    final sign = deltaFromBest! >= 0 ? '+' : '';
    return '$sign${deltaFromBest!.toStringAsFixed(1)} fra bedste';
  }

  /// Check if trend is positive (improving)
  bool get isImproving => trendDirection == 'improving';

  /// Check if trend is negative (worsening)
  bool get isWorsening => trendDirection == 'worsening';

  @override
  String toString() {
    return 'HandicapTrend(current: $currentHcp, delta: $deltaDisplay, '
        'direction: $trendDirection, rounds: $totalRounds)';
  }
}

