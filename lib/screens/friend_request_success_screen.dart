import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FriendRequestSuccessScreen extends StatelessWidget {
  final String friendName;
  final String relationType; // NEW: 'contact' | 'friend'

  const FriendRequestSuccessScreen({
    super.key,
    required this.friendName,
    required this.relationType, // NEW
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 32),
              
              // Success message (dynamic based on relation type)
              Text(
                relationType == 'contact'
                    ? 'I er nu kontakter!'
                    : 'Du er nu venner!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dguGreen,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                relationType == 'contact'
                    ? 'I kan nu chatte om golf og planlægge runder sammen.'
                    : 'Du følger nu $friendName\'s handicap.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Close button (for webview)
              TextButton(
                onPressed: () {
                  // Close webview (if possible)
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Luk',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

