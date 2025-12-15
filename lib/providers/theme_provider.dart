import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing app theme (Light/Dark mode)
///
/// Stores user preference in SharedPreferences and notifies listeners on change.
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  static const String _themeKey = 'is_dark_mode';

  /// Whether dark mode is currently enabled
  bool get isDarkMode => _isDarkMode;

  /// Initialize theme provider and load saved preference
  Future<void> initialize() async {
    await _loadThemePreference();
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _saveThemePreference();
  }

  /// Set dark mode explicitly
  Future<void> setDarkMode(bool isDark) async {
    if (_isDarkMode == isDark) return;
    _isDarkMode = isDark;
    notifyListeners();
    await _saveThemePreference();
  }

  /// Load theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      notifyListeners();
    } catch (e) {
      // If loading fails, default to light mode
      _isDarkMode = false;
    }
  }

  /// Save theme preference to SharedPreferences
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      // Silently fail if save fails
      debugPrint('Failed to save theme preference: $e');
    }
  }
}


