import 'package:flutter/foundation.dart';
import '../models/scorecard_model.dart';
import '../models/course_model.dart';
import '../models/player_model.dart';
import '../utils/stroke_allocator.dart';

class ScorecardProvider with ChangeNotifier {
  Scorecard? _currentScorecard;
  int _currentHoleIndex = 0;

  // Getters
  Scorecard? get scorecard => _currentScorecard;
  int get currentHoleIndex => _currentHoleIndex;
  
  HoleScore? get currentHole {
    if (_currentScorecard == null || 
        _currentHoleIndex >= _currentScorecard!.holeScores.length) {
      return null;
    }
    return _currentScorecard!.holeScores[_currentHoleIndex];
  }

  bool get isRoundComplete {
    return _currentScorecard?.isComplete ?? false;
  }

  bool get canGoNext {
    return _currentScorecard != null && 
           _currentHoleIndex < _currentScorecard!.holeScores.length - 1;
  }

  bool get canGoPrevious {
    return _currentHoleIndex > 0;
  }

  /// Start a new round
  void startRound(
    GolfCourse course,
    Tee tee,
    Player player,
    int playingHcp,
  ) {
    // Get holes from the tee
    final holes = tee.holes ?? course.holes;

    if (holes.isEmpty) {
      throw Exception('No holes available for this course/tee');
    }

    // Calculate stroke allocation
    final strokesPerHole = StrokeAllocator.calculateStrokesPerHole(
      playingHcp,
      holes,
      tee.isNineHole,
    );

    // Create hole scores
    final holeScores = holes.map((hole) {
      return HoleScore(
        holeNumber: hole.number,
        par: hole.par,
        index: hole.index,
        strokesReceived: strokesPerHole[hole.number] ?? 0,
      );
    }).toList();

    // Sort by hole number
    holeScores.sort((a, b) => a.holeNumber.compareTo(b.holeNumber));

    // Create scorecard
    _currentScorecard = Scorecard(
      course: course,
      tee: tee,
      player: player,
      playingHandicap: playingHcp,
      holeScores: holeScores,
      startTime: DateTime.now(),
    );

    _currentHoleIndex = 0;
    notifyListeners();
  }

  /// Set score for a specific hole
  void setScore(int holeNumber, int strokes) {
    if (_currentScorecard == null) return;

    final holeIndex = _currentScorecard!.holeScores
        .indexWhere((h) => h.holeNumber == holeNumber);

    if (holeIndex == -1) return;

    final updatedHoleScores = List<HoleScore>.from(_currentScorecard!.holeScores);
    updatedHoleScores[holeIndex] = updatedHoleScores[holeIndex].copyWith(
      strokes: strokes,
    );

    _currentScorecard = _currentScorecard!.copyWith(
      holeScores: updatedHoleScores,
    );

    notifyListeners();
  }

  /// Set putts for a specific hole
  void setPutts(int holeNumber, int putts) {
    if (_currentScorecard == null) return;

    final holeIndex = _currentScorecard!.holeScores
        .indexWhere((h) => h.holeNumber == holeNumber);

    if (holeIndex == -1) return;

    final updatedHoleScores = List<HoleScore>.from(_currentScorecard!.holeScores);
    updatedHoleScores[holeIndex] = updatedHoleScores[holeIndex].copyWith(
      putts: putts,
    );

    _currentScorecard = _currentScorecard!.copyWith(
      holeScores: updatedHoleScores,
    );

    notifyListeners();
  }

  /// Navigate to next hole
  void nextHole() {
    if (canGoNext) {
      _currentHoleIndex++;
      notifyListeners();
    }
  }

  /// Navigate to previous hole
  void previousHole() {
    if (canGoPrevious) {
      _currentHoleIndex--;
      notifyListeners();
    }
  }

  /// Jump to specific hole
  void goToHole(int index) {
    if (_currentScorecard != null && 
        index >= 0 && 
        index < _currentScorecard!.holeScores.length) {
      _currentHoleIndex = index;
      notifyListeners();
    }
  }

  /// Finish the round
  void finishRound() {
    if (_currentScorecard == null) return;

    _currentScorecard = _currentScorecard!.copyWith(
      endTime: DateTime.now(),
    );

    notifyListeners();
  }

  /// Reset/clear current scorecard
  void clearScorecard() {
    _currentScorecard = null;
    _currentHoleIndex = 0;
    notifyListeners();
  }

  /// Set marker information
  void setMarkerInfo({
    required String fullName,
    required String unionId,
    String? lifetimeId,
    String? homeClubName,
    required String signature,
  }) {
    if (_currentScorecard == null) return;

    _currentScorecard = _currentScorecard!.copyWith(
      markerFullName: fullName,
      markerUnionId: unionId,
      markerLifetimeId: lifetimeId,
      markerHomeClubName: homeClubName,
      markerSignature: signature,
      markerApprovedAt: DateTime.now(),
    );

    notifyListeners();
  }

  /// Clear marker information
  void clearMarkerInfo() {
    if (_currentScorecard == null) return;

    _currentScorecard = _currentScorecard!.copyWith(
      markerFullName: null,
      markerUnionId: null,
      markerLifetimeId: null,
      markerHomeClubName: null,
      markerSignature: null,
      markerApprovedAt: null,
    );

    notifyListeners();
  }

  /// Submit scorecard to DGU API
  /// Returns true if submission was successful
  Future<bool> submitScorecard() async {
    if (_currentScorecard == null) {
      throw Exception('No scorecard to submit');
    }

    if (!_currentScorecard!.canSubmit) {
      throw Exception('Scorecard cannot be submitted - marker not approved or already submitted');
    }

    // TODO: Implement POST to DGU ScorecardExchange API
    // For now, just mark as submitted
    _currentScorecard = _currentScorecard!.copyWith(
      isSubmitted: true,
      submittedAt: DateTime.now(),
      submissionResponse: 'Success (mock)', // Placeholder
    );

    notifyListeners();
    return true;
  }
}


