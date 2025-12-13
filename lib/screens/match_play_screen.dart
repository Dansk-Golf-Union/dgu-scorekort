import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/match_play_provider.dart';
import '../providers/auth_provider.dart';
import '../models/club_model.dart';
import '../models/course_model.dart';
import '../theme/app_theme.dart';

class MatchPlayScreen extends StatefulWidget {
  const MatchPlayScreen({super.key});

  @override
  State<MatchPlayScreen> createState() => _MatchPlayScreenState();
}

class _MatchPlayScreenState extends State<MatchPlayScreen> {
  final TextEditingController _opponentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final matchProvider = context.read<MatchPlayProvider>();
      final authProvider = context.read<AuthProvider>();
      
      // Set player 1 from auth
      if (authProvider.currentPlayer != null) {
        matchProvider.setPlayer1(authProvider.currentPlayer!);
      }
      
      // Load clubs
      matchProvider.loadClubs();
    });
  }

  @override
  void dispose() {
    _opponentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Tilbage',
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Match Play / Hulspil', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Consumer<MatchPlayProvider>(
        builder: (context, provider, child) {
          switch (provider.currentPhase) {
            case MatchPhase.setup:
              return _buildSetupPhase(context, provider);
            case MatchPhase.strokeView:
              return _buildStrokeViewPhase(context, provider);
            case MatchPhase.scoring:
              return _buildScoringPhase(context, provider);
          }
        },
      ),
    );
  }

  Widget _buildSetupPhase(BuildContext context, MatchPlayProvider provider) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Player 1 Info
              _buildPlayerCard(
                context: context,
                title: 'Spiller 1 (Dig)',
                playerName: provider.player1?.name ?? 'Ikke logget ind',
                playerHcp: provider.player1?.hcp.toStringAsFixed(1) ?? '-',
                playingHcp: provider.player1PlayingHcp?.toString(),
              ),
              const SizedBox(height: 16),

              // Opponent Input
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spiller 2 (Modstander)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _opponentController,
                        decoration: const InputDecoration(
                          labelText: 'DGU-nummer',
                          hintText: 'fx 177-2813',
                          prefixIcon: Icon(Icons.person_search),
                        ),
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 12),
                      if (provider.isLoadingOpponent)
                        const Center(child: CircularProgressIndicator())
                      else if (provider.opponentError != null)
                        Text(
                          provider.opponentError!,
                          style: const TextStyle(color: Colors.red),
                        )
                      else if (provider.player2 != null)
                        _buildOpponentInfo(context, provider)
                      else
                        FilledButton.icon(
                          onPressed: () {
                            final dguNumber = _opponentController.text.trim();
                            if (dguNumber.isNotEmpty) {
                              provider.fetchOpponent(dguNumber);
                            }
                          },
                          icon: const Icon(Icons.search),
                          label: const Text('Hent modstander'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.dguGreen,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Club Selection
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
                        ? Text(provider.clubsError!, style: const TextStyle(color: Colors.red))
                        : _buildClubDropdown(context, provider),
              ),
              const SizedBox(height: 16),

              // Course Selection
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
                            ? Text(provider.coursesError!, style: const TextStyle(color: Colors.red))
                            : _buildCourseDropdown(context, provider),
              ),
              const SizedBox(height: 16),

              // Tee Selection
              _buildStepCard(
                context: context,
                stepNumber: 3,
                title: 'Vælg Tee',
                child: provider.selectedCourse == null
                    ? _buildDisabledMessage('Vælg først en bane')
                    : _buildTeeDropdown(context, provider),
              ),
              const SizedBox(height: 16),

              // Handicap Summary
              if (provider.canStartMatch) ...[
                Card(
                  elevation: 2,
                  color: AppTheme.dguGreen.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Spillehandicap Oversigt',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  provider.player1?.name.split(' ').first ?? 'Spiller 1',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${provider.player1PlayingHcp} slag',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const Text('vs', style: TextStyle(fontSize: 18)),
                            Column(
                              children: [
                                Text(
                                  provider.player2?.name.split(' ').first ?? 'Spiller 2',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${provider.player2PlayingHcp} slag',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        if (provider.handicapDifference == 0)
                          const Text(
                            'Ingen får slag - lige handicap',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          )
                        else
                          Text(
                            '${provider.playerWithStrokes?.name.split(' ').first ?? 'Modstander'} får ${provider.handicapDifference} slag ekstra',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Start Match Button
              FilledButton.icon(
                onPressed: provider.canStartMatch ? () => provider.startMatch() : null,
                icon: const Icon(Icons.golf_course),
                label: const Text('Se Slag Fordeling'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.dguGreen,
                  disabledBackgroundColor: Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStrokeViewPhase(BuildContext context, MatchPlayProvider provider) {
    final tee = provider.selectedTee!;
    final holes = tee.holes ?? [];
    final strokesMap = provider.strokesOnHoles;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              color: AppTheme.dguGreen.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Slag Fordeling',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (provider.handicapDifference > 0)
                      Text(
                        _getStrokeDistributionDescription(provider),
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      )
                    else
                      const Text(
                        'Ingen slag - begge har samme spillehandicap',
                        style: TextStyle(fontSize: 16),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 2,
                child: ListView.builder(
                  itemCount: holes.length,
                  itemBuilder: (context, index) {
                    final hole = holes[index];
                    final strokeCount = strokesMap[hole.number] ?? 0;
                    final hasStroke = strokeCount > 0;
                    
                    // Determine if this hole should be highlighted (green)
                    // Only holes with the MOST strokes get highlighted
                    final maxStrokes = strokesMap.values.fold<int>(0, (max, val) => val > max ? val : max);
                    final shouldHighlight = strokeCount == maxStrokes && strokeCount > 0;

                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        color: shouldHighlight ? AppTheme.dguGreen.withOpacity(0.1) : null,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: shouldHighlight ? AppTheme.dguGreen : Colors.grey.shade300,
                          child: Text(
                            '${hole.number}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: shouldHighlight ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text('Par ${hole.par}'),
                            const SizedBox(width: 16),
                            Text(
                              'Index ${hole.index}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        trailing: hasStroke
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.stars, 
                                    color: shouldHighlight ? AppTheme.dguGreen : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$strokeCount slag ekstra',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: shouldHighlight ? AppTheme.dguGreen : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => provider.resetMatch(),
                    child: const Text('Tilbage'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => provider.startScoring(),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Match'),
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
    );
  }

  Widget _buildScoringPhase(BuildContext context, MatchPlayProvider provider) {
    if (provider.matchFinished) {
      return _buildMatchFinished(context, provider);
    }

    final tee = provider.selectedTee!;
    final holes = tee.holes ?? [];
    final currentHole = holes.firstWhere(
      (h) => h.number == provider.currentHole,
      orElse: () => holes.first,
    );
    final strokeCount = provider.strokesOnHoles[currentHole.number] ?? 0;
    final hasStroke = strokeCount > 0;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Hole Info
            Card(
              elevation: 2,
              color: AppTheme.dguGreen,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Hul ${currentHole.number}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Par ${currentHole.par} • Index ${currentHole.index}',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    if (hasStroke) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.stars, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${provider.playerWithStrokes?.name.split(' ').first} har $strokeCount slag ekstra',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Scoring Buttons
            Text(
              'Hvem vandt hullet?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => provider.recordHoleResult('player1'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.dguGreen,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    child: Text(
                      provider.player1?.name.split(' ').first ?? 'Spiller 1',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => provider.recordHoleResult('halved'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      side: const BorderSide(color: Colors.grey, width: 2),
                    ),
                    child: const Text(
                      'Delt',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => provider.recordHoleResult('player2'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.dguGreen,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    child: Text(
                      provider.player2?.name.split(' ').first ?? 'Spiller 2',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Match Status
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Match Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      provider.getMatchStatusString(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Progress indicator
            LinearProgressIndicator(
              value: provider.currentHole / holes.length,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.dguGreen),
            ),
            const SizedBox(height: 8),
            Text(
              'Hul ${provider.currentHole} af ${holes.length}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const Spacer(),

            // Undo and Quit buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: provider.currentHole > 1
                        ? () => provider.undoLastHole()
                        : null,
                    child: const Text('Fortryd'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Afslut match?'),
                          content: const Text('Er du sikker på at du vil afslutte matchen?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Annuller'),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(context);
                                provider.resetMatch();
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Afslut'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Afslut'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchFinished(BuildContext context, MatchPlayProvider provider) {
    final winnerName = provider.getWinnerName();

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 80,
              color: AppTheme.dguGreen,
            ),
            const SizedBox(height: 24),
            Text(
              'Match Afsluttet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (winnerName != null) ...[
              Text(
                'Vinder:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                winnerName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dguGreen,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                provider.finalResult,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
            ] else ...[
              const Text(
                'Match Delt',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 32),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Endelig Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      provider.getMatchStatusString(),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => provider.resetMatch(),
              icon: const Icon(Icons.refresh),
              label: const Text('Ny Match'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.dguGreen,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tilbage til Hovedside'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard({
    required BuildContext context,
    required String title,
    required String playerName,
    required String playerHcp,
    String? playingHcp,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  playerName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Chip(
                  label: Text('HCP $playerHcp'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (playingHcp != null) ...[
              const SizedBox(height: 8),
              Text(
                'Spillehandicap: $playingHcp',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOpponentInfo(BuildContext context, MatchPlayProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.player2!.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'HCP: ${provider.player2!.hcp.toStringAsFixed(1)}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                if (provider.player2!.homeClubName != null)
                  Text(
                    provider.player2!.homeClubName!,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                provider.fetchOpponent(''); // Clear opponent
                _opponentController.clear();
              },
              tooltip: 'Skift modstander',
            ),
          ],
        ),
        if (provider.player2PlayingHcp != null) ...[
          const SizedBox(height: 8),
          Text(
            'Spillehandicap: ${provider.player2PlayingHcp}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ],
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

  Widget _buildClubDropdown(BuildContext context, MatchPlayProvider provider) {
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

  Widget _buildCourseDropdown(BuildContext context, MatchPlayProvider provider) {
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
        );
      }).toList(),
      onSelected: (GolfCourse? course) {
        provider.setSelectedCourse(course);
      },
    );
  }

  Widget _buildTeeDropdown(BuildContext context, MatchPlayProvider provider) {
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

  String _getStrokeDistributionDescription(MatchPlayProvider provider) {
    if (provider.handicapDifference == 0) {
      return 'Ingen slag - begge har samme spillehandicap';
    }

    final playerName = provider.playerWithStrokes?.name.split(' ').first ?? 'Spiller';
    final isNineHole = (provider.selectedTee?.holes?.length ?? 18) <= 9;
    final maxHoles = isNineHole ? 9 : 18;
    final difference = provider.handicapDifference;

    if (difference <= maxHoles) {
      // Simple case: less than or equal to full round
      return '$playerName får $difference slag ekstra (handicap-nøgle 1-$difference)';
    } else {
      // Multiple strokes per hole case
      final fullRounds = difference ~/ maxHoles;
      final remainder = difference % maxHoles;
      
      if (remainder == 0) {
        return '$playerName får $fullRounds slag ekstra på alle $maxHoles huller';
      } else {
        return '$playerName får $fullRounds slag ekstra på alle huller + ${fullRounds + 1} slag ekstra på nøgle 1-$remainder';
      }
    }
  }
}

