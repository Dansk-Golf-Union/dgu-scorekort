import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/scorecard_provider.dart';
import '../models/scorecard_model.dart';
import 'scorecard_results_screen.dart';

class ScorecardBulkScreen extends StatefulWidget {
  const ScorecardBulkScreen({super.key});

  @override
  State<ScorecardBulkScreen> createState() => _ScorecardBulkScreenState();
}

class _ScorecardBulkScreenState extends State<ScorecardBulkScreen> {
  final List<FocusNode> _focusNodes = [];
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    final provider = context.read<ScorecardProvider>();
    final scorecard = provider.scorecard;
    
    if (scorecard != null) {
      // Create focus nodes and controllers for each hole
      for (int i = 0; i < scorecard.holeScores.length; i++) {
        _focusNodes.add(FocusNode());
        _controllers.add(TextEditingController());
        
        // Pre-fill if score exists
        final hole = scorecard.holeScores[i];
        if (hole.strokes != null && !hole.isPickedUp) {
          _controllers[i].text = hole.strokes.toString();
        }
      }
    }
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
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
            appBar: AppBar(
              title: const Text('Scorekort'),
            ),
            body: const Center(
              child: Text('Ingen aktiv runde'),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              tooltip: 'Tilbage',
              onPressed: () async {
                final shouldPop = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Afbryd scorekort?'),
                    content: const Text('Dine indtastede scores vil gå tabt.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuller'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Ja, afbryd'),
                      ),
                    ],
                  ),
                );
                if (shouldPop == true && context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
            title: const Text('Indberet Scorekort', style: TextStyle(color: Colors.white)),
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
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  // Scrollable table
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: _buildScorecardTable(scorecard, provider),
                    ),
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

  Widget _buildScorecardTable(Scorecard scorecard, ScorecardProvider provider) {
    final is18Holes = scorecard.holeScores.length == 18;
    final holes = scorecard.holeScores;

    // Split into front 9 and back 9
    final front9Holes = holes.where((h) => h.holeNumber <= 9).toList();
    final back9Holes = holes.where((h) => h.holeNumber > 9).toList();

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300, width: 1),
      columnWidths: const {
        0: FlexColumnWidth(1.2), // Hul
        1: FlexColumnWidth(1.0), // Par
        2: FlexColumnWidth(1.0), // SPH
        3: FlexColumnWidth(1.5), // Slag (editable)
        4: FlexColumnWidth(1.2), // Point
        5: FlexColumnWidth(1.2), // Score
      },
      children: [
        // Header row
        _buildHeaderRow(),

        // Front 9 holes
        ...front9Holes.map((hole) {
          final index = holes.indexOf(hole);
          return _buildHoleRow(hole, index, provider);
        }),

        // Ud summary (for 18 holes)
        if (is18Holes) _buildSummaryRow('Ud', front9Holes),

        // Back 9 holes (for 18 holes)
        if (is18Holes)
          ...back9Holes.map((hole) {
            final index = holes.indexOf(hole);
            return _buildHoleRow(hole, index, provider);
          }),

        // Ind summary (for 18 holes)
        if (is18Holes) _buildSummaryRow('Ind', back9Holes),

        // Total summary
        _buildSummaryRow('Total', holes),
      ],
    );
  }

  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFF1B5E20)),
      children: [
        _HeaderCell('Hul'),
        _HeaderCell('Par'),
        _HeaderCell('SPH'),
        _HeaderCell('Slag'),
        _HeaderCell('Point'),
        _HeaderCell('Score'),
      ],
    );
  }

  TableRow _buildHoleRow(HoleScore hole, int index, ScorecardProvider provider) {
    final isEven = (hole.holeNumber - 1) % 2 == 0;
    final backgroundColor = isEven ? Colors.white : Colors.grey.shade50;

    return TableRow(
      decoration: BoxDecoration(color: backgroundColor),
      children: [
        _DataCell(hole.holeNumber.toString()),
        _DataCell(hole.par.toString()),
        _DataCell(_getSPHDisplay(hole.strokesReceived)),
        _buildEditableCell(hole, index, provider),
        _DataCell(hole.stablefordPoints.toString()),
        _DataCell(hole.adjustedScore.toString()),
      ],
    );
  }

  Widget _buildEditableCell(HoleScore hole, int index, ScorecardProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              decoration: InputDecoration(
                hintText: '-',
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                isDense: true,
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  final strokes = int.tryParse(value);
                  if (strokes != null) {
                    if (strokes == 0) {
                      // 0 means pick up
                      provider.pickUpHole(hole.holeNumber);
                      _controllers[index].text = '';
                      
                      // Auto-advance to next field
                      if (index < _focusNodes.length - 1) {
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) {
                            _focusNodes[index + 1].requestFocus();
                          }
                        });
                      } else {
                        // Last field - unfocus keyboard
                        FocusScope.of(context).unfocus();
                      }
                    } else if (strokes >= 1 && strokes <= 15) {
                      provider.setScore(hole.holeNumber, strokes);
                      
                      // Auto-advance to next field
                      if (index < _focusNodes.length - 1) {
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) {
                            _focusNodes[index + 1].requestFocus();
                          }
                        });
                      } else {
                        // Last field - unfocus keyboard
                        FocusScope.of(context).unfocus();
                      }
                    }
                  }
                }
              },
            ),
          ),
          // Pick up button
          InkWell(
            onTap: () {
              provider.pickUpHole(hole.holeNumber);
              _controllers[index].text = '';
              
              // Auto-advance to next field
              if (index < _focusNodes.length - 1) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    _focusNodes[index + 1].requestFocus();
                  }
                });
              } else {
                FocusScope.of(context).unfocus();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                Icons.cancel_outlined,
                size: 20,
                color: Colors.red.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildSummaryRow(String label, List<HoleScore> holes) {
    final totalPar = holes.fold<int>(0, (sum, h) => sum + h.par);
    final totalPoints = holes.fold<int>(0, (sum, h) => sum + h.stablefordPoints);
    
    // Check if any hole has null strokes (dash in Slag column)
    final hasAnyDash = holes.any((h) => h.strokes == null);
    
    // Calculate actual strokes total (only if no dashes)
    final totalStrokes = hasAnyDash 
        ? '' 
        : holes.fold<int>(0, (sum, h) => sum + (h.strokes ?? 0)).toString();
    
    // Calculate adjusted score total (always shown)
    final totalAdjustedScore = holes.fold<int>(0, (sum, h) => sum + h.adjustedScore);

    final isTotal = label == 'Total';

    return TableRow(
      decoration: BoxDecoration(
        color: isTotal ? Colors.grey.shade200 : Colors.grey.shade100,
      ),
      children: [
        _DataCell(label, bold: true),
        _DataCell(totalPar.toString(), bold: true),
        _DataCell(''), // SPH empty for summary
        _DataCell(totalStrokes, bold: true),
        _DataCell(totalPoints.toString(), bold: true),
        _DataCell(totalAdjustedScore.toString(), bold: true),
      ],
    );
  }

  String _getSPHDisplay(int strokesReceived) {
    if (strokesReceived == 0) return 'I';
    if (strokesReceived == 1) return 'I';
    return strokesReceived.toString();
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;

  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final bool bold;

  const _DataCell(this.text, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
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
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
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
                  value: '${scorecard.holesCompleted}/${scorecard.holeScores.length}',
                ),
                _SummaryItem(
                  label: 'Points',
                  value: '${scorecard.totalPoints}',
                  highlighted: true,
                ),
                _SummaryItem(
                  label: 'Slag',
                  value: scorecard.totalStrokes != null ? '${scorecard.totalStrokes}' : '-',
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
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: small ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: highlighted ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}

