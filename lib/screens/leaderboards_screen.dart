import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friends_provider.dart';
import '../models/leaderboard_entry.dart';
import '../theme/app_theme.dart';

/// Leaderboards Screen - Full-screen view of friend leaderboards
/// Displays 3 tabs: Lowest Handicap, Biggest Improvement, Best Scores
class LeaderboardsScreen extends StatefulWidget {
  const LeaderboardsScreen({super.key});

  @override
  State<LeaderboardsScreen> createState() => _LeaderboardsScreenState();
}

class _LeaderboardsScreenState extends State<LeaderboardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboards'),
        backgroundColor: AppTheme.dguGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Laveste HCP'),
            Tab(text: 'Største Fremgang'),
            Tab(text: 'Bedste Scores'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _LeaderboardTab(type: LeaderboardType.lowestHandicap),
          _LeaderboardTab(type: LeaderboardType.biggestImprovement),
          _LeaderboardTab(type: LeaderboardType.bestScores),
        ],
      ),
    );
  }
}

/// Individual leaderboard tab - displays entries for a specific type
class _LeaderboardTab extends StatelessWidget {
  final LeaderboardType type;

  const _LeaderboardTab({required this.type});

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendsProvider>(
      builder: (context, friendsProvider, child) {
        // Loading state
        if (friendsProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.dguGreen),
          );
        }

        // Get leaderboard data
        final leaderboard = _getLeaderboard(friendsProvider);

        // Empty state
        if (leaderboard.isEmpty) {
          return _buildEmptyState(context);
        }

        // Leaderboard list
        return RefreshIndicator(
          onRefresh: () async {
            // Reload friends data
            final player = context.read<FriendsProvider>().friends.firstOrNull;
            if (player != null) {
              await friendsProvider.loadFriends(player.unionId);
            }
          },
          color: AppTheme.dguGreen,
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final entry = leaderboard[index];
              return _LeaderboardTile(
                entry: entry,
                isCurrentUser: false, // TODO: Check if current user
              );
            },
          ),
        );
      },
    );
  }

  /// Get appropriate leaderboard based on type
  List<LeaderboardEntry> _getLeaderboard(FriendsProvider provider) {
    switch (type) {
      case LeaderboardType.lowestHandicap:
        return provider.getLowestHandicapLeaderboard(limit: 50);
      case LeaderboardType.biggestImprovement:
        return provider.getBiggestImprovementLeaderboard(limit: 50);
      case LeaderboardType.bestScores:
        return provider.getBestScoresLeaderboard(limit: 50);
    }
  }

  /// Empty state when no friends or data
  Widget _buildEmptyState(BuildContext context) {
    String title;
    String subtitle;

    switch (type) {
      case LeaderboardType.lowestHandicap:
        title = 'Ingen venner endnu';
        subtitle = 'Tilføj venner for at se hvem der har laveste handicap';
        break;
      case LeaderboardType.biggestImprovement:
        title = 'Ingen fremgang at vise';
        subtitle = 'Dine venner skal sænke deres handicap for at dukke op her';
        break;
      case LeaderboardType.bestScores:
        title = 'Ingen scores at vise';
        subtitle = 'Kommer snart!';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == LeaderboardType.lowestHandicap
                  ? Icons.emoji_events_outlined
                  : Icons.trending_down,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual leaderboard entry tile
class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const _LeaderboardTile({
    required this.entry,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: isCurrentUser ? 4 : 1,
      color: isCurrentUser ? AppTheme.dguGreen.withOpacity(0.1) : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // Rank or trophy
        leading: SizedBox(
          width: 50,
          child: Center(
            child: entry.rank <= 3
                ? Text(
                    entry.trophyEmoji,
                    style: const TextStyle(fontSize: 32),
                  )
                : Text(
                    '#${entry.rank}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
          ),
        ),
        // Name and club
        title: Text(
          entry.name,
          style: TextStyle(
            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: entry.homeClubName != null
            ? Text(
                entry.homeClubName!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        // Value (HCP or improvement)
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getValueColor(),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            entry.displayValue,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getValueTextColor(),
            ),
          ),
        ),
      ),
    );
  }

  /// Get background color for value chip based on rank
  Color _getValueColor() {
    if (entry.rank == 1) return Colors.amber.shade100;
    if (entry.rank == 2) return Colors.grey.shade200;
    if (entry.rank == 3) return Colors.orange.shade100;
    return AppTheme.dguGreen.withOpacity(0.1);
  }

  /// Get text color for value chip
  Color _getValueTextColor() {
    if (entry.rank == 1) return Colors.amber.shade900;
    if (entry.rank == 2) return Colors.grey.shade800;
    if (entry.rank == 3) return Colors.orange.shade900;
    return AppTheme.dguGreen;
  }
}

