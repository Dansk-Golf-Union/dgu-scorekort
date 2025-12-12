import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  // Cloud Function URL (CORS-free proxy with CORRECTED URL!)
  static const String cloudFunctionUrl =
      'https://europe-west1-dgu-scorekort.cloudfunctions.net/sendNotification';

  /// Send push notification to marker when scorecard is ready for approval
  /// Uses Firebase Cloud Function as CORS-free proxy
  /// Returns a map with success status and optional error details
  Future<Map<String, dynamic>> sendMarkerApprovalNotification({
    required String markerUnionId,
    required String playerName,
    required String approvalUrl,
  }) async {
    try {
      print('📤 Sending push notification via Cloud Function...');
      print('  Marker: $markerUnionId');
      print('  Player: $playerName');
      print('  URL: $cloudFunctionUrl');

      // Build request payload
      final requestBody = {
        'markerUnionId': markerUnionId,
        'playerName': playerName,
        'approvalUrl': approvalUrl,
      };

      print('📦 Request: ${json.encode(requestBody)}');

      // Call Cloud Function via HTTP POST
      final response = await http.post(
        Uri.parse(cloudFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'data': requestBody,
        }), // Wrap in 'data' for HTTP call
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
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


