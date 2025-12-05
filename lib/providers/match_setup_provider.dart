import 'package:flutter/foundation.dart';
import '../models/club_model.dart';
import '../models/course_model.dart';
import '../models/player_model.dart';
import '../services/dgu_service.dart';
import '../utils/handicap_calculator.dart';

class MatchSetupProvider with ChangeNotifier {
  final DguService _dguService = DguService();

  // Player
  Player? _currentPlayer;
  bool _isLoadingPlayer = false;
  String? _playerError;

  // Clubs
  List<Club> _clubs = [];
  bool _isLoadingClubs = false;
  String? _clubsError;

  // Courses
  List<GolfCourse> _courses = [];
  bool _isLoadingCourses = false;
  String? _coursesError;

  // Selections
  Club? _selectedClub;
  GolfCourse? _selectedCourse;
  Tee? _selectedTee;

  // Playing Handicap (calculated)
  int? _playingHandicap;

  // Getters
  Player? get currentPlayer => _currentPlayer;
  bool get isLoadingPlayer => _isLoadingPlayer;
  String? get playerError => _playerError;

  List<Club> get clubs => _clubs;
  bool get isLoadingClubs => _isLoadingClubs;
  String? get clubsError => _clubsError;

  List<GolfCourse> get courses => _courses;
  bool get isLoadingCourses => _isLoadingCourses;
  String? get coursesError => _coursesError;

  Club? get selectedClub => _selectedClub;
  GolfCourse? get selectedCourse => _selectedCourse;
  Tee? get selectedTee => _selectedTee;

  int? get playingHandicap => _playingHandicap;

  bool get canStartRound =>
      _currentPlayer != null &&
      _selectedClub != null &&
      _selectedCourse != null &&
      _selectedTee != null;

  List<Tee> get availableTees => _selectedCourse?.tees ?? [];

  /// Set player from OAuth login
  void setPlayer(Player player) {
    _currentPlayer = player;
    _playerError = null;
    _updatePlayingHandicap();
    notifyListeners();
  }

  /// Load all clubs on app start
  Future<void> loadClubs() async {
    _isLoadingClubs = true;
    _clubsError = null;
    notifyListeners();

    try {
      _clubs = await _dguService.fetchClubs();
      _clubsError = null;
    } catch (e) {
      _clubsError = e.toString();
      _clubs = [];
    } finally {
      _isLoadingClubs = false;
      notifyListeners();
    }
  }

  /// Set selected club and load its courses
  Future<void> setSelectedClub(Club? club) async {
    _selectedClub = club;
    _selectedCourse = null;
    _selectedTee = null;
    _courses = [];
    _coursesError = null;
    notifyListeners();

    if (club != null) {
      await _loadCourses(club.id);
    }
  }

  /// Set selected course and reset tee
  void setSelectedCourse(GolfCourse? course) {
    _selectedCourse = course;
    _selectedTee = null;
    _playingHandicap = null;
    notifyListeners();
  }

  /// Set selected tee and calculate playing handicap
  void setSelectedTee(Tee? tee) {
    _selectedTee = tee;
    _updatePlayingHandicap();
    notifyListeners();
  }

  /// Update playing handicap when tee or player changes
  void _updatePlayingHandicap() {
    if (_currentPlayer != null && _selectedTee != null) {
      _playingHandicap = HandicapCalculator.calculatePlayingHcp(
        _currentPlayer!.hcp,
        _selectedTee!,
      );
    } else {
      _playingHandicap = null;
    }
  }

  /// Private method to load courses for a club
  Future<void> _loadCourses(String clubId) async {
    _isLoadingCourses = true;
    _coursesError = null;
    notifyListeners();

    try {
      _courses = await _dguService.fetchCourses(clubId);
      _coursesError = null;
    } catch (e) {
      _coursesError = e.toString();
      _courses = [];
    } finally {
      _isLoadingCourses = false;
      notifyListeners();
    }
  }

  /// Reset all selections
  void reset() {
    _selectedClub = null;
    _selectedCourse = null;
    _selectedTee = null;
    _courses = [];
    _playingHandicap = null;
    notifyListeners();
  }

  /// Get calculation description for displaying to user
  String? getCalculationDescription() {
    if (_currentPlayer != null && _selectedTee != null && _playingHandicap != null) {
      return HandicapCalculator.getCalculationDescription(
        _currentPlayer!.hcp,
        _selectedTee!,
        _playingHandicap!,
      );
    }
    return null;
  }
}

