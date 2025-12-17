import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/auth_config.dart';

class AuthService {
  /// Generates a cryptographically random code verifier for PKCE
  /// Length: 43-128 characters (using 64 for good entropy)
  String generateCodeVerifier() {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(
      64,
      (i) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Generates code challenge from verifier using SHA256 and base64url encoding
  String generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    // Base64url encode (RFC 7636)
    return base64Url
        .encode(digest.bytes)
        .replaceAll('=', ''); // Remove padding
  }

  /// Builds the OAuth authorization URL with PKCE parameters
  /// V2: Encodes BOTH code_verifier AND origin URL in state parameter (JSON format)
  /// for dynamic OAuth redirect in A/B testing scenarios
  String getAuthorizationUrl(String codeChallenge, String codeVerifier) {
    // Get current origin URL (e.g., "https://dgu-alt-design.web.app")
    final originUrl = Uri.base.origin;
    
    // Encode BOTH verifier AND origin in state parameter as JSON
    final stateData = {
      'verifier': codeVerifier,
      'origin': originUrl,
    };
    final stateJson = jsonEncode(stateData);
    final encodedState = base64Url.encode(utf8.encode(stateJson)).replaceAll('=', '');
    
    final params = {
      'client_id': AuthConfig.clientId,
      'redirect_uri': AuthConfig.redirectUri,
      'response_type': 'code',
      'scope': AuthConfig.scope,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'country_iso_code': 'dk',
      'state': encodedState,  // Now contains JSON with verifier + origin
    };

    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '${AuthConfig.authBaseUrl}/connect/authorize?$queryString';
  }
  
  /// Extracts code_verifier from state parameter
  /// V2: Handles both JSON format ({"verifier": "...", "origin": "..."})
  /// and legacy plain string format for backward compatibility
  String decodeVerifierFromState(String state) {
    try {
      // Add padding if needed for base64 decoding
      var paddedState = state;
      while (paddedState.length % 4 != 0) {
        paddedState += '=';
      }
      final decoded = utf8.decode(base64Url.decode(paddedState));
      
      // Try to parse as JSON (V2 format with origin)
      try {
        final stateData = jsonDecode(decoded);
        if (stateData is Map && stateData.containsKey('verifier')) {
          return stateData['verifier'];
        }
      } catch (_) {
        // Not JSON - treat as plain verifier string (legacy format)
      }
      
      // Fallback: return raw decoded string
      return decoded;
    } catch (e) {
      throw Exception('Failed to decode state parameter: $e');
    }
  }

  /// Exchanges authorization code for access token via Cloud Function (CORS proxy)
  /// Using direct HTTP instead of cloud_functions package to avoid Int64 deserialization issues
  Future<String> exchangeCodeForToken(String code, String codeVerifier) async {
    try {
      print('🔄 Calling Cloud Function for token exchange (via HTTP)...');
      print('  Code length: ${code.length}');
      print('  Verifier length: ${codeVerifier.length}');
      
      // Call Cloud Function directly via HTTP POST to avoid cloud_functions SDK Int64 issues
      final url = Uri.parse('https://europe-west1-dgu-scorekort.cloudfunctions.net/exchangeOAuthToken');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'data': {
            'code': code,
            'codeVerifier': codeVerifier,
          }
        }),
      );

      print('✅ Cloud Function response received');
      print('  Status code: ${response.statusCode}');
      print('  Response body: ${response.body}');
      
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
      
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      print('  Parsed JSON keys: ${jsonResponse.keys.toList()}');
      
      // Cloud Function returns data in 'result' field for HTTP calls
      final data = jsonResponse['result'] as Map<String, dynamic>;
      
      if (data['success'] == true && data['access_token'] != null) {
        print('✅ Access token received');
        return data['access_token'] as String;
      } else {
        print('❌ Token exchange failed - response missing success or access_token');
        print('  success: ${data['success']}');
        throw Exception('Token exchange failed: Invalid response from Cloud Function');
      }
    } catch (e, stackTrace) {
      print('❌ Token exchange error: $e');
      print('  Error type: ${e.runtimeType}');
      print('  Stack trace (first 500 chars): ${stackTrace.toString().substring(0, 500)}');
      throw Exception('Failed to exchange code for token: $e');
    }
  }

  /// Stores access token in SharedPreferences
  Future<void> storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AuthConfig.accessTokenKey, token);
  }

  /// Retrieves stored access token from SharedPreferences
  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AuthConfig.accessTokenKey);
  }

  /// Stores code verifier temporarily (needed for token exchange)
  Future<void> storeCodeVerifier(String verifier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AuthConfig.codeVerifierKey, verifier);
  }

  /// Retrieves stored code verifier
  Future<String?> getStoredCodeVerifier() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AuthConfig.codeVerifierKey);
  }

  /// Stores union ID (DGU-nummer) for persistent login
  Future<void> storeUnionId(String unionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AuthConfig.unionIdKey, unionId);
  }

  /// Retrieves stored union ID
  Future<String?> getStoredUnionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AuthConfig.unionIdKey);
  }

  /// Clears stored token, verifier, and unionId (logout)
  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AuthConfig.accessTokenKey);
    await prefs.remove(AuthConfig.codeVerifierKey);
    await prefs.remove(AuthConfig.unionIdKey);
  }

  /// Validates if a token exists and is non-empty
  Future<bool> hasValidToken() async {
    final token = await getStoredToken();
    return token != null && token.isNotEmpty;
  }
}

