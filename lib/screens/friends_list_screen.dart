import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friends_provider.dart';
import '../providers/auth_provider.dart';
import '../models/friend_profile_model.dart';
import '../widgets/add_friend_dialog.dart';
import '../screens/friend_detail_screen.dart';
import '../theme/app_theme.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load friends on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final unionId = authProvider.currentPlayer?.unionId;
      if (unionId != null) {
        context.read<FriendsProvider>().loadFriends(unionId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsProvider = context.watch<FriendsProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mine Venner', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Alle'),
            Tab(text: 'Laveste HCP'),
            Tab(text: 'Største Fremgang'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllFriendsTab(friendsProvider),
          _buildLowestHcpTab(friendsProvider),
          _buildBiggestImprovementTab(friendsProvider),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFriendDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Tilføj Ven'),
      ),
    );
  }

  /// Tab 1: Alle venner (alphabetically sorted, no medals)
  Widget _buildAllFriendsTab(FriendsProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.dguGreen));
    }
    
    if (provider.friends.isEmpty) {
      return _buildEmptyState();
    }
    
    // Sort alphabetically by first name
    final sortedFriends = List<FriendProfile>.from(provider.friends)
      ..sort((a, b) => a.name.compareTo(b.name));
    
    return RefreshIndicator(
      onRefresh: () async {
        final authProvider = context.read<AuthProvider>();
        final unionId = authProvider.currentPlayer?.unionId;
        if (unionId != null) {
          await provider.loadFriends(unionId);
        }
      },
      color: AppTheme.dguGreen,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80), // Space for FAB
        itemCount: sortedFriends.length,
        itemBuilder: (context, index) {
          final friend = sortedFriends[index];
          return _buildSimpleFriendTile(friend);
        },
      ),
    );
  }

  /// Tab 2: Laveste HCP (sorted by handicap)
  Widget _buildLowestHcpTab(FriendsProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.dguGreen));
    }
    
    if (provider.friends.isEmpty) {
      return _buildEmptyState();
    }
    
    // Sort by currentHandicap ascending (lowest first)
    final sortedFriends = List<FriendProfile>.from(provider.friends)
      ..sort((a, b) => a.currentHandicap.compareTo(b.currentHandicap));
    
    return RefreshIndicator(
      onRefresh: () async {
        final authProvider = context.read<AuthProvider>();
        final unionId = authProvider.currentPlayer?.unionId;
        if (unionId != null) {
          await provider.loadFriends(unionId);
        }
      },
      color: AppTheme.dguGreen,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: sortedFriends.length,
        itemBuilder: (context, index) {
          final friend = sortedFriends[index];
          final rank = index + 1;
          return _buildRankedTile(friend, rank, showHcp: true);
        },
      ),
    );
  }

  /// Tab 3: Største Fremgang (sorted by improvement)
  Widget _buildBiggestImprovementTab(FriendsProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.dguGreen));
    }
    
    // Filter friends with negative delta (improvement) and sort
    final improvedFriends = provider.friends
        .where((f) => f.trend.delta != null && f.trend.delta! < 0)
        .toList()
      ..sort((a, b) => a.trend.delta!.compareTo(b.trend.delta!));
    
    if (improvedFriends.isEmpty) {
      return _buildNoImprovementState();
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        final authProvider = context.read<AuthProvider>();
        final unionId = authProvider.currentPlayer?.unionId;
        if (unionId != null) {
          await provider.loadFriends(unionId);
        }
      },
      color: AppTheme.dguGreen,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: improvedFriends.length,
        itemBuilder: (context, index) {
          final friend = improvedFriends[index];
          final rank = index + 1;
          return _buildRankedTile(friend, rank, showImprovement: true);
        },
      ),
    );
  }

  /// Build a simple friend tile without medals (Tab 1 - Alle)
  Widget _buildSimpleFriendTile(FriendProfile friend) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.dguGreen,
          child: Text(
            friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          friend.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          friend.homeClubName ?? 'Ingen klub',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HCP ${friend.currentHandicap.toStringAsFixed(1)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (friend.trend.delta != null) ...[
              const SizedBox(width: 8),
              _buildTrendIndicator(friend.trend.delta!),
            ],
          ],
        ),
        onTap: () => _navigateToFriendDetail(friend),
      ),
    );
  }

  /// Build a ranked tile with medals for top 3 (Tabs 2 & 3)
  Widget _buildRankedTile(
    FriendProfile friend,
    int rank, {
    bool showHcp = false,
    bool showImprovement = false,
  }) {
    final isTopThree = rank <= 3;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: isTopThree ? 3 : 1,
      color: isTopThree ? Colors.amber.shade50 : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: SizedBox(
          width: 50,
          child: Center(
            child: isTopThree
                ? Text(
                    _getMedalEmoji(rank),
                    style: const TextStyle(fontSize: 36),
                  )
                : Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
          ),
        ),
        title: Text(
          friend.name,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              friend.homeClubName ?? 'Ingen klub',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (showImprovement)
              Text(
                'Nu: HCP ${friend.currentHandicap.toStringAsFixed(1)}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: showImprovement ? Colors.green.shade100 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            showImprovement 
                ? friend.trend.deltaDisplay
                : 'HCP ${friend.currentHandicap.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: showImprovement ? Colors.green.shade800 : Colors.grey.shade800,
            ),
          ),
        ),
        onTap: () => _navigateToFriendDetail(friend),
      ),
    );
  }

  /// Get medal emoji for rank
  String _getMedalEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  /// Build trend indicator chip
  Widget _buildTrendIndicator(double delta) {
    final isImprovement = delta < 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isImprovement ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isImprovement ? Icons.trending_down : Icons.trending_up,
            size: 14,
            color: isImprovement ? Colors.green.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 2),
          Text(
            delta.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isImprovement ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Ingen venner endnu',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tilføj venner for at følge deres handicap',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddFriendDialog(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Tilføj Ven'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoImprovementState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Ingen har sænket deres handicap',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Kom tilbage senere!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddFriendDialog(),
    );
  }

  void _navigateToFriendDetail(FriendProfile friend) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FriendDetailScreen(friend: friend),
      ),
    );
  }
}

