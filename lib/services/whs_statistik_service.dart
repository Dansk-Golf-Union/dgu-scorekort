import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/score_record_model.dart';

/// Service for fetching WHS scores from Statistik API
/// 
/// Uses same pattern as DguService:
/// - Token from GitHub Gist
/// - CORS proxy (corsproxy.io)
/// - Direct HTTP calls
/// 
/// API: https://api.danskgolfunion.dk/Statistik/
class WhsStatistikService {
  static const String baseUrl =
      'https://corsproxy.io/?https://api.danskgolfunion.dk';
  
  // Token fetched from GitHub Gist (same as Cloud Function used)
  static const String _tokenUrl =
      'https://gist.githubusercontent.com/nhuttel/36871c0145d83c3111174b5c87542ee8/raw/17bee0485c5420d473310de8deeaeccd58e3b9cc/statistik%2520token';
  
  // Cache token in memory to avoid fetching on every request
  static String? _cachedToken;
  
  /// Fetches the authentication token from GitHub Gist
  /// Caches the token to avoid repeated fetches
  Future<String> _getAuthToken() async {
    if (_cachedToken != null) {
      return _cachedToken!;
    }

    try {
      final response = await http.get(Uri.parse(_tokenUrl));
      if (response.statusCode == 200) {
        // Token format: "basic c3RhdGlzdGlrOk5pY2swMDA3"
        // Extract and format as "Basic <credentials>"
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
  
  /// Get player's WHS scores from Statistik API
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
    // Calculate default date range if not provided
    final from = dateFrom ?? DateTime.now().subtract(const Duration(days: 365));
    final to = dateTo ?? DateTime.now().add(const Duration(days: 1));
    
    // Format dates for API (format: "20240101T000000")
    final fromStr = _formatApiDate(from);
    final toStr = _formatApiDate(to);
    
    // Build API URL
    final url = Uri.parse(
      '$baseUrl/Statistik/GetWHSScores?UnionID=$unionId&RoundDateFrom=$fromStr&RoundDateTo=$toStr',
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
}

