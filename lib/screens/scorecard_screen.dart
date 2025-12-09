import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scorecard_provider.dart';
import '../models/scorecard_model.dart';
import 'scorecard_results_screen.dart';

class ScorecardScreen extends StatefulWidget {
  const ScorecardScreen({super.key});

  @override
  State<ScorecardScreen> createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ScorecardProvider>();
    _pageController = PageController(initialPage: provider.currentHoleIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScorecardProvider>(
      builder: (context, provider, child) {
        final scorecard = provider.scorecard;

        if (scorecard == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(title: const Text('Scorekort')),
            body: const Center(child: Text('Ingen aktiv runde')),
          );
        }

        // Sync PageController with provider state
        if (_pageController.hasClients &&
            _pageController.page?.round() != provider.currentHoleIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              _pageController.animateToPage(
                provider.currentHoleIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            title: Text(
              'Hul ${provider.currentHoleIndex + 1}/${scorecard.holeScores.length}',
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Text(
                    'Total: ${scorecard.totalPoints}p',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  // Hole card with score input
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: scorecard.holeScores.length,
                      onPageChanged: (index) {
                        provider.goToHole(index);
                      },
                      itemBuilder: (context, index) {
                        final hole = scorecard.holeScores[index];
                        return _HoleCard(
                          hole: hole,
                          onScoreChanged: (strokes) {
                            provider.setScore(hole.holeNumber, strokes);
                            // No auto-advance on counter - user may click multiple times
                          },
                        );
                      },
                    ),
                  ),

                  // Navigation buttons
                  _NavigationBar(
                    canGoPrevious: provider.canGoPrevious,
                    canGoNext: provider.canGoNext,
                    onPrevious: provider.previousHole,
                    onNext: provider.nextHole,
                  ),

                  // Score summary
                  _ScoreSummary(scorecard: scorecard),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HoleCard extends StatelessWidget {
  final HoleScore hole;
  final Function(int) onScoreChanged;

  const _HoleCard({required this.hole, required this.onScoreChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hole header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HUL ${hole.holeNumber}',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Index: ${hole.index}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Par ${hole.par}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hole.strokesReceived > 0)
                        Chip(
                          label: Text(
                            '+${hole.strokesReceived}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.orange[100],
                        ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32),

              // Score input
              Text('Score', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              _ScoreInput(
                currentScore: hole.strokes,
                par: hole.par,
                strokesReceived: hole.strokesReceived,
                onChanged: onScoreChanged,
              ),
              const SizedBox(height: 24),

              // Stableford points display
              if (hole.strokes != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getScoreColor(hole, context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${hole.stablefordPoints} points',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      Text(
                        _getScoreLabel(hole),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(HoleScore hole, BuildContext context) {
    final relativeToPar = hole.relativeToPar;
    if (relativeToPar == null) return Colors.grey;

    if (relativeToPar <= -2) return Colors.purple; // Eagle or better
    if (relativeToPar == -1) return Colors.green; // Birdie
    if (relativeToPar == 0) return Colors.blue; // Par
    if (relativeToPar == 1) return Colors.orange; // Bogey
    return Colors.red; // Double bogey or worse
  }

  String _getScoreLabel(HoleScore hole) {
    final relativeToPar = hole.relativeToPar;
    if (relativeToPar == null) return '';

    if (relativeToPar <= -3) return 'Albatross!';
    if (relativeToPar == -2) return 'Eagle!';
    if (relativeToPar == -1) return 'Birdie';
    if (relativeToPar == 0) return 'Par';
    if (relativeToPar == 1) return 'Bogey';
    if (relativeToPar == 2) return 'Double Bogey';
    return '+${relativeToPar} over par';
  }
}

class _ScoreInput extends StatelessWidget {
  final int? currentScore;
  final int par;
  final int strokesReceived;
  final Function(int) onChanged;

  const _ScoreInput({
    required this.currentScore,
    required this.par,
    required this.strokesReceived,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Default to "netto par" (par + tildelte slag)
    final nettoPar = par + strokesReceived;
    final score = currentScore ?? nettoPar;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Decrease button
        IconButton.filled(
          onPressed: score > 1 ? () => onChanged(score - 1) : null,
          icon: const Icon(Icons.remove),
          iconSize: 32,
        ),
        const SizedBox(width: 32),

        // Score display (clickable to select netto par)
        InkWell(
          onTap: () => onChanged(nettoPar),
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Center(
              child: Text(
                '$score',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 32),

        // Increase button
        IconButton.filled(
          onPressed: score < 15 ? () => onChanged(score + 1) : null,
          icon: const Icon(Icons.add),
          iconSize: 32,
        ),
      ],
    );
  }
}

class _NavigationBar extends StatelessWidget {
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _NavigationBar({
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: canGoPrevious ? onPrevious : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Forrige'),
            ),
          ),
          const SizedBox(width: 16),

          // Next button
          Expanded(
            child: FilledButton.icon(
              onPressed: canGoNext ? onNext : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Næste'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreSummary extends StatelessWidget {
  final Scorecard scorecard;

  const _ScoreSummary({required this.scorecard});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  label: 'Huller',
                  value:
                      '${scorecard.holesCompleted}/${scorecard.holeScores.length}',
                ),
                _SummaryItem(
                  label: 'Points',
                  value: '${scorecard.totalPoints}',
                  highlighted: true,
                ),
                _SummaryItem(
                  label: 'Slag',
                  value: scorecard.totalStrokes != null
                      ? '${scorecard.totalStrokes}'
                      : '-',
                ),
              ],
            ),
            if (scorecard.holeScores.length == 18) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem(
                    label: 'Front 9',
                    value: '${scorecard.front9Points}p',
                    small: true,
                  ),
                  _SummaryItem(
                    label: 'Back 9',
                    value: '${scorecard.back9Points}p',
                    small: true,
                  ),
                ],
              ),
            ],
            if (scorecard.isComplete) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    context.read<ScorecardProvider>().finishRound();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScorecardResultsScreen(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Afslut Runde'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;
  final bool small;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.highlighted = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
        ),
        Text(
          value,
          style:
              (small
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.titleLarge)
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: highlighted
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
        ),
      ],
    );
  }
}
