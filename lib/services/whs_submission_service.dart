import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class WhsSubmissionService {
  // API Configuration
  static const String baseUrl =
      "https://corsproxy.io/?https://dgubasen.api.union.golfbox.io/DGUScorkortAapp";

  // Current: Basic Auth endpoint
  static const String exchangeScorecardEndpoint =
      "/Clubs/Members/ExchangedScorecards";

  // Future: OAuth endpoint (skift når OAuth virker)
  // static const String exchangeScorecardEndpoint = "/Clubs/Members/ExchangedScorecards_ByAccessToken";

  // ⚠️ TEST WHITELIST: Kun disse spillere sender REELT til WHS API
  static const List<String> _testWhitelist = [
    '8-9995', // Test bruger 1
    '8-9994', // Test bruger 2
  ];

  /// Submit scorecard til WHS API (Minimum API format)
  /// Hvis spiller IKKE er på whitelist: Fake success (ingen API kald)
  /// firestoreData MUST include 'id' field (Firestore document ID) for ExternalID
  Future<bool> submitScorecard(Map<String, dynamic> firestoreData) async {
    final playerId = firestoreData['playerId'] as String;
    final documentId = firestoreData['id'] as String?;

    if (documentId == null || documentId.isEmpty) {
      throw Exception(
        'Missing Firestore document ID - cannot generate ExternalID',
      );
    }

    // Check whitelist
    if (!_testWhitelist.contains(playerId)) {
      print(
        '🚫 Player $playerId NOT on whitelist - SIMULATING success (no real API call)',
      );

      // Simulate API delay for realism
      await Future.delayed(Duration(milliseconds: 500));

      // Return fake success
      return true; // ✅ "Success" men ingen real API call!
    }

    print('✅ Player $playerId IS on whitelist - REAL WHS API submission!');

    try {
      // 1. Map til API format (returns ARRAY!)
      final payloadArray = _mapToApiFormat(firestoreData);

      print('📤 Payload: ${json.encode(payloadArray)}');

      // 2. Get auth token
      final authToken = await _getAuthToken();

      // 3. POST til ExchangedScorecards endpoint
      final url = Uri.parse('$baseUrl$exchangeScorecardEndpoint');

      print('📤 POST to: $url');

      final response = await http.post(
        url,
        headers: {
          'Authorization': authToken,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payloadArray), // Send array!
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ WHS submission successful!');
        print('📦 Response: ${response.body}');
        return true;
      } else {
        print('❌ WHS submission failed: ${response.statusCode}');
        print('📦 Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ WHS submission error: $e');
      return false;
    }
  }

  /// Get auth token (reuse token fetch logic)
  Future<String> _getAuthToken() async {
    const tokenUrl =
        'https://gist.githubusercontent.com/nhuttel/a907dd7d60bf417b584333dfd5fff74a/raw/9b743740c4a7476c79d6a03c726e0d32b4034ec6/dgu_token.txt';

    try {
      final response = await http.get(Uri.parse(tokenUrl));
      if (response.statusCode == 200) {
        return response.body.trim();
      } else {
        throw Exception('Failed to load auth token: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching auth token: $e');
    }
  }

  /// Map Firestore data til API format
  /// ⚠️ VIGTIGT: API forventer et ARRAY med ét scorecard objekt!
  List<Map<String, dynamic>> _mapToApiFormat(Map<String, dynamic> data) {
    // Format timestamps: "20251211T090200"
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final playedDate = (data['playedDate'] as Timestamp).toDate();

    final createDateTime = _formatDguDateTime(createdAt);
    final startTime = _formatDguDateTime(playedDate);

    // Generate ExternalID: Use Firestore document ID with prefix
    final documentId = data['id'] as String;
    final externalId = 'dgu_$documentId';

    // Format HCP: 15.8 → "158000" (multiply by 10000)
    final hcpInt = ((data['playerHandicap'] as num) * 10000).round();
    final hcp = hcpInt.toString();

    // Build strokes array from holes
    final holes = data['holes'] as List;
    final strokes = holes.map((h) => h['strokes'] as int? ?? 0).toList();

    // ⚠️ Return ARRAY med ét objekt (API krav!)
    return [
      {
        'CreateDateTime': createDateTime,
        'ExternalID': externalId,
        'HCP': hcp,
        'CourseHandicap': data['playingHandicap'],
        'Course': {
          'CourseID': data['courseId'],
          'ClubID': data['clubId'],
          'TeeID': data['teeId'],
        },
        'Marker': {
          'UnionID': data['markerId'], // Kun UnionID (API slår op automatisk)
        },
        'Result': {'Strokes': strokes, 'IsQualifying': true},
        'Round': {
          'HolesPlayed': holes.length,
          'RoundType': 1,
          'StartTime': startTime,
        },
        'Player': {'UnionID': data['playerId']},
      },
    ];
  }

  String _formatDguDateTime(DateTime dt) {
    return '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}'
        'T${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}${dt.second.toString().padLeft(2, '0')}';
  }
}



