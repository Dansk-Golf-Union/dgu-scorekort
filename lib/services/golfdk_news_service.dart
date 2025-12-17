import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // For kIsWeb and kDebugMode
import '../models/news_article_model.dart';

/// Service for fetching latest golf news from Golf.dk
///
/// Fetches news articles from Golf.dk's public API.
/// Uses corsproxy.io for web production builds to bypass CORS restrictions.
/// In debug mode (localhost), it calls the API directly with --disable-web-security.
class GolfDkNewsService {
  // Base URL for the Golf.dk news API.
  // Uses corsproxy.io for web production builds to bypass CORS restrictions.
  // In debug mode (localhost), it calls the API directly.
  static const String baseUrl = kIsWeb && !kDebugMode
      ? 'https://corsproxy.io/?https://prod-admin.golfdk.sdmdev.dk'
      : 'https://prod-admin.golfdk.sdmdev.dk';

  /// Get latest news articles from Golf.dk
  ///
  /// Parameters:
  /// - [limit]: Max number of articles to return (default: 3)
  ///
  /// Returns: List of NewsArticle objects, ordered by newest first
  ///
  /// Throws: Exception if API call fails
  Future<List<NewsArticle>> getLatestNews({int limit = 3}) async {
    try {
      // Add limit parameter to API URL (request more than needed as buffer)
      // Some APIs might ignore this, so we also do client-side take()
      final url = Uri.parse('$baseUrl/rest/latest_news?_format=json&limit=${limit * 2}');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'DGU-Scorekort/2.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        // Client-side limit as fallback (in case API ignores limit parameter)
        return jsonList
            .take(limit)
            .map((json) => NewsArticle.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load news: ${response.statusCode} ${response.reasonPhrase}');
      }
    } on TimeoutException {
      throw Exception('Request timed out. Check your internet connection.');
    } catch (e) {
      rethrow;
    }
  }
}

