import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/match_setup_provider.dart';
import 'providers/scorecard_provider.dart';
import 'providers/auth_provider.dart';
import 'models/club_model.dart';
import 'models/course_model.dart';
import 'screens/scorecard_screen.dart';
import 'screens/scorecard_keypad_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => MatchSetupProvider()),
        ChangeNotifierProvider(create: (_) => ScorecardProvider()),
      ],
      child: MaterialApp(
        title: 'DGU Scorekort',
        theme: AppTheme.lightTheme,
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            // Show loading while initializing
            if (authProvider.isLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Show login screen if not authenticated
            if (!authProvider.isAuthenticated) {
              return const LoginScreen();
            }

            // Show setup screen if authenticated
            return const SetupRoundScreen();
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
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
        title: const Text('DGU Scorekort'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
                              ? () => _startRound(context, provider, useKeypad: false)
                              : null,
                          icon: const Icon(Icons.exposure),
                          label: const Text(
                            'Plus/Minus',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.dguGreen,
                            disabledBackgroundColor: Colors.grey.shade400,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: provider.canStartRound
                              ? () => _startRound(context, provider, useKeypad: true)
                              : null,
                          icon: const Icon(Icons.grid_3x3),
                          label: const Text(
                            'Hurtig',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.dguGreen,
                            disabledBackgroundColor: Colors.grey.shade400,
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

  void _startRound(BuildContext context, MatchSetupProvider provider, {required bool useKeypad}) {
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
        builder: (context) => useKeypad
            ? const ScorecardKeypadScreen()
            : const ScorecardScreen(),
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
      initialSelection: provider.selectedTee,
      expandedInsets: EdgeInsets.zero,
      hintText: 'Vælg tee...',
      dropdownMenuEntries: provider.availableTees.map((tee) {
        final genderIcon = tee.gender == 0 ? '♂' : '♀';
        return DropdownMenuEntry<Tee>(
          value: tee,
          label:
              '$genderIcon ${tee.name} - CR: ${tee.courseRating.toStringAsFixed(1)}, Slope: ${tee.slopeRating}',
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
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.isLoadingPlayer)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (provider.playerError != null)
              _buildErrorWidget(
                context,
                provider.playerError!,
                () => provider.loadCurrentPlayer(),
              )
            else if (provider.currentPlayer != null)
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
                                  backgroundColor: Colors.white,
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
