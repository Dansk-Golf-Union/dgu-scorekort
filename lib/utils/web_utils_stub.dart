// Stub implementation for non-web platforms (iOS, Android, etc.)
// These functions are no-ops or return null when not on web

/// Get current browser URL (not available on native platforms)
String? getCurrentUrl() {
  return null; // No browser URL on native platforms
}

/// Clean OAuth parameters from browser URL (no-op on native platforms)
void cleanUrlParams() {
  // No-op: Not applicable on native platforms
}

/// Close browser window/tab (no-op on native platforms)
void closeWindow() {
  // No-op: Cannot programmatically close iOS app
}

