import 'package:cloud_functions/cloud_functions.dart';

class NotificationService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

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

      // Call Firebase Cloud Function
      final callable = _functions.httpsCallable('sendNotification');

      final result = await callable.call({
        'markerUnionId': markerUnionId,
        'playerName': playerName,
        'approvalUrl': approvalUrl,
      });

      print('✅ Push notification sent successfully!');
      print('📦 Response: ${result.data}');

      return {'success': true, 'response': result.data.toString()};
    } on FirebaseFunctionsException catch (e) {
      print('❌ Cloud Function error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'error': '${e.code}: ${e.message}',
        'details': e.details?.toString(),
      };
    } catch (e) {
      print('❌ Push notification error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
