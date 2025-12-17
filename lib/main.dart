import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'config/firebase_options.dart';
import 'providers/match_setup_provider.dart';
import 'providers/scorecard_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/match_play_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/friends_provider.dart';
import 'providers/dashboard_preferences_provider.dart';
import 'models/club_model.dart';
import 'models/course_model.dart';
import 'screens/scorecard_keypad_screen.dart';
import 'screens/scorecard_bulk_screen.dart';
import 'screens/login_screen.dart';
import 'screens/simple_login_screen.dart';
import 'screens/marker_approval_from_url_screen.dart';
import 'screens/match_play_screen.dart';
import 'screens/home_screen.dart';
import 'screens/score_archive_screen.dart';
import 'screens/friend_request_from_url_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/friends_list_screen.dart';
import 'screens/leaderboards_screen.dart';
import 'theme/app_theme.dart';

// Development tip: Toggle between OAuth and SimpleLogin as needed
// - false = OAuth (production, testing OAuth flow)
// - true = SimpleLogin (development convenience, quick refresh)
const bool useSimpleLogin = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Use path-based URLs instead of hash URLs (#/)
  usePathUrlStrategy();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('Firebase initialized successfully');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => FriendsProvider()),
        ChangeNotifierProvider(create: (_) => DashboardPreferencesProvider()..loadPreferences()),
        ChangeNotifierProvider(create: (_) => MatchSetupProvider()),
        ChangeNotifierProvider(create: (_) => ScorecardProvider()),
        ChangeNotifierProvider(create: (_) => MatchPlayProvider()),
      ],
      child: const _AppRouter(),
    );
  }
}

class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    
    // Setup router with auth state
    final router = GoRouter(
      // initialLocation removed to allow deep links to work from external sources
      debugLogDiagnostics: false,
      refreshListenable: authProvider, // Listen to auth changes!
      redirect: (context, state) {
        // NUCLEAR OPTION: Check actual browser URL first (bypasses GoRouter state issues)
        final browserUrl = html.window.location.href;
        
        // If browser URL contains public routes, allow immediate access
        if (browserUrl.contains('/friend-request/')) {
          return null;
        }
        if (browserUrl.contains('/marker-approval/')) {
          return null;
        }
        if (browserUrl.contains('/match-play')) {
          return null;
        }
        
        // Fallback: Check GoRouter state (for normal navigation within app)
        final isMarkerApproval = state.matchedLocation.startsWith('/marker-approval');
        final isMatchPlay = state.matchedLocation.startsWith('/match-play');
        final isFriendRequest = state.matchedLocation.startsWith('/friend-request');
        
        // Allow marker approval, match play, and friend requests without auth
        if (isMarkerApproval || isMatchPlay || isFriendRequest) {
          return null;
        }
        
        // Show loading screen while initializing
        if (authProvider.isLoading) {
          return null; // Stay on current route while loading
        }
        
        // Redirect to login if not authenticated (preserve intended destination)
        if (!authProvider.isAuthenticated && state.matchedLocation != '/login') {
          final loginUrl = '/login?from=${Uri.encodeComponent(state.matchedLocation)}';
          return loginUrl;
        }
        
        // Redirect to intended destination after login
        if (authProvider.isAuthenticated && 
            (state.matchedLocation == '/login' || state.matchedLocation.startsWith('/login'))) {
          final from = state.uri.queryParameters['from'];
          if (from != null && from.isNotEmpty) {
            return from;
          }
        }
        
        // If authenticated and on home, check if there's a stored destination
        if (authProvider.isAuthenticated && state.matchedLocation == '/') {
          // Check if we came from login with a destination
          final fullLocation = state.uri.toString();
          if (fullLocation.contains('from=')) {
            final from = state.uri.queryParameters['from'];
            if (from != null && from.isNotEmpty) {
              return from;
            }
          }
        }
        
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/setup-round',
          builder: (context, state) => const SetupRoundScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => useSimpleLogin 
              ? const SimpleLoginScreen() 
              : const LoginScreen(),
        ),
        GoRoute(
          path: '/match-play',
          builder: (context, state) => const MatchPlayScreen(),
        ),
        GoRoute(
          path: '/marker-approval/:documentId',
          builder: (context, state) {
            final documentId = state.pathParameters['documentId']!;
            return MarkerApprovalFromUrlScreen(documentId: documentId);
          },
        ),
        GoRoute(
          path: '/friend-request/:requestId',
          builder: (context, state) {
            final requestId = state.pathParameters['requestId']!;
            return FriendRequestFromUrlScreen(requestId: requestId);
          },
        ),
        GoRoute(
          path: '/score-archive',
          builder: (context, state) => const ScoreArchiveScreen(),
        ),
        GoRoute(
          path: '/feed',
          builder: (context, state) => const FeedScreen(),
        ),
        GoRoute(
          path: '/venner',
          builder: (context, state) => const FriendsListScreen(),
        ),
        GoRoute(
          path: '/leaderboards',
          builder: (context, state) => const LeaderboardsScreen(),
        ),
      ],
    );
    
    return MaterialApp.router(
      title: 'DGU Scorekort',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class SetupRoundScreen extends StatefulWidget {
  const SetupRoundScreen({super.key});

  @override
  State<SetupRoundScreen> createState() => _SetupRoundScreenState();
}

class _SetupRoundScreenState extends State<SetupRoundScreen> {
  @override
  void initState() {
    super.initState();
    // Load clubs when screen initializes
    // Player info comes from AuthProvider now
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final matchProvider = context.read<MatchSetupProvider>();
      final authProvider = context.read<AuthProvider>();
      
      // Set the authenticated player in match provider
      if (authProvider.currentPlayer != null) {
        matchProvider.setPlayer(authProvider.currentPlayer!);
      }
      
      // Load clubs
      matchProvider.loadClubs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Tilbage',
          onPressed: () {
            // Show confirmation dialog before going back
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Tilbage til forsiden?'),
                content: const Text('Dine valg vil gå tabt.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuller'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      context.go('/'); // Go back to home
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.dguGreen,
                    ),
                    child: const Text('Ja, gå tilbage'),
                  ),
                ],
              ),
            );
          },
        ),
        title: const Text('DGU Scorekort', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.people, color: Colors.white),
            tooltip: 'Match Play / Hulspil',
            onPressed: () {
              context.push('/match-play');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Log ud',
            onPressed: () async {
              await authProvider.logout();
            },
          ),
        ],
      ),
      body: Consumer<MatchSetupProvider>(
        builder: (context, provider, child) {
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  // Step 1: Select Club
                  _buildStepCard(
                    context: context,
                    stepNumber: 1,
                    title: 'Vælg Klub',
                    child: provider.isLoadingClubs
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : provider.clubsError != null
                            ? _buildErrorWidget(
                                context,
                                provider.clubsError!,
                                () => provider.loadClubs(),
                              )
                            : _buildClubDropdown(context, provider),
                  ),
                  const SizedBox(height: 16),

                  // Step 2: Select Course
                  _buildStepCard(
                    context: context,
                    stepNumber: 2,
                    title: 'Vælg Bane',
                    child: provider.selectedClub == null
                        ? _buildDisabledMessage('Vælg først en klub')
                        : provider.isLoadingCourses
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : provider.coursesError != null
                                ? _buildErrorWidget(
                                    context,
                                    provider.coursesError!,
                                    () => provider
                                        .setSelectedClub(provider.selectedClub),
                                  )
                                : _buildCourseDropdown(context, provider),
                  ),
                  const SizedBox(height: 16),

                  // Step 3: Select Tee
                  _buildStepCard(
                    context: context,
                    stepNumber: 3,
                    title: 'Vælg Tee',
                    child: provider.selectedCourse == null
                        ? _buildDisabledMessage('Vælg først en bane')
                        : _buildTeeDropdown(context, provider),
                  ),
                  const SizedBox(height: 16),

                  // Player Info Section
                  _buildPlayerInfoCard(context, provider),
                  const SizedBox(height: 32),

                  // Start Round Buttons (two variants)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: provider.canStartRound
                              ? () => _startRound(context, provider, useBulk: true)
                              : null,
                          icon: const Icon(Icons.table_chart),
                          label: const Text(
                            'Indberet',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.dguGreen,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: provider.canStartRound
                              ? () => _startRound(context, provider, useBulk: false)
                              : null,
                          icon: const Icon(Icons.grid_3x3),
                          label: const Text(
                            'Hul-for-hul',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.dguGreen,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _startRound(BuildContext context, MatchSetupProvider provider, {required bool useBulk}) {
    final scorecardProvider = context.read<ScorecardProvider>();
    scorecardProvider.startRound(
      provider.selectedCourse!,
      provider.selectedTee!,
      provider.currentPlayer!,
      provider.playingHandicap!,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => useBulk
            ? const ScorecardBulkScreen()
            : const ScorecardKeypadScreen(),
      ),
    );
  }

  Widget _buildStepCard({
    required BuildContext context,
    required int stepNumber,
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                    border: Border.all(
                      color: Colors.grey.shade400,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$stepNumber',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
            Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildClubDropdown(BuildContext context, MatchSetupProvider provider) {
    return DropdownMenu<Club>(
      key: ValueKey(provider.selectedClub?.id ?? 'no-club'),
      initialSelection: provider.selectedClub,
      expandedInsets: EdgeInsets.zero,
      hintText: 'Søg eller vælg klub...',
      enableFilter: true,
      enableSearch: true,
      requestFocusOnTap: true,
      dropdownMenuEntries: provider.clubs.map((club) {
        return DropdownMenuEntry<Club>(
          value: club,
          label: club.name,
        );
      }).toList(),
      onSelected: (Club? club) {
        provider.setSelectedClub(club);
      },
    );
  }

  Widget _buildCourseDropdown(
      BuildContext context, MatchSetupProvider provider) {
    if (provider.courses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Ingen baner fundet for denne klub'),
      );
    }

    return DropdownMenu<GolfCourse>(
      key: ValueKey(provider.selectedCourse?.name ?? 'no-course'),
      initialSelection: provider.selectedCourse,
      expandedInsets: EdgeInsets.zero,
      hintText: 'Vælg bane...',
      dropdownMenuEntries: provider.courses.map((course) {
        return DropdownMenuEntry<GolfCourse>(
          value: course,
          label: '${course.name} (${course.holeCount} huller)',
          trailingIcon: course.longestMenTee != null
              ? Tooltip(
                  message:
                      'CR/Slope: ${course.longestMenTee!.courseRating.toStringAsFixed(1)}/${course.longestMenTee!.slopeRating}',
                  child: const Icon(Icons.info_outline, size: 16),
                )
              : null,
        );
      }).toList(),
      onSelected: (GolfCourse? course) {
        provider.setSelectedCourse(course);
      },
    );
  }

  Widget _buildTeeDropdown(BuildContext context, MatchSetupProvider provider) {
    if (provider.availableTees.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Ingen tees fundet for denne bane'),
      );
    }

    return DropdownMenu<Tee>(
      key: ValueKey(provider.selectedTee?.name ?? 'no-tee'),
      initialSelection: provider.selectedTee,
      expandedInsets: EdgeInsets.zero,
      hintText: 'Vælg tee...',
      dropdownMenuEntries: provider.availableTees.map((tee) {
        return DropdownMenuEntry<Tee>(
          value: tee,
          label:
              '${tee.name} - CR: ${tee.courseRating.toStringAsFixed(1)}, Slope: ${tee.slopeRating}',
        );
      }).toList(),
      onSelected: (Tee? tee) {
        provider.setSelectedTee(tee);
      },
    );
  }

  Widget _buildDisabledMessage(String message) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildPlayerInfoCard(
      BuildContext context, MatchSetupProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.currentPlayer != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        provider.currentPlayer!.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      Chip(
                        label: Text(
                          'HCP ${provider.currentPlayer!.hcp}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (provider.playingHandicap != null &&
                      provider.selectedTee != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Du har ${provider.playingHandicap} slag på denne bane',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            final description = provider.getCalculationDescription();
                            if (description != null) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  title: const Text(
                                    'Handicap Beregning',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  content: Text(
                                    description,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  actions: [
                                    FilledButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppTheme.dguGreen,
                                      ),
                                      child: const Text('Luk'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Vælg tee for at se spillehandicap',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Ingen spiller data'),
                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(
      BuildContext context, String error, VoidCallback onRetry) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Prøv igen'),
          ),
        ],
      ),
    );
  }
}
