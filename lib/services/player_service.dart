import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/auth_config.dart';
import '../models/player_model.dart';

class PlayerService {
  // Token is fetched from external gist (for Basic Auth on public endpoints)
  static const String _tokenUrl = 
      'https://gist.githubusercontent.com/nhuttel/a907dd7d60bf417b584333dfd5fff74a/raw/9b743740c4a7476c79d6a03c726e0d32b4034ec6/dgu_token.txt';
  static String? _cachedToken;

  /// Fetches Basic Auth token from external source
  Future<String> _getBasicAuthToken() async {
    if (_cachedToken != null) {
      return _cachedToken!;
    }
    
    try {
      final response = await http.get(Uri.parse(_tokenUrl));
      if (response.statusCode == 200) {
        _cachedToken = response.body.trim();
        return _cachedToken!;
      } else {
        throw Exception('Failed to load auth token: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching auth token: $e');
    }
  }

  /// Fetches player information from GolfBox API using OAuth access token
  /// NOTE: Not currently used - using fetchPlayerByUnionId with Basic Auth instead
  /// This will be used later when OAuth player endpoint is confirmed
  Future<Player> fetchPlayerInfo(String accessToken) async {
    final url = Uri.parse(
      '${AuthConfig.proxyUrl}${AuthConfig.apiBaseUrl}/golfer',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Player.fromGolfBoxJson(data);
      } else {
        throw Exception(
          'Failed to fetch player info: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching player info: $e');
    }
  }

  /// Fetches player information by Union ID (e.g., "906-223")
  /// Uses Basic Auth instead of OAuth for temporary solution
  Future<Player> fetchPlayerByUnionId(String unionId) async {
    final url = Uri.parse(
      '${AuthConfig.proxyUrl}${AuthConfig.apiBaseUrl}/golfer?unionid=$unionId',
    );

    try {
      final basicAuthToken = await _getBasicAuthToken();
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': basicAuthToken,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Player.fromGolfBoxJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Kunne ikke finde spiller med DGU nummer: $unionId');
      } else {
        throw Exception(
          'Failed to fetch player: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e.toString().contains('Kunne ikke finde')) {
        rethrow;
      }
      throw Exception('Netværksfejl. Prøv igen');
    }
  }
}
