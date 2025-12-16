import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/birdie_bonus_model.dart';

/// Service for fetching Birdie Bonus data from Firestore cache
/// 
/// Data is updated nightly by Cloud Function `cacheBirdieBonusData` at 04:00 CET.
/// Cache is populated from paginated Birdie Bonus API.
/// 
/// Pattern: Server-side cache (like Course Cache) - no direct API calls from client.
/// Max 24-hour cache delay is acceptable for leaderboard data.
///
/// TODO: Consider removing Source.server workaround
/// Currently using GetOptions(source: Source.server) to force fresh reads
/// from Firestore servers, bypassing local cache. This was required because
/// Flutter's Firestore SDK was showing stale cached data even after manual
/// Firestore Console updates. Once proper Firebase Auth with custom claims
/// is implemented, evaluate if default caching behavior is acceptable.
/// Trade-off: Fresh data vs network latency (~200-500ms per read).
/// See: README.md "Birdie Bonus Integration: Lessons Learned" for details.
class BirdieBonusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Fetch Birdie Bonus data from Firestore cache
  /// 
  /// Data is updated nightly by Cloud Function at 04:00 CET.
  /// Max 24-hour cache delay acceptable.
  /// 
  /// [unionId] - Player's DGU union ID (e.g., "147-3270")
  /// 
  /// Returns:
  /// - BirdieBonusData with cached values if participant
  /// - BirdieBonusData with isParticipant=false if not in cache
  Future<BirdieBonusData> getBirdieBonusData(String unionId) async {
    try {
      // CRITICAL FIX: Force server read (bypass Firestore client-side cache)
      //
      // Problem: Flutter's Firestore SDK aggressively caches data locally.
      // When data is updated in Firestore (manually or via Cloud Function),
      // the Flutter app continues showing stale cached data indefinitely.
      //
      // Solution: GetOptions(source: Source.server) forces a fresh read
      // directly from Firestore servers, bypassing local cache.
      //
      // Without this, users would see outdated Birdie Bonus data or the bar
      // wouldn't appear even when they're registered as participants.
      final doc = await _firestore
          .collection('birdie_bonus_cache')
          .doc(unionId)
          .get(const GetOptions(source: Source.server));
      
      if (doc.exists) {
        final data = doc.data()!;
        return BirdieBonusData(
          birdieCount: data['birdieCount'] ?? 0,
          rankingPosition: data['rankingPosition'] ?? 0,
          isParticipant: data['isParticipant'] ?? false,
          unionId: unionId,
        );
      } else {
        // Player not found in cache = not participating
        return BirdieBonusData.notParticipant(unionId: unionId);
      }
    } catch (e) {
      print('Error fetching Birdie Bonus data: $e');
      // On error, return non-participant state
      return BirdieBonusData.notParticipant(unionId: unionId);
    }
  }

  /// Check if player is participating in Birdie Bonus
  /// 
  /// Returns true ONLY if player exists in cache.
  /// Used by Home screen to conditionally show/hide Birdie Bonus Bar.
  /// 
  /// [unionId] - Player's DGU union ID (e.g., "147-3270")
  /// 
  /// Returns:
  /// - true if player found in cache with isParticipant=true
  /// - false if not found or error
  Future<bool> isParticipating(String unionId) async {
    try {
      // CRITICAL FIX: Force server read (bypass Firestore client-side cache)
      // See detailed explanation in getBirdieBonusData() method above.
      // Without Source.server, the app would show stale cached data.
      final doc = await _firestore
          .collection('birdie_bonus_cache')
          .doc(unionId)
          .get(const GetOptions(source: Source.server));
      
      print('📊 Firestore doc.exists: ${doc.exists}');
      if (doc.exists) {
        final data = doc.data();
        print('📊 Firestore raw data: $data');
        final isParticipantValue = data?['isParticipant'];
        print('📊 isParticipant field value: $isParticipantValue (type: ${isParticipantValue.runtimeType})');
      }
      
      // Player must exist in cache to be considered participating
      return doc.exists && (doc.data()?['isParticipant'] ?? false);
    } catch (e) {
      print('❌ Error checking participation: $e');
      // On error, hide bar (graceful degradation)
      return false;
    }
  }
}

