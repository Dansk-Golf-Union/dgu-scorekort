import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoggingIn = false;
  final _unionIdController = TextEditingController();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  String? _lastProcessedCode; // Prevent processing same OAuth code multiple times
  bool _isProcessingCallback = false; // Prevent concurrent callback processing
  
  // TODO(ios-oauth-loop): Deep link listener placement in StatefulWidget causes rebuild loop
  // These guards reset on every widget rebuild, creating multiple active listeners.
  // See docs/IOS_OAUTH_LOGIN_LOOP_ISSUE.md for detailed analysis and solution.
  // Recommended fix: Move listener to AuthProvider or singleton service.

  @override
  void initState() {
    super.initState();
    
    // Initialize deep link handler (works on iOS, Android, Web)
    _appLinks = AppLinks();
    
    // Check for OAuth callback on page load (web fallback)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForCallback();
      _initDeepLinkListener(); // iOS/Android deep links
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _unionIdController.dispose();
    super.dispose();
  }

  /// Check if URL contains OAuth callback code (WEB ONLY)
  /// For iOS/Android, use _initDeepLinkListener() instead
  void _checkForCallback() async {
    if (!kIsWeb) {
      debugPrint('📱 Native platform: Skipping Uri.base check (uses deep links)');
      return; // Native platforms use deep link listener
    }
    
    debugPrint('🌐 Web platform: Checking Uri.base for OAuth params');
    final uri = Uri.base;
    if (uri.queryParameters.containsKey('code')) {
      final code = uri.queryParameters['code']!;
      final state = uri.queryParameters['state'];
      debugPrint('✅ OAuth callback detected via Uri.base');
      final authProvider = context.read<AuthProvider>();
      await authProvider.handleCallback(code, state);
      
      if (authProvider.isAuthenticated && mounted) {
        // The main app will handle navigation via Consumer
      }
    }
  }

  /// Initialize deep link listener for iOS/Android
  /// Web uses Uri.base check as fallback
  /// 
  /// WARNING: This creates a NEW listener on every widget rebuild, causing OAuth loop.
  /// See docs/IOS_OAUTH_LOGIN_LOOP_ISSUE.md for details.
  /// TODO(ios-oauth-loop): Move to AuthProvider.initDeepLinkListener() called from main()
  void _initDeepLinkListener() async {
    if (kIsWeb) {
      debugPrint('🌐 Web platform: Using Uri.base for OAuth detection');
      return; // Web doesn't need deep link listener
    }
    
    debugPrint('📱 Native platform: Initializing deep link listener');
    
    // Handle initial link if app was opened via deep link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('📱 Initial deep link: $initialUri');
        await _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('⚠️ Error getting initial link: $e');
    }
    
    // Listen for deep links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        debugPrint('📱 Deep link received: $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('⚠️ Deep link error: $err');
      },
    );
  }

  /// Handle deep link from iOS/Android (dgupoc://login?code=XXX&state=YYY)
  /// Process deep link from iOS app
  /// 
  /// KNOWN ISSUE: Guards (_lastProcessedCode, _isProcessingCallback) reset on widget rebuild.
  /// This causes the same OAuth code to be processed multiple times, leading to invalid_grant errors.
  /// See docs/IOS_OAUTH_LOGIN_LOOP_ISSUE.md for timeline analysis and Xcode console output.
  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint('📱 Handling deep link: ${uri.toString()}');
    debugPrint('   Scheme: ${uri.scheme}');
    debugPrint('   Host: ${uri.host}');
    debugPrint('   Path: ${uri.path}');
    debugPrint('   Query params: ${uri.queryParameters}');
    
    // Only handle dgupoc:// scheme
    if (uri.scheme != 'dgupoc') {
      debugPrint('⚠️ Ignoring non-dgupoc scheme: ${uri.scheme}');
      return;
    }
    
    // Check if this is OAuth callback (dgupoc://login?code=...)
    if (uri.host == 'login' && uri.queryParameters.containsKey('code')) {
      final code = uri.queryParameters['code']!;
      final state = uri.queryParameters['state'];
      
      debugPrint('✅ OAuth callback detected via deep link');
      debugPrint('   Code: ${code.substring(0, 10)}...');
      debugPrint('   State: ${state?.substring(0, 20) ?? 'null'}...');
      
      // Prevent processing same code multiple times (iOS can fire deep links repeatedly)
      // NOTE: This guard FAILS on widget rebuild - see docs/IOS_OAUTH_LOGIN_LOOP_ISSUE.md
      if (_lastProcessedCode == code) {
        debugPrint('⚠️ Ignoring duplicate OAuth code - already processed');
        return;
      }
      
      // Prevent concurrent processing
      // NOTE: This guard FAILS on widget rebuild - see docs/IOS_OAUTH_LOGIN_LOOP_ISSUE.md
      if (_isProcessingCallback) {
        debugPrint('⚠️ Callback already in progress - ignoring duplicate');
        return;
      }
      
      if (!mounted) return;
      
      _isProcessingCallback = true;
      _lastProcessedCode = code;
      
      try {
        final authProvider = context.read<AuthProvider>();
        await authProvider.handleCallback(code, state);
        
        // Navigation handled by main.dart redirect logic
        if (authProvider.isAuthenticated && mounted) {
          debugPrint('✅ Authentication successful');
        } else if (authProvider.needsUnionId && mounted) {
          debugPrint('✅ OAuth token received, awaiting DGU-nummer');
        }
      } finally {
        _isProcessingCallback = false;
      }
    } else {
      debugPrint('⚠️ Deep link is not OAuth callback: ${uri.toString()}');
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
                  
                  // Login button - ONLY show if NOT waiting for unionId
                  if (!authProvider.needsUnionId) ...[
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
                  ],
                  
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
                  
                  // DGU-nummer input (after OAuth success)
                  if (authProvider.needsUnionId && !authProvider.isLoading) ...[
                    const SizedBox(height: 32),
                    const Text(
                      '✅ Login lykkedes!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Indtast dit DGU-nummer igen for at fortsætte',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _unionIdController,
                      decoration: InputDecoration(
                        labelText: 'DGU-nummer (f.eks. 177-2813)',
                        hintText: 'Indtast dit DGU-nummer',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.badge),
                      ),
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (value) async {
                        if (value.trim().isNotEmpty) {
                          await authProvider.loginWithUnionIdAfterOAuth(value.trim());
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: () async {
                          final unionId = _unionIdController.text.trim();
                          if (unionId.isNotEmpty) {
                            await authProvider.loginWithUnionIdAfterOAuth(unionId);
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.dguGreen,
                        ),
                        child: const Text(
                          'Fortsæt',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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

