import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friends_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/friend_card.dart';
import '../widgets/add_friend_dialog.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  @override
  void initState() {
    super.initState();
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
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final authProvider = context.read<AuthProvider>();
          final unionId = authProvider.currentPlayer?.unionId;
          if (unionId != null) {
            await friendsProvider.loadFriends(unionId);
          }
        },
        child: _buildBody(friendsProvider),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFriendDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Tilføj Ven'),
      ),
    );
  }

  Widget _buildBody(FriendsProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (provider.friends.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      itemCount: provider.friends.length,
      itemBuilder: (context, index) {
        final friend = provider.friends[index];
        return FriendCard(friend: friend);
      },
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

  void _showAddFriendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddFriendDialog(),
    );
  }
}

