import 'dart:math';
import 'course_model.dart';
import 'player_model.dart';

class HoleScore {
  final int holeNumber;
  final int par;
  final int index;
  final int strokesReceived; // Tildelte slag
  int? strokes; // Faktiske slag (null = ikke spillet endnu)
  int? putts;
  bool isPickedUp; // Om bolden blev samlet op (netto dobbelt bogey)

  HoleScore({
    required this.holeNumber,
    required this.par,
    required this.index,
    required this.strokesReceived,
    this.strokes,
    this.putts,
    this.isPickedUp = false,
  });

  /// Calculate Stableford points for this hole
  /// Formula: Point = Par + Tildelte slag - Score + 2 (minimum 0)
  int get stablefordPoints {
    if (strokes == null) return 0;
    final points = par + strokesReceived - strokes! + 2;
    return max(0, points);
  }

  /// Get net score (after handicap strokes)
  int? get netScore {
    if (strokes == null) return null;
    return strokes! - strokesReceived;
  }

  /// Get score relative to par (for display)
  /// Returns: -2 for eagle, -1 for birdie, 0 for par, +1 for bogey, etc.
  int? get relativeToPar {
    final net = netScore;
    if (net == null) return null;
    return net - par;
  }

  /// Copy with updated values
  HoleScore copyWith({
    int? strokes,
    int? putts,
    bool? isPickedUp,
  }) {
    return HoleScore(
      holeNumber: holeNumber,
      par: par,
      index: index,
      strokesReceived: strokesReceived,
      strokes: strokes ?? this.strokes,
      putts: putts ?? this.putts,
      isPickedUp: isPickedUp ?? this.isPickedUp,
    );
  }
}

class Scorecard {
  final GolfCourse course;
  final Tee tee;
  final Player player;
  final int playingHandicap;
  final List<HoleScore> holeScores;
  final DateTime startTime;
  DateTime? endTime;
  
  // Marker information
  String? markerFullName;
  String? markerUnionId;
  String? markerLifetimeId;
  String? markerHomeClubName;
  DateTime? markerApprovedAt;
  String? markerSignature; // base64 encoded PNG
  
  // Submission tracking
  bool isSubmitted;
  DateTime? submittedAt;
  String? submissionResponse;

  Scorecard({
    required this.course,
    required this.tee,
    required this.player,
    required this.playingHandicap,
    required this.holeScores,
    required this.startTime,
    this.endTime,
    this.markerFullName,
    this.markerUnionId,
    this.markerLifetimeId,
    this.markerHomeClubName,
    this.markerApprovedAt,
    this.markerSignature,
    this.isSubmitted = false,
    this.submittedAt,
    this.submissionResponse,
  });

  /// Total strokes played (brutto)
  int get totalStrokes {
    return holeScores
        .where((h) => h.strokes != null)
        .fold<int>(0, (sum, h) => sum + h.strokes!);
  }

  /// Total Stableford points
  int get totalPoints {
    return holeScores.fold<int>(0, (sum, h) => sum + h.stablefordPoints);
  }

  /// Total net score
  int get totalNetScore {
    return holeScores
        .where((h) => h.netScore != null)
        .fold<int>(0, (sum, h) => sum + h.netScore!);
  }

  /// Number of holes completed
  int get holesCompleted {
    return holeScores.where((h) => h.strokes != null).length;
  }

  /// Check if round is complete
  bool get isComplete {
    return holesCompleted == holeScores.length;
  }
  
  /// Check if marker is approved
  bool get isMarkerApproved {
    return markerFullName != null && 
           markerUnionId != null && 
           markerSignature != null;
  }
  
  /// Check if scorecard can be submitted
  bool get canSubmit {
    return isMarkerApproved && !isSubmitted;
  }

  /// Get front 9 score (holes 1-9)
  int get front9Points {
    return holeScores
        .where((h) => h.holeNumber <= 9)
        .fold<int>(0, (sum, h) => sum + h.stablefordPoints);
  }

  /// Get back 9 score (holes 10-18)
  int get back9Points {
    return holeScores
        .where((h) => h.holeNumber > 9)
        .fold<int>(0, (sum, h) => sum + h.stablefordPoints);
  }

  /// Calculate adjusted gross score with net double bogey cap
  /// Used for handicap calculation according to WHS rules
  int get adjustedGrossScore {
    int total = 0;
    
    for (var hole in holeScores) {
      // Net double bogey for this hole = par + strokes received + 2
      final netDoubleBogey = hole.par + hole.strokesReceived + 2;
      
      // Determine adjusted score for this hole
      int adjustedScore;
      
      if (hole.strokes == null) {
        // No score recorded: use net double bogey
        adjustedScore = netDoubleBogey;
      } else if (hole.strokes! > netDoubleBogey) {
        // Score exceeds net double bogey: cap it
        adjustedScore = netDoubleBogey;
      } else {
        // Score within limit: use actual score
        adjustedScore = hole.strokes!;
      }
      
      total += adjustedScore;
    }
    
    return total;
  }

  /// Calculate handicap result (score differential) using adjusted gross score
  /// Returns null if round is not complete or required tee data is missing
  double? get handicapResult {
    // Require complete round
    if (!isComplete) return null;
    
    // Need slope and course rating from tee
    final slope = tee.slopeRating;
    final courseRating = tee.courseRating;
    
    // Slope rating of 0 is invalid, treat as null
    if (slope == 0 || courseRating == 0) return null;
    
    final pcc = 0.0; // PCC adjustment (default 0, ranges -1.0 to +3.0)
    final adjustedScore = adjustedGrossScore.toDouble();
    final isNineHole = holeScores.length == 9;
    
    double result;
    
    if (isNineHole) {
      // 9-hole formula
      result = (113 / slope) * (adjustedScore - courseRating - (0.5 * pcc));
    } else {
      // 18-hole formula
      result = (113 / slope) * (adjustedScore - courseRating - pcc);
    }
    
    // Round according to WHS rules
    return _roundHandicapResult(result);
  }

  /// Round handicap result according to WHS rules
  /// - Positive values: round to nearest 0.1, where 0.5 rounds up
  /// - Negative values: round UP towards 0
  double _roundHandicapResult(double value) {
    if (value >= 0) {
      // Positive: normal rounding to nearest 0.1, 0.5 rounds up
      return (value * 10).round() / 10;
    } else {
      // Negative: round UP towards 0
      // -1.54 → -1.5, -1.55 → -1.5, -1.56 → -1.6
      return (value * 10).ceil() / 10;
    }
  }

  /// Copy with updated values
  Scorecard copyWith({
    List<HoleScore>? holeScores,
    DateTime? endTime,
    String? markerFullName,
    String? markerUnionId,
    String? markerLifetimeId,
    String? markerHomeClubName,
    DateTime? markerApprovedAt,
    String? markerSignature,
    bool? isSubmitted,
    DateTime? submittedAt,
    String? submissionResponse,
  }) {
    return Scorecard(
      course: course,
      tee: tee,
      player: player,
      playingHandicap: playingHandicap,
      holeScores: holeScores ?? this.holeScores,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      markerFullName: markerFullName ?? this.markerFullName,
      markerUnionId: markerUnionId ?? this.markerUnionId,
      markerLifetimeId: markerLifetimeId ?? this.markerLifetimeId,
      markerHomeClubName: markerHomeClubName ?? this.markerHomeClubName,
      markerApprovedAt: markerApprovedAt ?? this.markerApprovedAt,
      markerSignature: markerSignature ?? this.markerSignature,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      submittedAt: submittedAt ?? this.submittedAt,
      submissionResponse: submissionResponse ?? this.submissionResponse,
    );
  }
}

