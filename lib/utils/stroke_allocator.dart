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

  /// Beregner slag fordeling for match play (hulspil)
  /// 
  /// I match play fordeles kun FORSKELLEN mellem de to spilleres handicap.
  /// Spilleren med lavest handicap får 0 slag, modstanderen får slag på 
  /// handicap-nøglerne 1 til difference.
  /// 
  /// Hvis forskellen er større end antal huller (fx 20 på 18 huller),
  /// starter fordelingen forfra fra index 1. Så index 1-2 får 2 slag,
  /// index 3-18 får 1 slag.
  /// 
  /// Parameters:
  /// - [handicapDifference]: Forskel mellem de to spilleres spillehandicap
  /// - [holes]: Liste af huller fra den valgte tee
  /// 
  /// Returns: Map<holeNumber, strokesPerHole> - antal slag på hver hul
  static Map<int, int> calculateMatchPlayStrokes(
    int handicapDifference,
    List<Hole> holes,
  ) {
    Map<int, int> strokesOnHoles = {};

    // Initialize all holes with 0 strokes
    for (final hole in holes) {
      strokesOnHoles[hole.number] = 0;
    }

    // If no difference, no strokes to allocate
    if (handicapDifference <= 0) {
      return strokesOnHoles;
    }

    // Sort holes by their handicap index (1 = hardest, 18 = easiest)
    final sortedHoles = [...holes]..sort((a, b) => a.index.compareTo(b.index));

    final numHoles = sortedHoles.length;
    
    // Calculate how many "rounds" of strokes to distribute
    // For example: 20 difference on 18 holes = 1 stroke on all + 2 extra on index 1-2
    final fullRounds = handicapDifference ~/ numHoles;
    final remainder = handicapDifference % numHoles;

    // Give full rounds to all holes
    if (fullRounds > 0) {
      for (final hole in sortedHoles) {
        strokesOnHoles[hole.number] = fullRounds;
      }
    }

    // Distribute remainder strokes to the hardest holes (lowest index)
    for (int i = 0; i < remainder && i < sortedHoles.length; i++) {
      strokesOnHoles[sortedHoles[i].number] = 
          (strokesOnHoles[sortedHoles[i].number] ?? 0) + 1;
    }

    return strokesOnHoles;
  }

  /// Get description of match play stroke allocation
  static String getMatchPlayStrokeDescription(
    int handicapDifference,
    String playerName,
    bool isNineHole,
  ) {
    if (handicapDifference == 0) {
      return 'Ingen slag - begge spillere har samme spillehandicap';
    }

    final maxHoles = isNineHole ? 9 : 18;
    final fullRounds = handicapDifference ~/ maxHoles;
    final remainder = handicapDifference % maxHoles;

    if (fullRounds == 0) {
      // Less than full round: e.g., 8 strokes on 18 holes
      return '$playerName får $handicapDifference slag ekstra på handicap-nøglerne 1-$handicapDifference';
    } else if (remainder == 0) {
      // Exact multiple: e.g., 18 strokes on 18 holes
      return '$playerName får $fullRounds slag ekstra på alle $maxHoles huller';
    } else {
      // Multiple rounds + remainder: e.g., 20 strokes = 1 on all + 2 extra on index 1-2
      return '$playerName får $fullRounds slag ekstra på alle huller + ${fullRounds + 1} slag ekstra på nøgle 1-$remainder';
    }
  }
}

// Helper function
int min(int a, int b) => a < b ? a : b;


