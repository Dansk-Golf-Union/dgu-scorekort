import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  // DGU Notification API (direct call from browser - no CORS issues!)
  static const String notificationApiUrl =
      'https://sendsingnotification-d3higuw2ca-ey.a.run.app';
  static const String tokenGistUrl =
      'https://gist.githubusercontent.com/nhuttel/ad197ae6de63e78d3d450fd70d604b7d/raw/6036a00fec46c4e5b1d05e4295c5e32566090abf/gistfile1.txt';

  /// Fetch notification token from GitHub Gist
  Future<String> _fetchNotificationToken() async {
    try {
      final response = await http.get(Uri.parse(tokenGistUrl));
      if (response.statusCode == 200) {
        return response.body.trim();
      } else {
        throw Exception('Failed to fetch token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Token fetch error: $e');
      rethrow;
    }
  }

  /// Format expiry date for notification API: "2025-12-18T23:15:53"
  String _formatExpiryDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
        'T${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  /// Send push notification to marker when scorecard is ready for approval
  /// Calls DGU notification API directly from browser (no Cloud Function)
  /// Returns a map with success status and optional error details
  Future<Map<String, dynamic>> sendMarkerApprovalNotification({
    required String markerUnionId,
    required String playerName,
    required String approvalUrl,
  }) async {
    try {
      print('📤 Sending push notification directly to DGU API...');
      print('  Marker: $markerUnionId');
      print('  Player: $playerName');
      print('  URL: $notificationApiUrl');

      // 1. Fetch notification token
      print('🔑 Fetching notification token...');
      final token = await _fetchNotificationToken();
      print('✅ Token fetched');

      // 2. Build expiry date (7 days from now)
      final expiryDate = DateTime.now().add(const Duration(days: 7));
      final expiryString = _formatExpiryDate(expiryDate);

      // 3. Build notification payload
      final payload = {
        'data': {
          'recipients': [markerUnionId],
          'title': 'Nyt scorekort afventer din godkendelse',
          'message':
              '$playerName har sendt et scorekort til godkendelse.\r\n\r\nKlik på \'Gå til\' for at godkende scorekortet.',
          'message_type': 'DGUMessage',
          'message_link': approvalUrl,
          'expire_at': expiryString,
          'token': token,
        },
      };

      print('📦 Payload: ${json.encode(payload)}');

      // 4. Send POST request to DGU notification API
      final response = await http.post(
        Uri.parse(notificationApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'response': response.body,
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'response': response.body,
          'error': 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Push notification error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
