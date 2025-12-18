import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tournament_model.dart';
import '../models/ranking_model.dart';

/// Service for fetching tournaments and rankings from Firestore cache
/// 
/// Data is updated nightly by Cloud Function `cacheTournamentsAndRankings` at 02:30 CET.
/// Cache is populated from Golf.dk APIs:
/// - https://drupal.golf.dk/rest/taxonomy_lists/current_tournaments?_format=json
/// - https://drupal.golf.dk/rest/taxonomy_lists/rankings?_format=json
/// 
/// Pattern: Server-side cache (like Course Cache, Birdie Bonus) - no direct API calls from client.
/// Max 24-hour cache delay is acceptable for tournament/ranking data.
///
/// Note: Using GetOptions(source: Source.server) to force fresh reads from Firestore
/// servers, bypassing local cache. This follows the same pattern as BirdieBonusService
/// to prevent stale cached data issues.
class GolfEventsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Fetch current tournaments from Firestore cache
  /// 
  /// Data is updated nightly by Cloud Function at 02:30 CET.
  /// Max 24-hour cache delay acceptable.
  /// 
  /// Returns:
  /// - List of Tournament objects if cache exists
  /// - Empty list if no cache or error
  Future<List<Tournament>> getCurrentTournaments() async {
    try {
      // Force server read to bypass Firestore client-side cache
      // See BirdieBonusService for detailed explanation of Source.server pattern
      final doc = await _firestore
          .collection('tournaments_cache')
          .doc('current')
          .get(const GetOptions(source: Source.server));
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final tournamentsJson = data['tournaments'] as List<dynamic>? ?? [];
        
        return tournamentsJson
            .map((json) => Tournament.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        print('⚠️ No tournaments cache found');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching tournaments: $e');
      return [];
    }
  }

  /// Fetch current rankings from Firestore cache
  /// 
  /// Data is updated nightly by Cloud Function at 02:30 CET.
  /// Max 24-hour cache delay acceptable.
  /// 
  /// Returns:
  /// - List of Ranking objects if cache exists
  /// - Empty list if no cache or error
  Future<List<Ranking>> getCurrentRankings() async {
    try {
      // Force server read to bypass Firestore client-side cache
      // See BirdieBonusService for detailed explanation of Source.server pattern
      final doc = await _firestore
          .collection('rankings_cache')
          .doc('current')
          .get(const GetOptions(source: Source.server));
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final rankingsJson = data['rankings'] as List<dynamic>? ?? [];
        
        return rankingsJson
            .map((json) => Ranking.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        print('⚠️ No rankings cache found');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching rankings: $e');
      return [];
    }
  }

  /// Fetch both tournaments and rankings in parallel
  /// 
  /// Returns a record with (tournaments, rankings)
  Future<(List<Tournament>, List<Ranking>)> getTournamentsAndRankings() async {
    final results = await Future.wait([
      getCurrentTournaments(),
      getCurrentRankings(),
    ]);
    
    return (results[0] as List<Tournament>, results[1] as List<Ranking>);
  }

  /// Fetch icon URL for a given icon ID from Firestore cache
  /// 
  /// Data is updated nightly by Cloud Function at 02:30 CET.
  /// Icons are cached from Golf.dk Drupal Media API.
  /// 
  /// [iconId] - Icon ID (e.g., "6645")
  /// 
  /// Returns:
  /// - Icon URL string if cached
  /// - null if not found or error
  Future<String?> getIconUrl(String iconId) async {
    if (iconId.isEmpty) return null;
    
    try {
      final doc = await _firestore
          .collection('tournament_icons_cache')
          .doc(iconId)
          .get(const GetOptions(source: Source.server));
      
      if (doc.exists && doc.data() != null) {
        return doc.data()!['url'] as String?;
      }
      return null;
    } catch (e) {
      print('⚠️ Error fetching icon $iconId: $e');
      return null;
    }
  }
}

