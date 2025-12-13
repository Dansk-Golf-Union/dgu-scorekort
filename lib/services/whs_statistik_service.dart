import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/score_record_model.dart';

/// Service for fetching WHS scores via Firebase Cloud Function
/// 
/// Uses Cloud Function as CORS proxy to avoid browser restrictions.
/// Cloud Function fetches token from GitHub Gist and calls WHS API.
/// 
/// Cloud Function: getWhsScores (europe-west1)
class WhsStatistikService {
  final _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
  
  /// Get player's WHS scores via Cloud Function (CORS proxy)
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
      // Calculate default date range if not provided
      final from = dateFrom ?? DateTime.now().subtract(const Duration(days: 365));
      final to = dateTo ?? DateTime.now().add(const Duration(days: 1));
      
      // Format dates for API (format: "20240101T000000")
      final fromStr = _formatApiDate(from);
      final toStr = _formatApiDate(to);
      
      // Call Cloud Function
      final callable = _functions.httpsCallable('getWhsScores');
      final result = await callable.call({
        'unionId': unionId,
        'limit': limit,
        'dateFrom': fromStr,
        'dateTo': toStr,
      });
      
      // Parse response
      final data = result.data as Map<String, dynamic>;
      final scoresJson = data['scores'] as List<dynamic>;
      
      // Convert to ScoreRecord objects
      final scores = scoresJson
          .map((json) => ScoreRecord.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return scores;
      
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Cloud Function error: ${e.message}');
    } catch (e) {
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
}

