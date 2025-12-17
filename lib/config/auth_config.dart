class AuthConfig {
  // OAuth Client Configuration
  static const String clientId = 'DGU_TEST_DK';

  // Redirect URI - Cloud Function relay håndterer OAuth callback
  // V2: Uses golfboxCallbackV2 for dynamic redirect (A/B testing support)
  static const String redirectUri =
      'https://europe-west1-dgu-scorekort.cloudfunctions.net/golfboxCallbackV2';

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
  static const String unionIdKey = 'dgu_union_id';
}
