import '../models/course_model.dart';

class HandicapCalculator {
  /// Calculates Playing Handicap according to Danish golf rules
  /// 
  /// Formula: Playing HCP = (HandicapIndex * (SlopeRating / 113)) + (CourseRating - Par)
  /// For 9-hole courses: Use half the handicap index
  /// 
  /// Parameters:
  /// - [hcp]: Player's handicap index (e.g., 14.5)
  /// - [tee]: The selected tee containing CourseRating and SlopeRating
  /// 
  /// Returns: Playing handicap rounded to nearest integer
  static int calculatePlayingHcp(double hcp, Tee tee) {
    // Get par for the course
    int par = _calculatePar(tee);

    // For 9-hole courses: divide by 2 and round to one decimal (WHS rule)
    final adjustedHcp = tee.isNineHole 
        ? _roundToOneDecimal(hcp / 2) 
        : hcp;

    // Danish formula: Playing HCP = (HCP Index * (Slope / 113)) + (CR - Par)
    final slopeAdjustment = adjustedHcp * (tee.slopeRating / 113.0);
    final courseAdjustment = tee.courseRating - par;
    final playingHcp = slopeAdjustment + courseAdjustment;

    // Round to nearest integer (0.5 rounds up)
    return playingHcp.round();
  }

  /// Calculate par for the tee
  /// If holes are available in the tee, sum their pars
  /// Otherwise, estimate based on number of holes (72 for 18, 36 for 9)
  static int _calculatePar(Tee tee) {
    // Try to get par from holes if available
    if (tee.holes != null && tee.holes!.isNotEmpty) {
      return tee.holes!.fold<int>(0, (sum, hole) => sum + hole.par);
    }

    // Fallback: estimate based on whether it's 9 or 18 holes
    // Check if it's a 9-hole course (IsNineHole flag would be ideal, but we'll check hole count)
    final holeCount = tee.holes?.length ?? 18;
    return holeCount <= 9 ? 36 : 72;
  }

  /// Round a value to one decimal place
  /// Used for 9-hole handicap calculation per WHS rules
  static double _roundToOneDecimal(double value) {
    return (value * 10).round() / 10;
  }

  /// Get a description of how the playing handicap was calculated
  static String getCalculationDescription(double hcp, Tee tee, int playingHcp) {
    final par = _calculatePar(tee);
    
    // For 9-hole courses: divide by 2 and round to one decimal (WHS rule)
    final adjustedHcp = tee.isNineHole 
        ? _roundToOneDecimal(hcp / 2) 
        : hcp;
    final slopeAdjustment = adjustedHcp * (tee.slopeRating / 113.0);
    final courseAdjustment = tee.courseRating - par;
    final exactResult = slopeAdjustment + courseAdjustment;

    final nineHoleNote = tee.isNineHole 
        ? ' (${hcp}/2 = ${(hcp/2).toStringAsFixed(2)} → ${adjustedHcp.toStringAsFixed(1)} afrundet)'
        : '';

    return 'Beregning:\n'
        '($adjustedHcp$nineHoleNote × ${tee.slopeRating}/113) + (${tee.courseRating.toStringAsFixed(1)} - $par) = ${exactResult.toStringAsFixed(1)} ≈ $playingHcp\n'
        '\n'
        'Forklaring:\n'
        '• Dit handicap: $hcp${tee.isNineHole ? ' → ${(hcp/2).toStringAsFixed(2)} → ${adjustedHcp.toStringAsFixed(1)} (9 huller, afrundet)' : ''}\n'
        '• Banens slope: ${tee.slopeRating}\n'
        '• Course Rating: ${tee.courseRating.toStringAsFixed(1)}\n'
        '• Par: $par\n'
        '• Resultat: $playingHcp slag (afrundet)';
  }
}

