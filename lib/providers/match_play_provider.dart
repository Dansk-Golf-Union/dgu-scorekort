import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../models/club_model.dart';
import '../models/course_model.dart';
import '../services/player_service.dart';
import '../services/course_cache_service.dart';
import '../utils/handicap_calculator.dart';
import '../utils/stroke_allocator.dart';

class MatchPlayProvider with ChangeNotifier {
  // Players
  Player? _player1; // From AuthProvider (logged in user)
  Player? _player2; // Opponent fetched via DGU number
  
  // Course selection
  Club? _selectedClub;
  GolfCourse? _selectedCourse;
  Tee? _selectedTee;
  
  // Handicaps
  int? _player1PlayingHcp;
  int? _player2PlayingHcp;
  int _handicapDifference = 0;
  Player? _playerWithStrokes; // The player who receives strokes
  
  // Stroke distribution
  Map<int, int> _strokesOnHoles = {}; // hole number -> number of strokes
  
  // Match scoring
  int _currentHole = 1;
  Map<int, String> _holeResults = {}; // hole number -> 'player1', 'player2', 'halved'
  int _matchStatus = 0; // Positive = player1 up, negative = player2 up, 0 = all square
  bool _matchFinished = false;
  String _finalResult = '';
  
  // UI state
  bool _isLoadingOpponent = false;
  String? _opponentError;
  bool _isLoadingClubs = false;
  bool _isLoadingCourses = false;
  String? _clubsError;
  String? _coursesError;
  List<Club> _clubs = [];
  List<GolfCourse> _courses = [];
  
  // Current phase of match play
  MatchPhase _currentPhase = MatchPhase.setup;
  
  // Services
  final PlayerService _playerService = PlayerService();
  final CourseCacheService _cacheService = CourseCacheService();
  
  // Getters
  Player? get player1 => _player1;
  Player? get player2 => _player2;
  Club? get selectedClub => _selectedClub;
  GolfCourse? get selectedCourse => _selectedCourse;
  Tee? get selectedTee => _selectedTee;
  int? get player1PlayingHcp => _player1PlayingHcp;
  int? get player2PlayingHcp => _player2PlayingHcp;
  int get handicapDifference => _handicapDifference;
  Player? get playerWithStrokes => _playerWithStrokes;
  Map<int, int> get strokesOnHoles => _strokesOnHoles;
  int get currentHole => _currentHole;
  Map<int, String> get holeResults => _holeResults;
  int get matchStatus => _matchStatus;
  bool get matchFinished => _matchFinished;
  String get finalResult => _finalResult;
  bool get isLoadingOpponent => _isLoadingOpponent;
  String? get opponentError => _opponentError;
  bool get isLoadingClubs => _isLoadingClubs;
  bool get isLoadingCourses => _isLoadingCourses;
  String? get clubsError => _clubsError;
  String? get coursesError => _coursesError;
  List<Club> get clubs => _clubs;
  List<GolfCourse> get courses => _courses;
  MatchPhase get currentPhase => _currentPhase;
  
  // Computed properties
  bool get canStartMatch => 
      _player1 != null && 
      _player2 != null && 
      _selectedTee != null && 
      _player1PlayingHcp != null && 
      _player2PlayingHcp != null;
  
  bool get canStartScoring => canStartMatch && _currentPhase == MatchPhase.strokeView;
  
  List<Tee> get availableTees {
    if (_selectedCourse == null) return [];
    
    final allTees = _selectedCourse!.tees;
    
    // If no player, show all tees
    if (_player1 == null) return allTees;
    
    // Filter tees by player1's gender (same logic as MatchSetupProvider)
    final matchingTees = allTees
        .where((tee) => tee.gender == _player1!.gender)
        .toList();
    
    // If no matching tees, return all (edge case - let user choose)
    return matchingTees.isNotEmpty ? matchingTees : allTees;
  }
  
  /// Initialize with player 1 from auth
  void setPlayer1(Player player) {
    _player1 = player;
    notifyListeners();
  }
  
  /// Fetch opponent by DGU number
  Future<void> fetchOpponent(String dguNumber) async {
    _isLoadingOpponent = true;
    _opponentError = null;
    notifyListeners();
    
    try {
      final player = await _playerService.fetchPlayerByUnionId(dguNumber);
      _player2 = player;
      _opponentError = null;
    } catch (e) {
      _opponentError = 'Kunne ikke hente spiller: $e';
      _player2 = null;
    } finally {
      _isLoadingOpponent = false;
      notifyListeners();
    }
  }
  
  /// Load clubs from cache or API
  Future<void> loadClubs() async {
    _isLoadingClubs = true;
    _clubsError = null;
    notifyListeners();
    
    try {
      // Try cache first, fallback to API
      _clubs = await _cacheService.fetchCachedClubs();
      _clubsError = null;
    } catch (e) {
      _clubsError = 'Kunne ikke hente klubber: $e';
      _clubs = [];
    } finally {
      _isLoadingClubs = false;
      notifyListeners();
    }
  }
  
  /// Set selected club and load courses
  Future<void> setSelectedClub(Club? club) async {
    _selectedClub = club;
    _selectedCourse = null;
    _selectedTee = null;
    _courses = [];
    
    if (club != null) {
      await _loadCourses(club.id);
    }
    
    notifyListeners();
  }
  
  /// Load courses for selected club
  Future<void> _loadCourses(String clubId) async {
    _isLoadingCourses = true;
    _coursesError = null;
    notifyListeners();
    
    try {
      // Try cache first, fallback to API
      _courses = await _cacheService.fetchCachedCourses(clubId);
      _coursesError = null;
    } catch (e) {
      _coursesError = 'Kunne ikke hente baner: $e';
      _courses = [];
    } finally {
      _isLoadingCourses = false;
      notifyListeners();
    }
  }
  
  /// Set selected course
  void setSelectedCourse(GolfCourse? course) {
    _selectedCourse = course;
    _selectedTee = null;
    _calculateHandicaps();
    notifyListeners();
  }
  
  /// Set selected tee
  void setSelectedTee(Tee? tee) {
    _selectedTee = tee;
    _calculateHandicaps();
    notifyListeners();
  }
  
  /// Calculate playing handicaps and stroke distribution
  void _calculateHandicaps() {
    if (_player1 == null || _player2 == null || _selectedTee == null) {
      _player1PlayingHcp = null;
      _player2PlayingHcp = null;
      _handicapDifference = 0;
      _playerWithStrokes = null;
      _strokesOnHoles = {};
      return;
    }
    
    // Calculate playing handicaps for both players
    _player1PlayingHcp = HandicapCalculator.calculatePlayingHcp(
      _player1!.hcp,
      _selectedTee!,
    );
    
    _player2PlayingHcp = HandicapCalculator.calculatePlayingHcp(
      _player2!.hcp,
      _selectedTee!,
    );
    
    // Calculate difference (always positive)
    _handicapDifference = (_player1PlayingHcp! - _player2PlayingHcp!).abs();
    
    // Determine who gets strokes
    if (_player1PlayingHcp! > _player2PlayingHcp!) {
      _playerWithStrokes = _player1;
    } else if (_player2PlayingHcp! > _player1PlayingHcp!) {
      _playerWithStrokes = _player2;
    } else {
      _playerWithStrokes = null; // Equal handicaps
    }
    
    // Calculate stroke distribution
    _calculateStrokeDistribution();
  }
  
  /// Calculate which holes receive strokes in match play
  void _calculateStrokeDistribution() {
    _strokesOnHoles = {};
    
    if (_selectedTee == null || _handicapDifference == 0) {
      return;
    }
    
    final holes = _selectedTee!.holes ?? [];
    if (holes.isEmpty) return;
    
    // Use StrokeAllocator to calculate match play strokes
    // This handles cases where difference > number of holes
    _strokesOnHoles = StrokeAllocator.calculateMatchPlayStrokes(
      _handicapDifference,
      holes,
    );
  }
  
  /// Start the match (move to stroke view phase)
  void startMatch() {
    if (!canStartMatch) return;
    
    _currentPhase = MatchPhase.strokeView;
    notifyListeners();
  }
  
  /// Start scoring (move to scoring phase)
  void startScoring() {
    if (!canStartScoring) return;
    
    _currentPhase = MatchPhase.scoring;
    _currentHole = 1;
    _holeResults = {};
    _matchStatus = 0;
    _matchFinished = false;
    _finalResult = '';
    notifyListeners();
  }
  
  /// Record hole result
  void recordHoleResult(String result) {
    if (_matchFinished || _currentHole > (_selectedTee?.holes?.length ?? 18)) {
      return;
    }
    
    _holeResults[_currentHole] = result;
    
    // Update match status
    if (result == 'player1') {
      _matchStatus++;
    } else if (result == 'player2') {
      _matchStatus--;
    }
    // 'halved' doesn't change status
    
    // Check if match is finished
    final totalHoles = _selectedTee?.holes?.length ?? 18;
    final holesRemaining = totalHoles - _currentHole;
    
    if (_matchStatus.abs() > holesRemaining) {
      // Match is decided - one player is too far ahead
      _matchFinished = true;
      _finalResult = '${_matchStatus.abs()}/$holesRemaining';
    } else if (_currentHole == totalHoles) {
      // All holes played
      _matchFinished = true;
      if (_matchStatus == 0) {
        _finalResult = 'Match delt';
      } else {
        _finalResult = '${_matchStatus.abs()} hul';
      }
    } else {
      // Continue to next hole
      _currentHole++;
    }
    
    notifyListeners();
  }
  
  /// Undo last hole (if not finished)
  void undoLastHole() {
    if (_currentHole <= 1 || _matchFinished) return;
    
    _currentHole--;
    final lastResult = _holeResults[_currentHole];
    
    if (lastResult == 'player1') {
      _matchStatus--;
    } else if (lastResult == 'player2') {
      _matchStatus++;
    }
    
    _holeResults.remove(_currentHole);
    notifyListeners();
  }
  
  /// Reset match to setup phase
  void resetMatch() {
    _currentPhase = MatchPhase.setup;
    _player2 = null;
    _selectedClub = null;
    _selectedCourse = null;
    _selectedTee = null;
    _player1PlayingHcp = null;
    _player2PlayingHcp = null;
    _handicapDifference = 0;
    _playerWithStrokes = null;
    _strokesOnHoles = {};
    _currentHole = 1;
    _holeResults = {};
    _matchStatus = 0;
    _matchFinished = false;
    _finalResult = '';
    _opponentError = null;
    _courses = [];
    notifyListeners();
  }
  
  /// Get match status string
  String getMatchStatusString() {
    if (_matchStatus == 0) {
      return 'Match lige';
    } else if (_matchStatus > 0) {
      return '${_player1?.name ?? 'Spiller 1'}: $_matchStatus op';
    } else {
      return '${_player2?.name ?? 'Spiller 2'}: ${_matchStatus.abs()} op';
    }
  }
  
  /// Get winner name
  String? getWinnerName() {
    if (!_matchFinished) return null;
    if (_matchStatus == 0) return null; // Draw
    return _matchStatus > 0 ? _player1?.name : _player2?.name;
  }
}

enum MatchPhase {
  setup,
  strokeView,
  scoring,
}

