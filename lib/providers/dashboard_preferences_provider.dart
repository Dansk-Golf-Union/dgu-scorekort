import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPreferencesProvider with ChangeNotifier {
  // Default values (max 10 for all)
  int _newsCount = 3;
  int _friendsCount = 3;
  int _activitiesCount = 2;
  int _scoresCount = 2;
  
  // Widget order (removed 'ugens_bedste' - merged into Mine Venner)
  List<String> _widgetOrder = [
    'news',
    'friends',
    'activities',
    'scores',
    'tournaments',
  ];
  
  // Getters
  int get newsCount => _newsCount;
  int get friendsCount => _friendsCount;
  int get activitiesCount => _activitiesCount;
  int get scoresCount => _scoresCount;
  List<String> get widgetOrder => _widgetOrder;
  
  // SharedPreferences keys
  static const String _newsKey = 'dashboard_news_count';
  static const String _friendsKey = 'dashboard_friends_count';
  static const String _activitiesKey = 'dashboard_activities_count';
  static const String _scoresKey = 'dashboard_scores_count';
  static const String _orderKey = 'dashboard_widget_order';
  
  /// Load preferences from storage
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _newsCount = prefs.getInt(_newsKey) ?? 3;
    _friendsCount = prefs.getInt(_friendsKey) ?? 3;
    _activitiesCount = prefs.getInt(_activitiesKey) ?? 2;
    _scoresCount = prefs.getInt(_scoresKey) ?? 2;
    
    // Load widget order
    final orderJson = prefs.getString(_orderKey);
    if (orderJson != null) {
      _widgetOrder = List<String>.from(json.decode(orderJson));
      
      // Migration: Remove 'ugens_bedste' if present (merged into Mine Venner)
      if (_widgetOrder.contains('ugens_bedste')) {
        _widgetOrder.remove('ugens_bedste');
        // Save the migrated order
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
    await saveWidgetOrder(['news', 'friends', 'activities', 'scores', 'tournaments']);
  }
}

