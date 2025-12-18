import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPreferencesProvider with ChangeNotifier {
  // Default values (max 10 for all)
  int _newsCount = 3;
  int _friendsCount = 3;
  int _activitiesCount = 2;
  int _scoresCount = 2;
  int _tournamentsCount = 3;
  int _rankingsCount = 3;
  
  // Widget order (split 'tournaments' into separate 'tournaments' and 'rankings')
  List<String> _widgetOrder = [
    'news',
    'friends',
    'activities',
    'scores',
    'tournaments',
    'rankings',
  ];
  
  // Getters
  int get newsCount => _newsCount;
  int get friendsCount => _friendsCount;
  int get activitiesCount => _activitiesCount;
  int get scoresCount => _scoresCount;
  int get tournamentsCount => _tournamentsCount;
  int get rankingsCount => _rankingsCount;
  List<String> get widgetOrder => _widgetOrder;
  
  // SharedPreferences keys
  static const String _newsKey = 'dashboard_news_count';
  static const String _friendsKey = 'dashboard_friends_count';
  static const String _activitiesKey = 'dashboard_activities_count';
  static const String _scoresKey = 'dashboard_scores_count';
  static const String _tournamentsKey = 'dashboard_tournaments_count';
  static const String _rankingsKey = 'dashboard_rankings_count';
  static const String _orderKey = 'dashboard_widget_order';
  
  /// Load preferences from storage
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _newsCount = prefs.getInt(_newsKey) ?? 3;
    _friendsCount = prefs.getInt(_friendsKey) ?? 3;
    _activitiesCount = prefs.getInt(_activitiesKey) ?? 2;
    _scoresCount = prefs.getInt(_scoresKey) ?? 2;
    _tournamentsCount = prefs.getInt(_tournamentsKey) ?? 3;
    _rankingsCount = prefs.getInt(_rankingsKey) ?? 3;
    
    // Load widget order
    final orderJson = prefs.getString(_orderKey);
    if (orderJson != null) {
      _widgetOrder = List<String>.from(json.decode(orderJson));
      
      bool needsMigration = false;
      
      // Migration: Remove 'ugens_bedste' if present (merged into Mine Venner)
      if (_widgetOrder.contains('ugens_bedste')) {
        _widgetOrder.remove('ugens_bedste');
        needsMigration = true;
      }
      
      // Migration: Split old single 'tournaments' into 'tournaments' and 'rankings'
      // If order has 'tournaments' but not 'rankings', add 'rankings' after 'tournaments'
      if (_widgetOrder.contains('tournaments') && !_widgetOrder.contains('rankings')) {
        final tournamentsIndex = _widgetOrder.indexOf('tournaments');
        _widgetOrder.insert(tournamentsIndex + 1, 'rankings');
        needsMigration = true;
      }
      
      // Save migrated order if needed
      if (needsMigration) {
        await prefs.setString(_orderKey, json.encode(_widgetOrder));
      }
    }
    
    notifyListeners();
  }
  
  /// Update news count
  Future<void> setNewsCount(int count) async {
    _newsCount = count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_newsKey, count);
    notifyListeners();
  }
  
  /// Update friends count
  Future<void> setFriendsCount(int count) async {
    _friendsCount = count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_friendsKey, count);
    notifyListeners();
  }
  
  /// Update activities count
  Future<void> setActivitiesCount(int count) async {
    _activitiesCount = count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_activitiesKey, count);
    notifyListeners();
  }
  
  /// Update scores count
  Future<void> setScoresCount(int count) async {
    _scoresCount = count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_scoresKey, count);
    notifyListeners();
  }
  
  /// Update tournaments count
  Future<void> setTournamentsCount(int count) async {
    _tournamentsCount = count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tournamentsKey, count);
    notifyListeners();
  }
  
  /// Update rankings count
  Future<void> setRankingsCount(int count) async {
    _rankingsCount = count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_rankingsKey, count);
    notifyListeners();
  }
  
  /// Save widget order
  Future<void> saveWidgetOrder(List<String> order) async {
    _widgetOrder = order;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_orderKey, json.encode(order));
    notifyListeners();
  }
  
  /// Reset to defaults
  Future<void> resetToDefaults() async {
    await setNewsCount(3);
    await setFriendsCount(3);
    await setActivitiesCount(2);
    await setScoresCount(2);
    await setTournamentsCount(3);
    await setRankingsCount(3);
    await saveWidgetOrder(['news', 'friends', 'activities', 'scores', 'tournaments', 'rankings']);
  }
}

