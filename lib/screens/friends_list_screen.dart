import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friends_provider.dart';
import '../providers/auth_provider.dart';
import '../models/friend_profile_model.dart';
import '../models/friend_request_model.dart';
import '../widgets/add_friend_dialog.dart';
import '../screens/friend_detail_screen.dart';
import '../providers/chat_provider.dart';
import 'chat_groups_screen.dart';
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
    
    // Load friends and pending requests on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final unionId = authProvider.currentPlayer?.unionId;
      if (unionId != null) {
        context.read<FriendsProvider>().loadFriends(unionId);
        context.read<FriendsProvider>().loadPendingRequests(unionId);
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
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              final unreadCount = chatProvider.totalUnreadCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChatGroupsScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            const Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Venner'),
                  SizedBox(width: 4),
                  Text('👥', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Kontakter'),
                  SizedBox(width: 4),
                  Text('💬', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Tab(
              child: Consumer<FriendsProvider>(
                builder: (context, provider, _) {
                  final count = provider.pendingRequestsCount;
                  if (count > 0) {
                    return Badge(
                      label: Text('$count'),
                      child: const Text('Anmodninger'),
                    );
                  }
                  return const Text('Anmodninger');
                },
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(friendsProvider),      // Tab 0: Venner (👥)
          _buildContactsTab(friendsProvider),     // Tab 1: Kontakter (💬)
          _buildRequestsTab(friendsProvider),     // Tab 2: Anmodninger
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFriendDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Tilføj Ven'),
      ),
    );
  }

  /// Tab 1: Kun venner (relationType == 'friend')
  Widget _buildFriendsTab(FriendsProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.dguGreen));
    }
    
    final friends = provider.fullFriends;
    
    if (friends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Ingen venner endnu',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tilføj venner for at følge deres handicap',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    // Sort alphabetically
    final sortedFriends = List<FriendProfile>.from(friends)
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
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: sortedFriends.length,
        itemBuilder: (context, index) {
          final friend = sortedFriends[index];
          return _buildContactCard(friend, provider);
        },
      ),
    );
  }

  /// Tab 2: Kun kontakter (relationType == 'contact')
  Widget _buildContactsTab(FriendsProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.dguGreen));
    }
    
    final contacts = provider.contactsOnly;
    
    if (contacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Ingen kontakter endnu',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tilføj kontakter for at kunne chatte',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    // Sort alphabetically
    final sortedContacts = List<FriendProfile>.from(contacts)
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
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: sortedContacts.length,
        itemBuilder: (context, index) {
          final contact = sortedContacts[index];
          return _buildContactCard(contact, provider);
        },
      ),
    );
  }

  /// Tab 3: Pending requests
  Widget _buildRequestsTab(FriendsProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.dguGreen));
    }
    
    final requests = provider.pendingRequests;
    
    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Ingen anmodninger',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Du har ingen ventende venneanmodninger',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildRequestCard(request, provider);
      },
    );
  }

  /// Build contact card with relation type icon
  Widget _buildContactCard(FriendProfile friend, FriendsProvider provider) {
    final friendship = provider.getFriendship(friend.unionId);
    final relationType = friendship?.relationType ?? 'friend';
    final icon = relationType == 'friend' ? '👥' : '💬';
    final showHandicap = relationType == 'friend';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.dguGreen,
              child: Text(
                friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            // Larger icon badge
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: relationType == 'friend' ? Colors.blue.shade100 : Colors.orange.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
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
        trailing: showHandicap
            ? Text(
                'HCP ${friend.currentHandicap.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
        onTap: () => _navigateToFriendDetail(friend),
      ),
    );
  }

  /// Build request card
  Widget _buildRequestCard(FriendRequest request, FriendsProvider provider) {
    final relationType = request.requestedRelationType;
    final icon = relationType == 'friend' ? '👥' : '💬';
    final typeLabel = relationType == 'friend' ? 'Ven' : 'Kontakt';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.dguGreen,
              child: Text(
                request.fromUserName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            // Larger icon badge
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: relationType == 'friend' ? Colors.blue.shade100 : Colors.orange.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
        title: Text(request.fromUserName),
        subtitle: Text(typeLabel, style: TextStyle(
          color: relationType == 'friend' ? Colors.blue : Colors.orange,
          fontWeight: FontWeight.w600,
        )),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => provider.declineFriendRequest(request.id),
              child: const Text('Afvis'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => provider.acceptFriendRequest(request.id),
              child: const Text('Acceptér'),
            ),
          ],
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(request.fromUserName),
              content: Text(request.consentMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Luk'),
                ),
              ],
            ),
          );
        },
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

