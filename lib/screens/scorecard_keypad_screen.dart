import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scorecard_provider.dart';
import '../models/scorecard_model.dart';
import '../utils/score_helper.dart';
import 'scorecard_results_screen.dart';

class ScorecardKeypadScreen extends StatefulWidget {
  const ScorecardKeypadScreen({super.key});

  @override
  State<ScorecardKeypadScreen> createState() => _ScorecardKeypadScreenState();
}

class _ScorecardKeypadScreenState extends State<ScorecardKeypadScreen> {
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
                  // Hole card with keypad input
                  SizedBox(
                    height: MediaQuery.of(context).size.width < 768
                        ? MediaQuery.of(context).size.height *
                              0.55 // Mobile
                        : MediaQuery.of(context).size.height *
                              0.60, // Tablet/Desktop
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: scorecard.holeScores.length,
                      onPageChanged: (index) {
                        provider.goToHole(index);
                      },
                      itemBuilder: (context, index) {
                        final hole = scorecard.holeScores[index];
                        return _HoleKeypadCard(
                          hole: hole,
                          onScoreChanged: (strokes) {
                            provider.setScore(hole.holeNumber, strokes);
                            // Auto-advance to next hole after a short delay
                            if (provider.canGoNext) {
                              Future.delayed(
                                const Duration(milliseconds: 400),
                                () {
                                  if (context.mounted) {
                                    provider.nextHole();
                                  }
                                },
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),

                  // Compact scorekort progress view (starts directly under keypad, grows down)
                  // Dynamically shrink when "Afslut Runde" button appears
                  Flexible(
                    flex: scorecard.isComplete ? 3 : 5,
                    child: _CompactScorecardView(scorecard: scorecard),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HoleKeypadCard extends StatelessWidget {
  final HoleScore hole;
  final Function(int) onScoreChanged;

  const _HoleKeypadCard({required this.hole, required this.onScoreChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hole header
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side: HUL 1  Index: 5
                  Row(
                    children: [
                      Text(
                        'HUL ${hole.holeNumber}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Index: ${hole.index}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  // Right side: +1  Par 4
                  Row(
                    children: [
                      if (hole.strokesReceived > 0) ...[
                        Chip(
                          label: Text(
                            '+${hole.strokesReceived}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 0,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: Colors.orange[100],
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        'Par ${hole.par}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Current score display
          _ScoreDisplay(hole: hole),
          const SizedBox(height: 12),

          // Keypad
          _ScoreKeypad(
            currentScore: hole.strokes,
            par: hole.par,
            nettoPar: hole.par + hole.strokesReceived,
            onChanged: onScoreChanged,
            onPickUp: () {
              final provider = Provider.of<ScorecardProvider>(
                context,
                listen: false,
              );
              provider.pickUpHole(hole.holeNumber);
              // Auto-advance to next hole after a short delay
              if (provider.canGoNext) {
                Future.delayed(const Duration(milliseconds: 400), () {
                  if (context.mounted) {
                    provider.nextHole();
                  }
                });
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ScoreDisplay extends StatelessWidget {
  final HoleScore hole;

  const _ScoreDisplay({required this.hole});

  @override
  Widget build(BuildContext context) {
    if (hole.strokes == null) {
      return Card(
        color: Colors.grey[200],
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Vælg score hint
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Vælg score',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              // Divider
              Container(width: 1, height: 12, color: Colors.grey[400]),
              // Swipe hint
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swipe, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Swipe for næste',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final nettoPar = hole.par + hole.strokesReceived;
    final golfTerm = hole.isPickedUp
        ? 'Samlet op'
        : ScoreHelper.getGolfTerm(hole.strokes!, nettoPar);
    final colorCategory = ScoreHelper.getScoreColor(hole.strokes!, nettoPar);

    return Card(
      color: hole.isPickedUp ? Colors.grey[600] : _getCardColor(colorCategory),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              hole.isPickedUp ? '—' : '${hole.strokes}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (golfTerm.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                '•',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                golfTerm,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(width: 6),
            Text(
              '•',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${hole.stablefordPoints}p',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCardColor(ScoreColor category) {
    switch (category) {
      case ScoreColor.excellent:
        return Colors.purple;
      case ScoreColor.good:
        return Colors.green;
      case ScoreColor.par:
        return Colors.blue;
      case ScoreColor.bogey:
        return Colors.orange;
      case ScoreColor.poor:
        return Colors.red;
    }
  }
}

class _ScoreKeypad extends StatefulWidget {
  final int? currentScore;
  final int par; // Actual par for the hole
  final int nettoPar; // Par + strokes received (used as default)
  final Function(int) onChanged;
  final VoidCallback onPickUp;

  const _ScoreKeypad({
    required this.currentScore,
    required this.par,
    required this.nettoPar,
    required this.onChanged,
    required this.onPickUp,
  });

  @override
  State<_ScoreKeypad> createState() => _ScoreKeypadState();
}

class _ScoreKeypadState extends State<_ScoreKeypad> {
  bool _showHighScores = false; // false = 1-9, true = 10-18

  @override
  Widget build(BuildContext context) {
    final currentScore = widget.currentScore;
    final par = widget.par; // Actual par for labels
    final nettoPar = widget.nettoPar; // Used as default score
    final onChanged = widget.onChanged;

    // Get dynamic labels for keypad based on ACTUAL par (not netto par)
    // This way "Par" label shows on the real par, not netto par
    final labels = _showHighScores
        ? <int, String>{}
        : ScoreHelper.getKeypadLabels(par);

    // Calculate base score for current mode
    final baseScore = _showHighScores ? 10 : 1;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Row 1: base, base+1, base+2
            Row(
              children: [
                _KeypadButton(
                  score: baseScore,
                  label: labels[baseScore],
                  nettoPar: nettoPar,
                  isSelected: currentScore == baseScore,
                  onTap: () => onChanged(baseScore),
                ),
                const SizedBox(width: 4),
                _KeypadButton(
                  score: baseScore + 1,
                  label: labels[baseScore + 1],
                  nettoPar: nettoPar,
                  isSelected: currentScore == baseScore + 1,
                  onTap: () => onChanged(baseScore + 1),
                ),
                const SizedBox(width: 4),
                _KeypadButton(
                  score: baseScore + 2,
                  label: labels[baseScore + 2],
                  nettoPar: nettoPar,
                  isSelected: currentScore == baseScore + 2,
                  onTap: () => onChanged(baseScore + 2),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Row 2: base+3, base+4, base+5
            Row(
              children: [
                _KeypadButton(
                  score: baseScore + 3,
                  label: labels[baseScore + 3],
                  nettoPar: nettoPar,
                  isSelected: currentScore == baseScore + 3,
                  onTap: () => onChanged(baseScore + 3),
                ),
                const SizedBox(width: 4),
                _KeypadButton(
                  score: baseScore + 4,
                  label: labels[baseScore + 4],
                  nettoPar: nettoPar,
                  isSelected: currentScore == baseScore + 4,
                  onTap: () => onChanged(baseScore + 4),
                ),
                const SizedBox(width: 4),
                _KeypadButton(
                  score: baseScore + 5,
                  label: labels[baseScore + 5],
                  nettoPar: nettoPar,
                  isSelected: currentScore == baseScore + 5,
                  onTap: () => onChanged(baseScore + 5),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Row 3: base+6, base+7, base+8
            Row(
              children: [
                _KeypadButton(
                  score: baseScore + 6,
                  label: labels[baseScore + 6],
                  nettoPar: nettoPar,
                  isSelected: currentScore == baseScore + 6,
                  onTap: () => onChanged(baseScore + 6),
                ),
                const SizedBox(width: 4),
                _KeypadButton(
                  score: baseScore + 7,
                  label: labels[baseScore + 7],
                  nettoPar: nettoPar,
                  isSelected: currentScore == baseScore + 7,
                  onTap: () => onChanged(baseScore + 7),
                ),
                const SizedBox(width: 4),
                _KeypadButton(
                  score: baseScore + 8,
                  label: labels[baseScore + 8],
                  nettoPar: nettoPar,
                  isSelected: currentScore == baseScore + 8,
                  onTap: () => onChanged(baseScore + 8),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Row 4: Toggle button and Pick up button
            Row(
              children: [
                // Left: Toggle 10-18 button
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: Material(
                      color: _showHighScores
                          ? Colors.orange.shade300
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _showHighScores = !_showHighScores;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _showHighScores
                                    ? Icons.arrow_back
                                    : Icons.more_horiz,
                                size: 20,
                                color: Colors.black87,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _showHighScores ? '1-9' : '10-18',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Right: Pick up button
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: Material(
                      color: Colors.red.shade300,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: widget.onPickUp,
                        borderRadius: BorderRadius.circular(8),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cancel_outlined,
                                size: 20,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Saml op',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
}

class _KeypadButton extends StatelessWidget {
  final int score;
  final String? label;
  final int nettoPar;
  final bool isSelected;
  final VoidCallback onTap;

  const _KeypadButton({
    required this.score,
    this.label,
    required this.nettoPar,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPar = score == nettoPar;

    Color backgroundColor;
    Color textColor;

    if (isSelected) {
      backgroundColor = Theme.of(context).colorScheme.primary;
      textColor = Colors.white;
    } else if (isPar) {
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade900;
    } else {
      backgroundColor = Colors.grey.shade200;
      textColor = Colors.black87;
    }

    return Expanded(
      child: AspectRatio(
        aspectRatio: 1.6, // Even more compact for mobile
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (label != null && label!.isNotEmpty)
                  Text(
                    label!,
                    style: TextStyle(
                      fontSize: 8,
                      color: textColor.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact vertical scorekort showing completed holes with running totals
/// Replaces the bottom footer bar with integrated view
class _CompactScorecardView extends StatefulWidget {
  final Scorecard scorecard;

  const _CompactScorecardView({required this.scorecard});

  @override
  State<_CompactScorecardView> createState() => _CompactScorecardViewState();
}

class _CompactScorecardViewState extends State<_CompactScorecardView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_CompactScorecardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll to bottom when new hole is added
    if (widget.scorecard.holesCompleted > oldWidget.scorecard.holesCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get completed holes (including pickups)
    final completedHoles = widget.scorecard.holeScores
        .where((hole) => hole.strokes != null || hole.isPickedUp)
        .toList();

    // Return empty container if no holes completed yet
    if (completedHoles.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate totals (only count actual strokes, not pickups)
    int totalStrokes = completedHoles
        .where((h) => !h.isPickedUp && h.strokes != null)
        .fold(0, (sum, hole) => sum + hole.strokes!);
    int totalPoints = completedHoles.fold(
      0,
      (sum, hole) => sum + hole.stablefordPoints,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        12,
        0,
        12,
        12,
      ), // No top padding, bottom padding for button
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row (fixed at top)
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF1B5E20), // DGU Green
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        _TableCell('Hul', isHeader: true, width: 70),
                        _TableCell('Par', isHeader: true, width: 60),
                        _TableCell('Slag', isHeader: true, width: 70),
                        _TableCell('Point', isHeader: true, width: 70),
                      ],
                    ),
                  ),

                  // Scrollable data rows
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        children: completedHoles
                            .map(
                              (hole) => Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _TableCell('${hole.holeNumber}', width: 70),
                                    _TableCell('${hole.par}', width: 60),
                                    _TableCell(
                                      hole.isPickedUp ? '-' : '${hole.strokes}',
                                      width: 70,
                                    ),
                                    _TableCell(
                                      '${hole.stablefordPoints}',
                                      width: 70,
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),

                  // Total row (fixed at bottom)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border(
                        top: BorderSide(
                          color: const Color(0xFF1B5E20),
                          width: 2,
                        ),
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        _TableCell('Total', width: 70, isBold: true),
                        _TableCell('-', width: 60, isBold: true),
                        _TableCell('$totalStrokes', width: 70, isBold: true),
                        _TableCell(
                          '$totalPoints',
                          width: 70,
                          isBold: true,
                          highlight: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Finish round button (when all holes completed)
          if (widget.scorecard.isComplete)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    context.read<ScorecardProvider>().finishRound();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScorecardResultsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Afslut Runde'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Table cell widget for compact scorekort
class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final bool isBold;
  final bool highlight;
  final double width;

  const _TableCell(
    this.text, {
    this.isHeader = false,
    this.isBold = false,
    this.highlight = false,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isHeader ? 11 : 13,
          fontWeight: isHeader || isBold ? FontWeight.bold : FontWeight.normal,
          color: isHeader
              ? Colors.white
              : highlight
              ? const Color(0xFF1B5E20)
              : Colors.black87,
        ),
      ),
    );
  }
}
