import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friends_provider.dart';
import '../providers/auth_provider.dart';
import '../services/player_service.dart';
import '../models/player_model.dart';
import '../theme/app_theme.dart';

/// Dialog for adding a new friend by DGU number
///
/// Flow:
/// 1. User enters DGU number (e.g., "72-4197")
/// 2. Validates format (XXX-XXXXXX)
/// 3. Validates player exists via GetPlayer API
/// 4. Shows preview: "Jonas Meyer (HCP 12.0)"
/// 5. Confirms send request
/// 6. Sends friend request to Firestore
/// 7. Triggers push notification via Cloud Function
class AddFriendDialog extends StatefulWidget {
  const AddFriendDialog({super.key});

  @override
  State<AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<AddFriendDialog> {
  final TextEditingController _dguNumberController = TextEditingController();
  final _playerService = PlayerService();
  
  bool _isLoading = false;
  String? _errorMessage;
  Player? _previewPlayer;

  @override
  void dispose() {
    _dguNumberController.dispose();
    super.dispose();
  }

  Future<void> _validateAndPreview() async {
    final dguNumber = _dguNumberController.text.trim();
    
    // Validate format
    if (!RegExp(r'^\d{1,3}-\d{1,6}$').hasMatch(dguNumber)) {
      setState(() => _errorMessage = 'Ugyldigt format (XXX-XXXXXX)');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final player = await _playerService.fetchPlayerByUnionId(dguNumber);
      setState(() {
        _previewPlayer = player;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Kunne ikke finde spiller';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendFriendRequest() async {
    // Show relation type dialog
    final relationType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hvordan vil du tilføje spilleren?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('💬', style: TextStyle(fontSize: 24)),
              title: const Text('Som chat kontakt'),
              subtitle: const Text('Kan kun chatte, ser ikke handicap'),
              onTap: () => Navigator.pop(context, 'contact'),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Text('👥', style: TextStyle(fontSize: 24)),
              title: const Text('Som ven'),
              subtitle: const Text('Kan chatte + se handicap'),
              onTap: () => Navigator.pop(context, 'friend'),
            ),
          ],
        ),
      ),
    );
    
    if (relationType == null) return; // User cancelled
    
    print('🔍 [AddFriendDialog] User selected relationType: $relationType');
    
    // Send request with selected relation type
    final authProvider = context.read<AuthProvider>();
    final friendsProvider = context.read<FriendsProvider>();
    
    setState(() => _isLoading = true);
    
    try {
      final unionId = authProvider.currentPlayer?.unionId;
      if (unionId == null) {
        throw Exception('Ikke logget ind');
      }
      
      print('🔍 [AddFriendDialog] Sending friend request:');
      print('   fromUserId: $unionId');
      print('   toUserId: ${_previewPlayer!.unionId}');
      print('   relationType: $relationType');
      
      await friendsProvider.sendFriendRequest(
        fromUserId: unionId,
        fromUserName: authProvider.currentPlayer!.name,
        toUserId: _previewPlayer!.unionId,
        toUserName: _previewPlayer!.name,
        relationType: relationType, // NEW: Pass selected type
      );
      
      if (mounted) {
        Navigator.pop(context);
        final typeLabel = relationType == 'friend' ? 'Venneanmodning' : 'Kontaktanmodning';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$typeLabel sendt til ${_previewPlayer!.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Kunne ikke sende anmodning: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.person_add,
            color: AppTheme.dguGreen,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('Tilføj Ven'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _dguNumberController,
            decoration: InputDecoration(
              labelText: 'DGU Nummer',
              hintText: '123-4567',
              errorText: _errorMessage,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {
              _errorMessage = null;
              _previewPlayer = null;
            }),
          ),
          if (_isLoading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_previewPlayer != null) ...[
            const SizedBox(height: 16),
            _buildPreview(),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuller'),
        ),
        if (_previewPlayer == null)
          ElevatedButton(
            onPressed: _isLoading ? null : _validateAndPreview,
            child: const Text('Søg'),
          )
        else
          ElevatedButton(
            onPressed: _sendFriendRequest,
            child: const Text('Send Anmodning'),
          ),
      ],
    );
  }

  Widget _buildPreview() {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(_previewPlayer!.name[0]),
        ),
        title: Text(_previewPlayer!.name),
        subtitle: Text('HCP ${_previewPlayer!.hcp.toStringAsFixed(1)}'),
      ),
    );
  }
}
