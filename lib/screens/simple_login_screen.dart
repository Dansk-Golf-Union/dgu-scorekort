import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class SimpleLoginScreen extends StatefulWidget {
  const SimpleLoginScreen({super.key});

  @override
  State<SimpleLoginScreen> createState() => _SimpleLoginScreenState();
}

class _SimpleLoginScreenState extends State<SimpleLoginScreen> {
  final TextEditingController _unionIdController = TextEditingController();
  bool _isLoggingIn = false;
  String? _errorMessage;

  @override
  void dispose() {
    _unionIdController.dispose();
    super.dispose();
  }

  /// Validates Union ID format (e.g., 906-223, 72-4197)
  /// Format: 1-3 digits, dash, 1-6 digits
  bool _isValidUnionId(String input) {
    final regex = RegExp(r'^\d{1,3}-\d{1,6}$');
    return regex.hasMatch(input.trim());
  }

  /// Handle login with Union ID
  Future<void> _handleLogin() async {
    setState(() {
      _errorMessage = null;
      _isLoggingIn = true;
    });

    final unionId = _unionIdController.text.trim();

    // Validate format
    if (!_isValidUnionId(unionId)) {
      setState(() {
        _errorMessage = 'Ugyldigt format. Brug format: 906-223';
        _isLoggingIn = false;
      });
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.loginWithUnionId(unionId);

      // Navigation handled by main.dart Consumer
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoggingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // DGU Logo
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
                'DGU App 2.0 POC',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Test af features i kommende version',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Union ID input field
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: TextField(
                  controller: _unionIdController,
                  decoration: InputDecoration(
                    labelText: 'DGU Nummer',
                    hintText: 'F.eks. 123-4567',
                    helperText: 'Format: XXX-XXXXXX',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleLogin(),
                  enabled: !_isLoggingIn,
                ),
              ),
              const SizedBox(height: 24),

              // Login button
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
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
                          'Log ind',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 24),
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
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
              ],

              const SizedBox(height: 48),

              // Info text
              const Text(
                'Indtast dit DGU nummer for at logge ind',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black38,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

