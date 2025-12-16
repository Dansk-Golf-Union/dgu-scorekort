import '../models/birdie_bonus_model.dart';

/// Service for fetching Birdie Bonus data
/// 
/// Currently uses mock data for development.
/// Prepared for future API integration with GolfBox Birdie Bonus endpoint.
/// 
/// API endpoint (when ready):
/// https://birdie-bonus.api.union.golfbox.dk/api/medlemmar/rating_list/{unionId}
class BirdieBonusService {
  // TODO: Replace with actual API endpoint when available
  // static const String _apiBaseUrl = 'https://birdie-bonus.api.union.golfbox.dk';
  
  /// Fetch Birdie Bonus data for a player
  /// 
  /// Currently returns mock data.
  /// 
  /// [unionId] - Player's DGU union ID (e.g., "147-3270")
  /// 
  /// Returns:
  /// - BirdieBonusData with mock values if participant
  /// - BirdieBonusData with isParticipant=false if not enrolled
  Future<BirdieBonusData> getBirdieBonusData(String unionId) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    // TODO: Replace with real API call
    // return _fetchFromApi(unionId);
    
    // For now, return mock data
    return BirdieBonusData.mock(unionId: unionId);
  }

  /// Check if player is participating in Birdie Bonus
  /// 
  /// Currently returns true for all users (mock behavior).
  /// In production, this would check actual participation status.
  Future<bool> isParticipating(String unionId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    // TODO: Replace with real participation check
    // For testing, return true so bar is always visible
    return true;
  }

  // ============================================================================
  // FUTURE API INTEGRATION (commented out for now)
  // ============================================================================
  
  /*
  /// Fetch Birdie Bonus data from API
  /// 
  /// Expected API response structure from GolfBox documentation:
  /// ```json
  /// {
  ///   "BB_participant": 2,
  ///   "dgUNumber": "147-3270",
  ///   "BirdieBonusPoints": 294,
  ///   "regionLabel": "Sjælland",
  ///   "hcpGroupLabel": "11.5-18.4",
  ///   "rankInRegionGroup": 125
  /// }
  /// ```
  Future<BirdieBonusData> _fetchFromApi(String unionId) async {
    final url = Uri.parse('$_apiBaseUrl/api/medlemmar/rating_list/$unionId');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Basic [credentials]', // TODO: Add auth
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return BirdieBonusData.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        // Player not found or not participating
        return BirdieBonusData.notParticipant(unionId: unionId);
      } else {
        throw Exception('Failed to load Birdie Bonus data: ${response.statusCode}');
      }
    } catch (e) {
      // On error, return non-participant state
      print('Error fetching Birdie Bonus data: $e');
      return BirdieBonusData.notParticipant(unionId: unionId);
    }
  }
  */
}

