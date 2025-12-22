import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../models/chat_group.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'create_chat_group_screen.dart';

class ChatGroupsScreen extends StatefulWidget {
  const ChatGroupsScreen({super.key});

  @override
  State<ChatGroupsScreen> createState() => _ChatGroupsScreenState();
}

class _ChatGroupsScreenState extends State<ChatGroupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final authProvider = context.watch<AuthProvider>();
    final myUnionId = authProvider.currentPlayer?.unionId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mine Chats', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: chatProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.dguGreen))
          : chatProvider.groups.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: chatProvider.groups.length,
                  itemBuilder: (context, index) {
                    final group = chatProvider.groups[index];
                    return Dismissible(
                      key: Key(group.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.orange,
                        child: const Icon(Icons.archive, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Arkiver chat?'),
                            content: const Text(
                              'Chatten skjules, men du kan få den tilbage hvis nogen sender en besked.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Annuller'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Arkiver'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        chatProvider.hideChat(group.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chat arkiveret')),
                        );
                      },
                      child: _buildGroupCard(group, myUnionId),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateChatGroupScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Ny Chat'),
      ),
    );
  }

  Widget _buildGroupCard(ChatGroup group, String? myUnionId) {
    final unreadCount = myUnionId != null ? group.getUnreadCountForUser(myUnionId) : 0;
    final hasUnread = unreadCount > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.dguGreen,
          child: Text(
            group.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          group.name,
          style: TextStyle(
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: group.lastMessage != null
            ? Text(
                group.lastMessage!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                ),
              )
            : const Text('Ingen beskeder endnu'),
        trailing: hasUnread
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.dguGreen,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(group: group),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Ingen chats endnu',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Start en chat med dine venner',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

