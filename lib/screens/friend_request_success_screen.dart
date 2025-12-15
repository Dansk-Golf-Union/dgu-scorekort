import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class FriendRequestSuccessScreen extends StatelessWidget {
  final String friendName;

  const FriendRequestSuccessScreen({
    super.key,
    required this.friendName,
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
              
              // Success message
              Text(
                'Du er nu venner!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dguGreen,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'Du følger nu $friendName\'s handicap.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Link to POC app
              FilledButton.icon(
                onPressed: () {
                  // Navigate to home using go_router
                  context.go('/');
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Åbn DGU App'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.dguGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () {
                  // Close webview (if possible)
                  Navigator.of(context).pop();
                },
                child: const Text('Luk'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

