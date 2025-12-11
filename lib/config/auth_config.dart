class AuthConfig {
  // OAuth Client Configuration
  static const String clientId = 'DGU_TEST_DK';

  // Redirect URI - relay side håndterer callback
  static const String redirectUri =
      'https://staging-danskgolfunion.dk.sdmdev.dk/verifiedlogin';

  // GolfBox Auth endpoints
  static const String authBaseUrl = 'https://auth.golfbox.io';

  // API endpoints
  static const String apiBaseUrl =
      'https://dgubasen.api.union.golfbox.io/DGUScorkortAapp/clubs';

  // OAuth scopes
  static const String scope = 'get_player.information none union';

  // CORS proxy for web environment
  static const String proxyUrl = 'https://corsproxy.io/?';

  // Storage keys
  static const String accessTokenKey = 'dgu_access_token';
  static const String codeVerifierKey = 'dgu_code_verifier';
}
