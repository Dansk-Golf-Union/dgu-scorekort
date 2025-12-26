import 'package:flutter/foundation.dart';
import '../models/player_model.dart';
import '../services/auth_service.dart';
import '../services/player_service.dart';
import '../utils/web_utils.dart' if (dart.library.io) '../utils/web_utils_stub.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final PlayerService _playerService = PlayerService();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _accessToken;
  Player? _currentPlayer;
  String? _errorMessage;
  String? _codeVerifier; // Stored temporarily for token exchange
  bool _needsUnionId = false; // After OAuth, waiting for DGU-nummer input

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get accessToken => _accessToken;
  Player? get currentPlayer => _currentPlayer;
  String? get errorMessage => _errorMessage;
  bool get needsUnionId => _needsUnionId;

  /// Initialize auth state on app start - check for stored token and unionId
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getStoredToken();
      final unionId = await _authService.getStoredUnionId();
      
      // Only auto-login if we have both token AND unionId
      if (token != null && token.isNotEmpty && unionId != null && unionId.isNotEmpty) {
        _accessToken = token;
        // Use Basic Auth flow with stored unionId for persistent login
        await loginWithUnionIdAfterOAuth(unionId);
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      // Token/unionId might be expired/invalid, clear it
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

      // Don't fetch player info yet - wait for DGU-nummer input
      _isAuthenticated = false;
      _needsUnionId = true; // Trigger DGU-nummer input UI
      _errorMessage = null;
      
      debugPrint('✅ OAuth token stored, waiting for DGU-nummer input');
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      _isAuthenticated = false;
      debugPrint('Error during OAuth callback: $e');
    } finally {
      // ALWAYS clean URL parameters (prevents code reuse on refresh, even after errors)
      if (kIsWeb) {
        try {
          cleanUrlParams();
          debugPrint('✅ Cleaned OAuth parameters from URL');
        } catch (e) {
          debugPrint('⚠️ Failed to clean URL: $e');
        }
      }
      
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login with DGU-nummer after OAuth success
  /// Uses existing Basic Auth flow with fetchPlayerByUnionId
  Future<void> loginWithUnionIdAfterOAuth(String unionId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Use existing Basic Auth flow
      _currentPlayer = await _playerService.fetchPlayerByUnionId(unionId);
      
      // Store unionId for persistent login
      await _authService.storeUnionId(unionId);
      
      _isAuthenticated = true;
      _needsUnionId = false;
      _errorMessage = null;
      
      debugPrint('✅ Login successful with DGU-nummer: $unionId');
    } catch (e) {
      _errorMessage = 'Kunne ikke hente spiller info: $e';
      _isAuthenticated = false;
      debugPrint('❌ Error fetching player by unionId: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout and clear all stored data
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.clearAuth(); // Clears token + verifier + unionId
      _accessToken = null;
      _currentPlayer = null;
      _isAuthenticated = false;
      _needsUnionId = false;
      _errorMessage = null;
      _codeVerifier = null;
      
      debugPrint('✅ Logout successful');
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

