import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/score_record_model.dart';

/// Service for fetching WHS scores from DGU Basen Statistik API
/// 
/// Uses same pattern as DguService:
/// - DIFFERENT token from GitHub Gist (Statistik token, not DGU Basen!)
/// - CORS proxy (corsproxy.io)
/// - Direct HTTP calls
/// 
/// API: https://dgubasen.api.union.golfbox.io/statistik/
class WhsStatistikService {
  static const String baseUrl =
      'https://corsproxy.io/?https://dgubasen.api.union.golfbox.io';
  
  // STATISTIK token from GitHub Gist (DIFFERENT from DGU Basen token!)
  static const String _tokenUrl =
      'https://gist.githubusercontent.com/nhuttel/36871c0145d83c3111174b5c87542ee8/raw/17bee0485c5420d473310de8deeaeccd58e3b9cc/statistik%2520token';
  
  // Cache token in memory to avoid fetching on every request
  static String? _cachedToken;
  
  /// Fetches the authentication token from GitHub Gist
  /// Caches the token to avoid repeated fetches
  /// STATISTIK token (different from DGU Basen!)
  /// 
  /// Token format in Gist: "basic [base64-encoded-credentials]"
  /// Converted to HTTP header: "Basic [credentials]"
  Future<String> _getAuthToken() async {
    if (_cachedToken != null) {
      return _cachedToken!;
    }

    try {
      final response = await http.get(Uri.parse(_tokenUrl));
      if (response.statusCode == 200) {
        // Token format from Gist: "basic [base64-encoded-credentials]"
        // Extract and format as "Basic [credentials]"
        final tokenLine = response.body.trim();
        if (tokenLine.toLowerCase().startsWith('basic ')) {
          final credentials = tokenLine.substring(6);
          _cachedToken = 'Basic $credentials';
        } else {
          _cachedToken = tokenLine;
        }
        return _cachedToken!;
      } else {
        throw Exception('Failed to load auth token: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching auth token: $e');
    }
  }
  
  /// Get player's WHS scores from DGU Basen Statistik API
  /// 
  /// Endpoint: /statistik/clubs/{clubId}/Memberships/Scorecards?unionid={unionId}
  /// 
  /// Parameters:
  /// - [unionId]: Player's DGU union ID (e.g., "177-2813")
  /// - [clubId]: Player's home club ID (from Player.homeClubId)
  /// - [limit]: Max number of scores to return (default: 20)
  /// 
  /// Returns: List of ScoreRecord objects, sorted by date (newest first)
  Future<List<ScoreRecord>> getPlayerScores({
    required String unionId,
    required String clubId,
    int limit = 20,
  }) async {
    // Build API URL (same format as DGU Basen API)
    final url = Uri.parse(
      '$baseUrl/statistik/clubs/$clubId/Memberships/Scorecards?unionid=$unionId',
    );
    
    final authToken = await _getAuthToken();
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': authToken,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        
        // Parse scores
        final scores = jsonData
            .map((json) => ScoreRecord.fromJson(json as Map<String, dynamic>))
            .toList();
        
        // Sort by date (newest first)
        scores.sort((a, b) => b.roundDate.compareTo(a.roundDate));
        
        // Apply limit
        return scores.take(limit).toList();
      } else {
        throw Exception('Failed to load scores: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching WHS scores: $e');
    }
  }
}

