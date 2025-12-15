import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friends_provider.dart';
import '../providers/auth_provider.dart';
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
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _dguNumberController.dispose();
    super.dispose();
  }

  /// Validates DGU number format (XXX-XXXXXX)
  bool _isValidDguNumber(String input) {
    final regex = RegExp(r'^\d{1,3}-\d{1,6}$');
    return regex.hasMatch(input.trim());
  }

  Future<void> _handleSendRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final dguNumber = _dguNumberController.text.trim();

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final friendsProvider = context.read<FriendsProvider>();

      final currentUser = authProvider.currentPlayer;
      if (currentUser == null) {
        throw Exception('Ikke logget ind');
      }

      // Send friend request
      await friendsProvider.sendFriendRequest(
        fromUserId: currentUser.unionId!,
        fromUserName: currentUser.name,
        toUnionId: dguNumber,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Venneanmodning sendt! 🎉'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Close dialog
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isProcessing = false;
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
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Indtast DGU nummer på den spiller du vil tilføje som ven.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _dguNumberController,
              decoration: const InputDecoration(
                labelText: 'DGU Nummer',
                hintText: 'F.eks. 72-4197',
                helperText: 'Format: XXX-XXXXXX',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              enabled: !_isProcessing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Indtast DGU nummer';
                }
                if (!_isValidDguNumber(value)) {
                  return 'Ugyldigt format. Brug: XXX-XXXXXX';
                }
                return null;
              },
              onFieldSubmitted: (_) => _handleSendRequest(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuller'),
        ),
        FilledButton.icon(
          onPressed: _isProcessing ? null : _handleSendRequest,
          icon: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send),
          label: Text(_isProcessing ? 'Sender...' : 'Send Anmodning'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.dguGreen,
          ),
        ),
      ],
    );
  }
}


