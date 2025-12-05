import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/auth_config.dart';
import '../models/player_model.dart';

class PlayerService {
  /// Fetches player information from GolfBox API using access token
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
}
