// Web-specific utilities
// This file is only imported when running on web platform
import 'dart:html' as html;

/// Get current browser URL (web only)
String? getCurrentUrl() {
  try {
    return html.window.location.href;
  } catch (e) {
    return null;
  }
}

/// Clean OAuth parameters from browser URL (web only)
void cleanUrlParams() {
  try {
    final uri = Uri.parse(html.window.location.href);
    final cleanUri = uri.replace(
      queryParameters: {},
      fragment: '', // Also clear fragment
    );
    html.window.history.replaceState({}, '', cleanUri.toString());
  } catch (e) {
    // Silently fail if URL cleaning not possible
  }
}

/// Close browser window/tab (web only)
void closeWindow() {
  try {
    html.window.close();
  } catch (e) {
    // Silently fail if window cannot be closed
  }
}

