import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  // Notification API Configuration
  // Note: No CORS proxy needed - works directly from Firebase Hosting
  static const String notificationUrl =
      'https://sendsingnotification-d3higuw2ca-ey.a.run.app';

  // Token URL (GitHub Gist)
  static const String tokenUrl =
      'https://gist.githubusercontent.com/nhuttel/ad197ae6de63e78d3d450fd70d604b7d/raw/6036a00fec46c4e5b1d05e4295c5e32566090abf/gistfile1.txt';

  /// Send push notification to marker when scorecard is ready for approval
  Future<bool> sendMarkerApprovalNotification({
    required String markerUnionId,
    required String playerName,
    required String approvalUrl,
  }) async {
    try {
      print('📤 Sending push notification to marker: $markerUnionId');

      // 1. Get auth token
      final token = await _getNotificationToken();

      // 2. Calculate expiry date (7 days from now)
      final expiryDate = DateTime.now().add(Duration(days: 7));
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

      print('📦 Notification payload: ${json.encode(payload)}');

      // 4. POST to notification service
      final response = await http.post(
        Uri.parse(notificationUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Push notification sent successfully!');
        print('📦 Response: ${response.body}');
        return true;
      } else {
        print('⚠️ Push notification failed: ${response.statusCode}');
        print('📦 Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Push notification error: $e');
      return false;
    }
  }

  /// Get notification auth token from GitHub Gist
  Future<String> _getNotificationToken() async {
    try {
      final response = await http.get(Uri.parse(tokenUrl));
      if (response.statusCode == 200) {
        return response.body.trim();
      } else {
        throw Exception(
          'Failed to load notification token: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching notification token: $e');
    }
  }

  /// Format date for API: "2025-12-18T17:40:00"
  String _formatExpiryDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
        'T${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }
}
