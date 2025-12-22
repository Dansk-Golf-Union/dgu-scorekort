import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull
import '../models/chat_group.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import 'auth_provider.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final AuthProvider _authProvider;

  List<ChatGroup> _groups = [];
  bool _isLoading = false;
  String? _errorMessage;

  ChatProvider(this._authProvider);

  // Getters
  List<ChatGroup> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Total unread count across all groups
  int get totalUnreadCount {
    final myUnionId = _authProvider.currentPlayer?.unionId;
    if (myUnionId == null) return 0;
    return _groups.fold(0, (sum, group) => sum + group.getUnreadCountForUser(myUnionId));
  }

  /// Load user's groups (called on init)
  Future<void> loadGroups() async {
    final unionId = _authProvider.currentPlayer?.unionId;
    if (unionId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Start listening to groups
      _chatService.streamUserGroups(unionId).listen((groups) {
        _groups = groups;
        _errorMessage = null;
        notifyListeners();
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create new group
  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
  }) async {
    final myUnionId = _authProvider.currentPlayer?.unionId;
    if (myUnionId == null) throw Exception('Not authenticated');

    // Ensure creator is in members list
    final allMembers = {...memberIds, myUnionId}.toList();

    return await _chatService.createGroup(
      name: name,
      memberIds: allMembers,
      createdBy: myUnionId,
    );
  }

  /// Get single group by ID
  Future<ChatGroup?> getGroup(String groupId) async {
    return await _chatService.getGroup(groupId);
  }

  /// Add member to group
  Future<void> addMember(String groupId, String unionId) async {
    await _chatService.addMemberToGroup(groupId, unionId);
  }

  /// Remove member from group
  Future<void> removeMember(String groupId, String unionId) async {
    await _chatService.removeMemberFromGroup(groupId, unionId);
  }

  /// Hide chat (archive)
  Future<void> hideChat(String groupId) async {
    final unionId = _authProvider.currentPlayer?.unionId;
    if (unionId == null) return;
    
    await _chatService.hideChat(groupId, unionId);
  }

  /// Send message (with auto-unhide)
  Future<void> sendMessage(String groupId, String text) async {
    final player = _authProvider.currentPlayer;
    if (player == null) throw Exception('Not authenticated');

    final unionId = player.unionId;
    final playerName = player.name;
    
    if (unionId == null || unionId.isEmpty) {
      throw Exception('Union ID not found');
    }

    // Send message
    await _chatService.sendMessage(
      groupId: groupId,
      text: text,
      senderId: unionId,
      senderName: playerName,
    );
    
    // Auto-unhide for all members (in case it was archived)
    final group = _groups.firstWhereOrNull((g) => g.id == groupId);
    if (group != null) {
      for (final memberId in group.members) {
        if (group.hiddenFor.contains(memberId)) {
          await _chatService.unhideChat(groupId, memberId);
        }
      }
    }
  }

  /// Mark messages as read
  Future<void> markAsRead(String groupId) async {
    final unionId = _authProvider.currentPlayer?.unionId;
    if (unionId == null) return;

    await _chatService.markMessagesAsRead(groupId, unionId);
  }

  /// Stream messages for a group
  Stream<List<ChatMessage>> streamMessages(String groupId) {
    return _chatService.streamMessages(groupId);
  }
}

