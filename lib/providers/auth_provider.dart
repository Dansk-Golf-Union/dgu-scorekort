import 'package:flutter/foundation.dart';
import '../models/player_model.dart';
import '../services/auth_service.dart';
import '../services/player_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final PlayerService _playerService = PlayerService();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _accessToken;
  Player? _currentPlayer;
  String? _errorMessage;
  String? _codeVerifier; // Stored temporarily for token exchange

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get accessToken => _accessToken;
  Player? get currentPlayer => _currentPlayer;
  String? get errorMessage => _errorMessage;

  /// Initialize auth state on app start - check for stored token
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getStoredToken();
      if (token != null && token.isNotEmpty) {
        _accessToken = token;
        // Try to fetch player info with stored token
        await _fetchPlayerInfo(token);
        _isAuthenticated = true;
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      // Token might be expired, clear it
      await _authService.clearAuth();
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start OAuth login flow
  /// Returns the authorization URL to open in browser
  String startLogin() {
    _errorMessage = null;
    
    // Generate PKCE parameters
    _codeVerifier = _authService.generateCodeVerifier();
    final codeChallenge = _authService.generateCodeChallenge(_codeVerifier!);
    
    // Store verifier for later use in token exchange (backup)
    _authService.storeCodeVerifier(_codeVerifier!);
    
    // Return authorization URL (verifier is encoded in state parameter)
    return _authService.getAuthorizationUrl(codeChallenge, _codeVerifier!);
  }

  /// Handle OAuth callback after user returns from login
  Future<void> handleCallback(String authCode, String? state) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Try to get verifier from state parameter first (most reliable on web)
      String? verifier;
      if (state != null && state.isNotEmpty) {
        try {
          verifier = _authService.decodeVerifierFromState(state);
          debugPrint('Code verifier retrieved from state parameter');
        } catch (e) {
          debugPrint('Failed to decode state: $e');
        }
      }
      
      // Fallback to stored verifier if state decode failed
      if (verifier == null) {
        verifier = await _authService.getStoredCodeVerifier();
      }
      
      if (verifier == null) {
        throw Exception('Code verifier not found. Please try logging in again.');
      }

      // Exchange authorization code for access token
      final token = await _authService.exchangeCodeForToken(authCode, verifier);
      _accessToken = token;

      // Store token for future sessions
      await _authService.storeToken(token);

      // Fetch player information
      await _fetchPlayerInfo(token);

      _isAuthenticated = true;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      _isAuthenticated = false;
      debugPrint('Error during OAuth callback: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch player information from API
  Future<void> _fetchPlayerInfo(String token) async {
    try {
      _currentPlayer = await _playerService.fetchPlayerInfo(token);
    } catch (e) {
      debugPrint('Error fetching player info: $e');
      throw Exception('Failed to fetch player information');
    }
  }

  /// Logout and clear all stored data
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.clearAuth();
      _accessToken = null;
      _currentPlayer = null;
      _isAuthenticated = false;
      _errorMessage = null;
      _codeVerifier = null;
    } catch (e) {
      debugPrint('Error during logout: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Login with Union ID (temporary solution without OAuth)
  Future<void> loginWithUnionId(String unionId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch player information directly by Union ID
      _currentPlayer = await _playerService.fetchPlayerByUnionId(unionId);
      
      // Set authenticated (no token needed for this flow)
      _isAuthenticated = true;
      _accessToken = 'simple_login_$unionId'; // Dummy token
      _errorMessage = null;
      
      debugPrint('Simple login successful for Union ID: $unionId');
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isAuthenticated = false;
      _currentPlayer = null;
      debugPrint('Error during simple login: $e');
      rethrow; // Re-throw to let UI handle it
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

