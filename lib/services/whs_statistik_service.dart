import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/score_record_model.dart';

/// Service for fetching WHS scores from Statistik API
/// 
/// API Documentation:
/// - Endpoint: /Statistik/GetWHSScores
/// - Auth: Basic (token from GitHub Gist)
/// - Returns: Array of score records with handicap history
class WhsStatistikService {
  static const String _gistUrl = 
      'https://gist.githubusercontent.com/nhuttel/36871c0145d83c3111174b5c87542ee8/raw/17bee0485c5420d473310de8deeaeccd58e3b9cc/statistik%2520token';
  
  static const String _apiBase = 'https://api.danskgolfunion.dk';
  
  String? _cachedToken;
  
  /// Fetch authentication token from GitHub Gist
  /// 
  /// Format: "basic <base64_credentials>"
  /// Returns: Authorization header value
  Future<String> _fetchToken() async {
    // Return cached token if available
    if (_cachedToken != null) {
      return _cachedToken!;
    }
    
    try {
      final response = await http.get(
        Uri.parse(_gistUrl),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        // Response format: "basic c3RhdGlzdGlrOk5pY2swMDA3"
        final tokenLine = response.body.trim();
        
        // Extract the "Basic <credentials>" part
        if (tokenLine.toLowerCase().startsWith('basic ')) {
          final credentials = tokenLine.substring(6); // Remove "basic "
          _cachedToken = 'Basic $credentials';
          return _cachedToken!;
        }
        
        throw Exception('Invalid token format in Gist');
      } else {
        throw Exception('Failed to fetch token: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Token fetch timeout - check internet connection');
    } catch (e) {
      throw Exception('Failed to fetch Statistik API token: $e');
    }
  }
  
  /// Get player's WHS scores
  /// 
  /// Parameters:
  /// - [unionId]: Player's DGU union ID (e.g., "177-2813")
  /// - [limit]: Max number of scores to return (default: 20)
  /// - [dateFrom]: Optional start date (default: 1 year ago)
  /// - [dateTo]: Optional end date (default: today)
  /// 
  /// Returns: List of ScoreRecord objects, sorted by date (newest first)
  Future<List<ScoreRecord>> getPlayerScores({
    required String unionId,
    int limit = 20,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      // Fetch auth token
      final token = await _fetchToken();
      
      // Calculate default date range if not provided
      final from = dateFrom ?? DateTime.now().subtract(const Duration(days: 365));
      final to = dateTo ?? DateTime.now().add(const Duration(days: 1));
      
      // Format dates for API (format: "20240101T000000")
      final fromStr = _formatApiDate(from);
      final toStr = _formatApiDate(to);
      
      // Build API URL
      final url = Uri.parse('$_apiBase/Statistik/GetWHSScores').replace(
        queryParameters: {
          'UnionID': unionId,
          'RoundDateFrom': fromStr,
          'RoundDateTo': toStr,
        },
      );
      
      // Make API request
      final response = await http.get(
        url,
        headers: {
          'Authorization': token,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
      
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
      } else if (response.statusCode == 401) {
        // Clear cached token and retry once
        _cachedToken = null;
        throw Exception('Unauthorized - invalid token');
      } else {
        throw Exception('API error: ${response.statusCode} - ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Request timeout - check internet connection');
    } catch (e) {
      if (e.toString().contains('Unauthorized')) {
        rethrow;
      }
      throw Exception('Failed to fetch WHS scores: $e');
    }
  }
  
  /// Format DateTime for API (format: "20240101T000000")
  String _formatApiDate(DateTime date) {
    return '${date.year}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}'
        'T'
        '${date.hour.toString().padLeft(2, '0')}'
        '${date.minute.toString().padLeft(2, '0')}'
        '${date.second.toString().padLeft(2, '0')}';
  }
  
  /// Clear cached token (useful for testing or token refresh)
  void clearCache() {
    _cachedToken = null;
  }
}

