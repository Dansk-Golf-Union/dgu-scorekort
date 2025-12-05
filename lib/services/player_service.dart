import '../models/player_model.dart';

class PlayerService {
  /// Returns the current player (mock data for now)
  /// 
  /// TODO: Replace with actual authentication/login in the future
  Future<Player> getCurrentPlayer() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Return hardcoded mock player
    return Player(
      name: 'Nick Hüttel',
      memberNo: '134-2813',
      hcp: 14.5,
      token: '', // Empty for now, will be used for future API authentication
    );
  }
}


