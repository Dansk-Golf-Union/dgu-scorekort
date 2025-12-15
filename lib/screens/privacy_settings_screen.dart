import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/friends_provider.dart';
import '../providers/auth_provider.dart';
import '../models/friend_profile_model.dart';
import '../theme/app_theme.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentPlayer?.unionId != null) {
        context.read<FriendsProvider>().loadFriends(
          authProvider.currentPlayer!.unionId!,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final friendsProvider = context.watch<FriendsProvider>();
    final authProvider = context.watch<AuthProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Samtykke'),
        backgroundColor: AppTheme.dguGreen,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => friendsProvider.loadFriends(
          authProvider.currentPlayer!.unionId!,
        ),
        child: ListView(
          children: [
            // Info card
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.dguGreen),
                        const SizedBox(width: 8),
                        const Text(
                          'Datadeling',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Dine venner kan se:\n'
                      '• Dit nuværende handicap\n'
                      '• Din handicap historik\n'
                      '• Dine seneste scorekort\n\n'
                      'Du kan til enhver tid fjerne venner og trække dit samtykke tilbage.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            // Master toggle
            SwitchListTile(
              title: const Text('Del handicap med venner'),
              subtitle: const Text(
                'Når slået fra kan ingen venner se dit handicap',
              ),
              value: friendsProvider.shareHandicapWithFriends,
              onChanged: (value) {
                friendsProvider.updatePrivacySettings(
                  authProvider.currentPlayer!.unionId!,
                  value,
                );
              },
            ),
            
            const Divider(),
            
            // Friends list header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Personer der kan se dit handicap (${friendsProvider.friends.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            
            // Friends list (= people who can see my data)
            if (friendsProvider.friends.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Ingen venner endnu',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...friendsProvider.friends.map((friend) => 
                _buildFriendPrivacyCard(context, friend),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFriendPrivacyCard(BuildContext context, FriendProfile friend) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.dguGreen,
          child: Text(
            friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(friend.name),
        subtitle: Text('Venner siden ${_formatDate(friend.createdAt)}'),
        trailing: OutlinedButton(
          onPressed: () => _confirmRemoveFriend(context, friend),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
          ),
          child: const Text('Fjern'),
        ),
      ),
    );
  }
  
  Future<void> _confirmRemoveFriend(BuildContext context, FriendProfile friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fjern ven og træk samtykke tilbage?'),
        content: Text(
          '${friend.name} vil ikke længere kunne se dit handicap.\n\n'
          'Du vil heller ikke længere kunne se deres handicap.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuller'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Fjern'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    final friendsProvider = context.read<FriendsProvider>();
    
    try {
      await friendsProvider.removeFriend(friend.friendshipId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${friend.name} fjernet'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fejl: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  String _formatDate(DateTime? date) {
    if (date == null) return 'Ukendt';
    return DateFormat('d. MMM yyyy').format(date);
  }
}

