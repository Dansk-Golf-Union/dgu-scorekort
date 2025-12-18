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
          // Map widget IDs to slider data
          final widgets = prefs.widgetOrder.map((id) {
            switch (id) {
              case 'news':
                return _WidgetSliderData(
                  id: 'news',
                  title: '🗞️ Nyheder fra Golf.dk',
                  value: prefs.newsCount.toDouble(),
                  max: 5,
                  onChanged: (v) => prefs.setNewsCount(v.toInt()),
                );
              case 'friends':
                return _WidgetSliderData(
                  id: 'friends',
                  title: '👥 Mine Venner',
                  value: prefs.friendsCount.toDouble(),
                  max: 10,
                  onChanged: (v) => prefs.setFriendsCount(v.toInt()),
                );
              case 'activities':
                return _WidgetSliderData(
                  id: 'activities',
                  title: '📰 Seneste Aktivitet',
                  value: prefs.activitiesCount.toDouble(),
                  max: 10,
                  onChanged: (v) => prefs.setActivitiesCount(v.toInt()),
                );
              case 'scores':
                return _WidgetSliderData(
                  id: 'scores',
                  title: '📊 Mine Seneste Scores',
                  value: prefs.scoresCount.toDouble(),
                  max: 10,
                  onChanged: (v) => prefs.setScoresCount(v.toInt()),
                );
              case 'tournaments':
                return _WidgetSliderData(
                  id: 'tournaments',
                  title: '🏌️ Aktuelle Turneringer',
                  value: prefs.tournamentsCount.toDouble(),
                  max: 10,
                  onChanged: (v) => prefs.setTournamentsCount(v.toInt()),
                );
              case 'rankings':
                return _WidgetSliderData(
                  id: 'rankings',
                  title: '🏆 Aktuelle Ranglister',
                  value: prefs.rankingsCount.toDouble(),
                  max: 10,
                  onChanged: (v) => prefs.setRankingsCount(v.toInt()),
                );
              default:
                throw Exception('Unknown widget ID: $id');
            }
          }).toList();
          
          return Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Tilpas antal elementer og rækkefølge',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Træk og slip for at ændre rækkefølgen',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              
              // Reorderable list
              Expanded(
                child: ReorderableListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex--;
                    final newOrder = List<String>.from(prefs.widgetOrder);
                    final item = newOrder.removeAt(oldIndex);
                    newOrder.insert(newIndex, item);
                    prefs.saveWidgetOrder(newOrder);
                  },
                  children: [
                    for (int i = 0; i < widgets.length; i++)
                      _buildDraggableSliderCard(
                        key: ValueKey(widgets[i].id),
                        context: context,
                        data: widgets[i],
                      ),
                  ],
                ),
              ),
              
              // Reset button (fixed at bottom)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: OutlinedButton.icon(
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
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildDraggableSliderCard({
    required Key key,
    required BuildContext context,
    required _WidgetSliderData data,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Drag handle
              const Icon(Icons.drag_handle, color: Colors.grey, size: 28),
              const SizedBox(width: 12),
              
              // Slider content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (data.max > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.dguGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              data.value.toInt().toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (data.max > 1) ...[
                      const SizedBox(height: 8),
                      Slider(
                        value: data.value,
                        min: 0,
                        max: data.max,
                        divisions: data.max.toInt(),
                        activeColor: AppTheme.dguGreen,
                        label: data.value.toInt().toString(),
                        onChanged: data.onChanged,
                      ),
                      Text(
                        data.value.toInt() == 0 
                            ? 'Skjult (0 elementer)'
                            : 'Viser ${data.value.toInt()} element${data.value.toInt() > 1 ? 'er' : ''}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Altid synlig',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper class to hold widget slider configuration
class _WidgetSliderData {
  final String id;
  final String title;
  final double value;
  final double max;
  final ValueChanged<double> onChanged;
  
  _WidgetSliderData({
    required this.id,
    required this.title,
    required this.value,
    required this.max,
    required this.onChanged,
  });
}

