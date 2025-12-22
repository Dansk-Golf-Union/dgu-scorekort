import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friends_provider.dart';
import '../services/friends_service.dart';
import '../theme/app_theme.dart';
import 'friend_request_success_screen.dart';

/// Screen for accepting/declining friend requests via deep link
///
/// Similar to marker_approval_from_url_screen.dart but for friend requests.
/// Accessed via deep link: /friend-request/:requestId
///
/// Flow:
/// 1. User receives push notification
/// 2. Taps notification → Opens app via deep link
/// 3. Shows friend request with explicit consent message
/// 4. User accepts → Creates friendship
/// 5. User declines → Deletes request
class FriendRequestFromUrlScreen extends StatefulWidget {
  final String requestId;

  const FriendRequestFromUrlScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<FriendRequestFromUrlScreen> createState() =>
      _FriendRequestFromUrlScreenState();
}

class _FriendRequestFromUrlScreenState
    extends State<FriendRequestFromUrlScreen> {
  final FriendsService _friendsService = FriendsService();
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  Map<String, dynamic>? _requestData;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final request = await _friendsService.getFriendRequest(widget.requestId);

      if (!mounted) return;

      if (request == null) {
        setState(() {
          _errorMessage = 'Venneanmodning ikke fundet';
          _isLoading = false;
        });
        return;
      }

      // Check if already processed
      if (request.status != 'pending') {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Denne anmodning er allerede ${request.status == 'accepted' ? 'accepteret' : 'afvist'}';
          _isLoading = false;
        });
        return;
      }

      print('🔍 [FriendRequestScreen] Request loaded:');
      print('   requestId: ${request.id}');
      print('   fromUserId: ${request.fromUserId}');
      print('   toUserId: ${request.toUserId}');
      print('   requestedRelationType: ${request.requestedRelationType}');
      
      if (!mounted) return;
      setState(() {
        _requestData = {
          'id': request.id,
          'fromUserId': request.fromUserId,
          'fromUserName': request.fromUserName,
          'toUserId': request.toUserId,
          'toUserName': request.toUserName,
          'status': request.status,
          'consentMessage': request.consentMessage,
          'createdAt': request.createdAt,
          'requestedRelationType': request.requestedRelationType, // NEW: Add this!
        };
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Fejl ved hentning af anmodning: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAccept() async {
    if (_isProcessing) return;
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final friendsProvider = context.read<FriendsProvider>();
      await friendsProvider.acceptFriendRequest(widget.requestId);

      if (mounted) {
        // Show success screen (not snackbar)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => FriendRequestSuccessScreen(
              friendName: _requestData!['fromUserName'],
              relationType: _requestData!['requestedRelationType'] ?? 'friend', // NEW
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Fejl ved accept: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleDecline() async {
    if (_isProcessing) return;
    if (!mounted) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Afvis venneanmodning?'),
        content: Text(
          'Er du sikker på at du vil afvise anmodningen fra ${_requestData!['fromUserName']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuller'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Afvis'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final friendsProvider = context.read<FriendsProvider>();
      await friendsProvider.declineFriendRequest(widget.requestId);

      if (mounted) {
        // Show simple info screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline, size: 80, color: Colors.grey),
                      const SizedBox(height: 24),
                      const Text(
                        'Anmodning afvist',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 48),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Luk'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Fejl ved afvisning: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Venneanmodning'),
        backgroundColor: AppTheme.dguGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.dguGreen,
              ),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : _buildRequestContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Tilbage'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.dguGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestContent() {
    final fromUserName = _requestData!['fromUserName'] as String;
    final consentMessage = _requestData!['consentMessage'] as String;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.dguGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 60,
              color: AppTheme.dguGreen,
            ),
          ),
          const SizedBox(height: 24),

          // User name
          Text(
            fromUserName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Main message (dynamic based on relation type)
          Text(
            _requestData!['requestedRelationType'] == 'contact'
                ? 'vil gerne chatte med dig om golf'
                : 'vil følge dit handicap',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Consent message card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.dguGreen,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Samtykke til datadeling',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    consentMessage,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Error message (if any)
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Action buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _isProcessing ? null : _handleAccept,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _isProcessing ? 'Behandler...' : 'Accepter og del handicap',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.dguGreen,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _handleDecline,
                  icon: const Icon(Icons.close),
                  label: const Text('Afvis'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

