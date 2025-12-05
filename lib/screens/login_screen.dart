import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    // Check for OAuth callback on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForCallback();
    });
  }

  /// Check if URL contains OAuth callback code
  void _checkForCallback() async {
    final uri = Uri.base;
    if (uri.queryParameters.containsKey('code')) {
      final code = uri.queryParameters['code']!;
      final authProvider = context.read<AuthProvider>();
      await authProvider.handleCallback(code);
      
      // Navigate to setup screen on success
      if (authProvider.isAuthenticated && mounted) {
        // The main app will handle navigation via Consumer
      }
    }
  }

  /// Start OAuth login flow
  Future<void> _handleLogin() async {
    setState(() {
      _isLoggingIn = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final authUrl = authProvider.startLogin();
      
      // Open OAuth URL in browser
      final url = Uri.parse(authUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kunne ikke åbne login side')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login fejl: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Logger ind...'),
                ],
              ),
            );
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // DGU Logo placeholder
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.dguGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.golf_course,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // App title
                  const Text(
                    'DGU Scorekort',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Digital scorekort til danske golfspillere',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _isLoggingIn ? null : _handleLogin,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.dguGreen,
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: _isLoggingIn
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Log ind med DGU',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                  
                  // Error message
                  if (authProvider.errorMessage != null) ...[
                    const SizedBox(height: 24),
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
                              authProvider.errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 48),
                  
                  // Info text
                  const Text(
                    'Du skal have en aktiv DGU konto for at bruge denne app',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black38,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

