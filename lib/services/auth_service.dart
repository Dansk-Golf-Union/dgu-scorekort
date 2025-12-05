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
  String getAuthorizationUrl(String codeChallenge) {
    final params = {
      'client_id': AuthConfig.clientId,
      'redirect_uri': AuthConfig.redirectUri,
      'response_type': 'code',
      'scope': AuthConfig.scope,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    };

    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '${AuthConfig.authBaseUrl}/authorize?$queryString';
  }

  /// Exchanges authorization code for access token
  Future<String> exchangeCodeForToken(String code, String codeVerifier) async {
    final url = Uri.parse('${AuthConfig.authBaseUrl}/token');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': AuthConfig.redirectUri,
          'client_id': AuthConfig.clientId,
          'code_verifier': codeVerifier,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['access_token'] as String;
      } else {
        throw Exception(
          'Token exchange failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
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

  /// Clears stored token and verifier (logout)
  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AuthConfig.accessTokenKey);
    await prefs.remove(AuthConfig.codeVerifierKey);
  }

  /// Validates if a token exists and is non-empty
  Future<bool> hasValidToken() async {
    final token = await getStoredToken();
    return token != null && token.isNotEmpty;
  }
}

