import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/friends_provider.dart';
import '../models/activity_item_model.dart';
import '../widgets/activity_card.dart';
import '../widgets/dgu_hero_banner.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  ActivityType? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final friendsProvider = context.watch<FriendsProvider>();

    // Get list of friend union IDs
    final friendIds = friendsProvider.friends.map((f) => f.unionId).toList();

    // Add current user to see own activities
    friendIds.add(authProvider.currentPlayer?.unionId ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitetsfeed', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Hero Banner
          DguHeroBanner(
            title: 'Aktivitetsfeed',
            subtitle: 'Følg med i hvad dine venner laver',
            height: 170,
            showFlag: true,
          ),
          // Filter chips
          _buildFilterChips(),
          // Activity feed
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('activities')
                  // TEMP: Show all activities (whereIn filter removed until proper index is created)
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildError(snapshot.error.toString());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final activities = snapshot.data!.docs
                    .map((doc) => ActivityItem.fromFirestore(doc))
                    .where((activity) => !activity.isDismissed)
                    // Filter to only show activities from friends (client-side filtering)
                    .where((activity) => friendIds.contains(activity.userId))
                    .toList();

                // Apply type filter
                final filteredActivities = _selectedFilter == null
                    ? activities
                    : activities.where((a) => a.type == _selectedFilter).toList();

                if (filteredActivities.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // Firestore stream handles auto-refresh
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    itemCount: filteredActivities.length,
                    itemBuilder: (context, index) {
                      final activity = filteredActivities[index];
                      return ActivityCard(activity: activity);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterChip(
            label: const Text('Alle'),
            selected: _selectedFilter == null,
            onSelected: (selected) {
              setState(() => _selectedFilter = null);
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('🏆 Milestones'),
            selected: _selectedFilter == ActivityType.milestone,
            onSelected: (selected) {
              setState(() => _selectedFilter = selected ? ActivityType.milestone : null);
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('📉 Forbedringer'),
            selected: _selectedFilter == ActivityType.improvement,
            onSelected: (selected) {
              setState(() => _selectedFilter = selected ? ActivityType.improvement : null);
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('🦅 Eagles'),
            selected: _selectedFilter == ActivityType.eagle,
            onSelected: (selected) {
              setState(() => _selectedFilter = selected ? ActivityType.eagle : null);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rss_feed, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Ingen aktiviteter endnu',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Feed opdateres hver nat med venners milestones',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text('Kunne ikke hente aktiviteter', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text(error, style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

