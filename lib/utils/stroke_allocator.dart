import '../models/course_model.dart';

class StrokeAllocator {
  /// Beregner tildelte slag per hul baseret på spillehandicap
  /// 
  /// Parameters:
  /// - [playingHcp]: Spillerens spillehandicap (fx 16 for 18 huller, 8 for 9 huller)
  /// - [holes]: Liste af huller fra den valgte tee
  /// - [isNineHole]: Om det er en 9-hullers runde
  /// 
  /// Returns: Map<holeNumber, strokesReceived>
  static Map<int, int> calculateStrokesPerHole(
    int playingHcp,
    List<Hole> holes,
    bool isNineHole,
  ) {
    Map<int, int> strokesPerHole = {};

    // Initialize all holes with 0 strokes
    for (final hole in holes) {
      strokesPerHole[hole.number] = 0;
    }

    // If no playing handicap, return all zeros
    if (playingHcp <= 0) {
      return strokesPerHole;
    }

    // Sort holes by their handicap index (1 = hardest, 18 = easiest)
    final sortedHoles = [...holes]..sort((a, b) => a.index.compareTo(b.index));

    // Determine how many holes to distribute over
    final distributionBase = isNineHole ? 9 : 18;
    
    // Calculate how many "rounds" of strokes to give
    // For example: playingHcp 20 on 18 holes = 1 stroke on all + 2 extra on hardest holes
    final fullRounds = playingHcp ~/ distributionBase;
    final remainder = playingHcp % distributionBase;

    // Give full rounds to all holes within distribution base
    for (int i = 0; i < min(sortedHoles.length, distributionBase); i++) {
      strokesPerHole[sortedHoles[i].number] = fullRounds;
    }

    // Distribute remainder strokes to the hardest holes (lowest index)
    for (int i = 0; i < remainder && i < sortedHoles.length; i++) {
      strokesPerHole[sortedHoles[i].number] = 
          (strokesPerHole[sortedHoles[i].number] ?? 0) + 1;
    }

    return strokesPerHole;
  }

  /// Get a textual description of stroke allocation
  static String getStrokeAllocationDescription(
    int playingHcp,
    bool isNineHole,
  ) {
    if (playingHcp <= 0) {
      return 'Ingen tildelte slag (scratch)';
    }

    final base = isNineHole ? 9 : 18;
    final fullRounds = playingHcp ~/ base;
    final remainder = playingHcp % base;

    if (fullRounds == 0) {
      return '$playingHcp slag på de $playingHcp sværeste huller';
    } else if (remainder == 0) {
      return '$fullRounds slag på alle $base huller';
    } else {
      return '$fullRounds slag på alle huller + $remainder ekstra på de sværeste';
    }
  }
}

// Helper function
int min(int a, int b) => a < b ? a : b;


