import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_preferences_provider.dart';
import '../theme/app_theme.dart';

class DashboardSettingsScreen extends StatelessWidget {
  const DashboardSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Dashboard Indstillinger'),
        backgroundColor: AppTheme.dguGreen,
        foregroundColor: Colors.white,
      ),
      body: Consumer<DashboardPreferencesProvider>(
        builder: (context, prefs, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Text(
                'Tilpas antal elementer i hver widget på forsiden',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              
              // News Slider
              _buildSliderCard(
                context,
                title: '🗞️ Nyheder fra Golf.dk',
                value: prefs.newsCount.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                onChanged: (value) => prefs.setNewsCount(value.toInt()),
              ),
              const SizedBox(height: 16),
              
              // Friends Slider
              _buildSliderCard(
                context,
                title: '👥 Mine Venner',
                value: prefs.friendsCount.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                onChanged: (value) => prefs.setFriendsCount(value.toInt()),
              ),
              const SizedBox(height: 16),
              
              // Activities Slider
              _buildSliderCard(
                context,
                title: '📰 Seneste Aktivitet',
                value: prefs.activitiesCount.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                onChanged: (value) => prefs.setActivitiesCount(value.toInt()),
              ),
              const SizedBox(height: 16),
              
              // Scores Slider
              _buildSliderCard(
                context,
                title: '📊 Mine Seneste Scores',
                value: prefs.scoresCount.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                onChanged: (value) => prefs.setScoresCount(value.toInt()),
              ),
              const SizedBox(height: 32),
              
              // Reset button
              OutlinedButton.icon(
                onPressed: () async {
                  await prefs.resetToDefaults();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nulstillet til standard')),
                    );
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Nulstil til standard'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildSliderCard(
    BuildContext context, {
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.dguGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              activeColor: AppTheme.dguGreen,
              label: value.toInt().toString(),
              onChanged: onChanged,
            ),
            Text(
              value.toInt() == 0 
                  ? 'Skjult (0 elementer)'
                  : 'Viser ${value.toInt()} element${value.toInt() > 1 ? 'er' : ''}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

