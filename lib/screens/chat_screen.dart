import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../models/chat_group.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final ChatGroup group;

  const ChatScreen({super.key, required this.group});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mark as read when opening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().markAsRead(widget.group.id);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final authProvider = context.watch<AuthProvider>();
    final myUnionId = authProvider.currentPlayer?.unionId;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.group.name, style: const TextStyle(color: Colors.white)),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => _GroupMembersSheet(group: widget.group),
                );
              },
              child: Row(
                children: [
                  Text(
                    '${widget.group.members.length} medlemmer',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.info_outline, size: 12, color: Colors.white70),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: chatProvider.streamMessages(widget.group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.dguGreen),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == myUnionId;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),

          // Input field
          _buildInputField(chatProvider),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.dguGreen : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message.senderName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppTheme.dguGreen,
                ),
              ),
            if (!isMe) const SizedBox(height: 4),
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(ChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Skriv en besked...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppTheme.dguGreen,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _sendMessage(chatProvider),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(ChatProvider chatProvider) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      await chatProvider.sendMessage(widget.group.id, text);
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_outlined, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Start samtalen',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0) {
      return DateFormat.Hm().format(timestamp); // "14:30"
    } else if (diff.inDays == 1) {
      return 'I går ${DateFormat.Hm().format(timestamp)}';
    } else if (diff.inDays < 7) {
      return DateFormat.E().add_Hm().format(timestamp); // "Man 14:30"
    } else {
      return DateFormat.MMMd().add_Hm().format(timestamp); // "Jan 5 14:30"
    }
  }
}

/// Group Members Sheet - Shows all members in a modal
class _GroupMembersSheet extends StatelessWidget {
  final ChatGroup group;
  
  const _GroupMembersSheet({required this.group});
  
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Medlemmer (${group.members.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: group.members.length,
                  itemBuilder: (context, index) {
                    final memberId = group.members[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.dguGreen,
                        child: Text(
                          memberId.split('-').first,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      title: Text('Medlem #${memberId}'),
                      subtitle: Text('Union ID: $memberId'),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

