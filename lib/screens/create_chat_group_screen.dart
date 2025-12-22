import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friends_provider.dart';
import '../providers/chat_provider.dart';
import '../models/friend_profile_model.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class CreateChatGroupScreen extends StatefulWidget {
  final List<FriendProfile>? preselectedFriends;

  const CreateChatGroupScreen({
    super.key,
    this.preselectedFriends,
  });

  @override
  State<CreateChatGroupScreen> createState() => _CreateChatGroupScreenState();
}

class _CreateChatGroupScreenState extends State<CreateChatGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final Set<String> _selectedFriendIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Preselect friends if provided
    if (widget.preselectedFriends != null) {
      _selectedFriendIds.addAll(
        widget.preselectedFriends!.map((f) => f.unionId),
      );
      // Auto-fill name for 1-to-1 chats
      if (widget.preselectedFriends!.length == 1) {
        _nameController.text = widget.preselectedFriends![0].name;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsProvider = context.watch<FriendsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ny Chat Gruppe', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _selectedFriendIds.isEmpty ? null : _createGroup,
            child: Text(
              'Opret',
              style: TextStyle(
                color: _selectedFriendIds.isEmpty ? Colors.white38 : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.dguGreen))
          : Column(
              children: [
                // Group name input
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Gruppe navn',
                      hintText: 'F.eks. Fredagsgolf',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.group),
                    ),
                  ),
                ),

                const Divider(),

                // Friend selection
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Text(
                        'Vælg venner',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_selectedFriendIds.length} valgt',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: friendsProvider.friends.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: friendsProvider.friends.length,
                          itemBuilder: (context, index) {
                            final friend = friendsProvider.friends[index];
                            final isSelected = _selectedFriendIds.contains(friend.unionId);
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (selected) {
                                setState(() {
                                  if (selected == true) {
                                    _selectedFriendIds.add(friend.unionId);
                                  } else {
                                    _selectedFriendIds.remove(friend.unionId);
                                  }
                                });
                              },
                              title: Text(friend.name),
                              subtitle: Text(friend.homeClubDisplay),
                              secondary: CircleAvatar(
                                backgroundColor: AppTheme.dguGreen,
                                child: Text(
                                  friend.name[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indtast et gruppe navn')),
      );
      return;
    }

    if (_selectedFriendIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vælg mindst én ven')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final chatProvider = context.read<ChatProvider>();
      final groupId = await chatProvider.createGroup(
        name: name,
        memberIds: _selectedFriendIds.toList(),
      );

      // Fetch the created group directly from Firestore
      final group = await chatProvider.getGroup(groupId);
      
      if (group == null) {
        throw Exception('Kunne ikke oprette gruppe');
      }

      if (!mounted) return;

      // Navigate to chat screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(group: group),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fejl: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Ingen venner endnu',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tilføj venner først',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

