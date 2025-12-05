import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scorecard_provider.dart';
import '../models/scorecard_model.dart';
import 'package:intl/intl.dart';

// Score marker types for visual indication
enum ScoreMarker {
  doubleCircle,  // Eagle eller bedre (-2 eller bedre)
  singleCircle,  // Birdie (-1)
  none,          // Par (0)
  singleBox,     // Bogey (+1)
  doubleBox,     // Double bogey eller værre (+2 eller værre)
}

class ScorecardResultsScreen extends StatelessWidget {
  const ScorecardResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScorecardProvider>(
      builder: (context, provider, child) {
        final scorecard = provider.scorecard;

        if (scorecard == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Resultat'),
            ),
            body: const Center(
              child: Text('Ingen scorekort data'),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            title: const Text('Runde Afsluttet'),
            centerTitle: true,
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info card
                    _InfoCard(scorecard: scorecard),
                    const SizedBox(height: 16),

                    // Scorecard table
                    _ScorecardTable(scorecard: scorecard),
                    const SizedBox(height: 24),

                    // Bottom info
                    _BottomInfo(scorecard: scorecard),
                    const SizedBox(height: 24),

                    // Back button
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Tilbage til Start'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Scorecard scorecard;

  const _InfoCard({required this.scorecard});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final dateStr = dateFormat.format(scorecard.startTime);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scorecard.course.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _InfoRow('Dato', dateStr),
            _InfoRow(
              'Bane',
              '${scorecard.course.name} ${scorecard.holeScores.length} huller',
            ),
            _InfoRow('Tee', scorecard.tee.name),
            _InfoRow('Runde', 'Privat'),
            _InfoRow('Handicap', '${scorecard.player.hcp}'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class _ScorecardTable extends StatelessWidget {
  final Scorecard scorecard;

  const _ScorecardTable({required this.scorecard});

  @override
  Widget build(BuildContext context) {
    final is18Holes = scorecard.holeScores.length == 18;
    final holes = scorecard.holeScores;

    // Calculate totals
    final front9Holes = holes.where((h) => h.holeNumber <= 9).toList();
    final back9Holes = holes.where((h) => h.holeNumber > 9).toList();

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(1.5), // Hul
        1: FlexColumnWidth(1.0), // Par
        2: FlexColumnWidth(1.0), // SPH
        3: FlexColumnWidth(1.2), // Slag
        4: FlexColumnWidth(1.2), // Point
        5: FlexColumnWidth(1.2), // Score
      },
      children: [
        // Header row
        _buildHeaderRow(),

        // Front 9 holes
        ...front9Holes.map((hole) => _buildHoleRow(hole, front9Holes.indexOf(hole))),

        // Ud summary (for 18 holes)
        if (is18Holes) _buildSummaryRow('Ud', front9Holes, true),

        // Back 9 holes (for 18 holes)
        if (is18Holes)
          ...back9Holes.map((hole) => _buildHoleRow(hole, back9Holes.indexOf(hole))),

        // Ind summary (for 18 holes)
        if (is18Holes) _buildSummaryRow('Ind', back9Holes, true),

        // Total summary
        _buildSummaryRow('Total', holes, false),
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

  TableRow _buildHoleRow(HoleScore hole, int index) {
    final isEven = index % 2 == 0;
    final backgroundColor = isEven ? Colors.white : Colors.grey.shade50;

    return TableRow(
      decoration: BoxDecoration(color: backgroundColor),
      children: [
        _DataCell(hole.holeNumber.toString()),
        _DataCell(hole.par.toString()),
        _DataCell(_getSPHDisplay(hole.strokesReceived)),
        _MarkedScoreCell(
          score: hole.strokes?.toString() ?? '-',
          marker: _getScoreMarker(hole),
        ),
        _DataCell(hole.stablefordPoints.toString()),
        _DataCell(hole.strokes?.toString() ?? '-'),
      ],
    );
  }

  TableRow _buildSummaryRow(String label, List<HoleScore> holes, bool isSubtotal) {
    final totalPar = holes.fold<int>(0, (sum, h) => sum + h.par);
    final totalStrokes = holes.fold<int>(0, (sum, h) => sum + (h.strokes ?? 0));
    final totalPoints = holes.fold<int>(0, (sum, h) => sum + h.stablefordPoints);

    return TableRow(
      decoration: BoxDecoration(
        color: isSubtotal ? Colors.grey.shade100 : Colors.grey.shade200,
      ),
      children: [
        _DataCell(label, bold: true),
        _DataCell(totalPar.toString(), bold: true),
        _DataCell(''), // SPH empty for summary
        _DataCell(totalStrokes.toString(), bold: true),
        _DataCell(totalPoints.toString(), bold: true),
        _DataCell(totalStrokes.toString(), bold: true),
      ],
    );
  }

  String _getSPHDisplay(int strokesReceived) {
    if (strokesReceived == 0) return 'I';
    if (strokesReceived == 1) return 'I';
    return strokesReceived.toString();
  }

  ScoreMarker _getScoreMarker(HoleScore hole) {
    if (hole.strokes == null) return ScoreMarker.none;
    
    // Beregn relativt til BANENS PAR (ikke netto par)
    final diff = hole.strokes! - hole.par;
    
    if (diff <= -2) return ScoreMarker.doubleCircle;  // Eagle eller bedre
    if (diff == -1) return ScoreMarker.singleCircle;  // Birdie
    if (diff == 0) return ScoreMarker.none;           // Par
    if (diff == 1) return ScoreMarker.singleBox;      // Bogey
    return ScoreMarker.doubleBox;                     // Double bogey eller værre
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

class _MarkedScoreCell extends StatelessWidget {
  final String score;
  final ScoreMarker marker;

  const _MarkedScoreCell({
    required this.score,
    required this.marker,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Center(
        child: _buildMarkedContainer(),
      ),
    );
  }

  Widget _buildMarkedContainer() {
    const textStyle = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 14,
    );

    switch (marker) {
      case ScoreMarker.singleCircle:
        // Enkelt cirkel (birdie)
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: Center(
            child: Text(
              score,
              textAlign: TextAlign.center,
              style: textStyle,
            ),
          ),
        );

      case ScoreMarker.doubleCircle:
        // Dobbelt cirkel (eagle eller bedre) - to separate cirkler
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: Center(
            child: Container(
              width: 26, // Indre cirkel, 3px mellemrum på hver side
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Center(
                child: Text(
                  score,
                  textAlign: TextAlign.center,
                  style: textStyle,
                ),
              ),
            ),
          ),
        );

      case ScoreMarker.singleBox:
        // Enkelt firkant (bogey)
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1.5),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Center(
            child: Text(
              score,
              textAlign: TextAlign.center,
              style: textStyle,
            ),
          ),
        );

      case ScoreMarker.doubleBox:
        // Dobbelt firkant (double bogey eller værre) - to separate firkanter
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1.5),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Center(
            child: Container(
              width: 26, // Indre firkant, 3px mellemrum på hver side
              height: 26,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1.5),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Center(
                child: Text(
                  score,
                  textAlign: TextAlign.center,
                  style: textStyle,
                ),
              ),
            ),
          ),
        );

      case ScoreMarker.none:
        // Ingen markering (par)
        return SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: Text(
              score,
              textAlign: TextAlign.center,
              style: textStyle,
            ),
          ),
        );
    }
  }
}

class _BottomInfo extends StatelessWidget {
  final Scorecard scorecard;

  const _BottomInfo({required this.scorecard});

  @override
  Widget build(BuildContext context) {
    final handicapResult = scorecard.handicapResult;
    final handicapResultStr = handicapResult != null 
        ? handicapResult.toStringAsFixed(1)
        : '-';
    
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BottomInfoRow('HCP resultat', handicapResultStr),
            _BottomInfoRow('Spiller', scorecard.player.name),
            _BottomInfoRow('Markør', '-'),
            _BottomInfoRow('Score status', 'Ikke-tællende'),
            _BottomInfoRow('PCC', '0'),
          ],
        ),
      ),
    );
  }
}

class _BottomInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _BottomInfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
