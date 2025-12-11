import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/scorecard_provider.dart';
import '../providers/match_setup_provider.dart';
import '../models/scorecard_model.dart';
import '../models/player_model.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'marker_assignment_dialog.dart';
import '../services/scorecard_storage_service.dart';
import '../services/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

// Score marker types for visual indication
enum ScoreMarker {
  doubleCircle, // Eagle eller bedre (-2 eller bedre)
  singleCircle, // Birdie (-1)
  none, // Par (0)
  singleBox, // Bogey (+1)
  doubleBox, // Double bogey eller værre (+2 eller værre)
}

class ScorecardResultsScreen extends StatelessWidget {
  const ScorecardResultsScreen({super.key});

  /// Send scorecard to marker via Firebase
  Future<void> _sendToMarker(BuildContext context, Scorecard scorecard) async {
    // Step 1: Show marker assignment dialog
    final Player? marker = await showDialog<Player>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const MarkerAssignmentDialog(),
    );

    // User cancelled
    if (marker == null) return;

    final storage = ScorecardStorageService();

    try {
      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💾 Gemmer scorekort til Firebase...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Save scorecard with real marker info
      final documentId = await storage.saveScorecardForApproval(
        scorecard: scorecard,
        markerId: marker.unionId ?? marker.memberNo,
        markerName: marker.name,
      );

      // Wait a bit
      await Future.delayed(const Duration(seconds: 1));

      // Retrieve scorecard
      final retrievedData = await storage.getScorecardById(documentId);

      // Send push notification to marker
      bool notificationSent = false;
      if (retrievedData != null) {
        try {
          final notificationService = NotificationService();
          final approvalUrl =
              'https://dgu-scorekort.web.app/#/marker-approval/$documentId';

          print('📤 Sending notification to marker: ${marker.unionId ?? marker.memberNo}');

          notificationSent = await notificationService.sendMarkerApprovalNotification(
            markerUnionId: marker.unionId ?? marker.memberNo,
            playerName: scorecard.player.name,
            approvalUrl: approvalUrl,
          );

          if (notificationSent) {
            print('✅ Push notification sent to marker');
          } else {
            print('⚠️ Push notification failed (but scorecard was saved)');
          }
        } catch (e) {
          print('❌ Notification error: $e (but scorecard was saved)');
        }
      }

      if (context.mounted) {
        if (retrievedData != null) {
          // Success!
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 8),
                  Expanded(child: Text('Scorekort gemt!')),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Scorekortet er gemt og klar til godkendelse!'),
                  const SizedBox(height: 16),
                  // Notification status
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: notificationSent
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: notificationSent
                            ? Colors.green.shade200
                            : Colors.orange.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          notificationSent
                              ? Icons.notifications_active
                              : Icons.notifications_off,
                          color: notificationSent ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notificationSent
                                ? 'Push besked sendt til markør'
                                : 'Push besked kunne ikke sendes',
                            style: TextStyle(
                              fontSize: 12,
                              color: notificationSent
                                  ? Colors.green.shade900
                                  : Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Document ID: $documentId',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Spiller: ${retrievedData['playerName']}'),
                  Text(
                    'Markør: ${retrievedData['markerName']} (${retrievedData['markerId']})',
                  ),
                  Text('Status: ${retrievedData['status']}'),
                  Text('Total Points: ${retrievedData['totalPoints']}'),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Markør Godkendelses-link:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _buildUrlButton(
                    context,
                    'https://dgu-scorekort.web.app/#/marker-approval/$documentId',
                    'Åbn i ny tab',
                    Icons.open_in_new,
                  ),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          throw Exception('Kunne ikke hente scorekort fra Firebase');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Firebase test fejl: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  static Widget _buildUrlButton(
    BuildContext context,
    String url,
    String label,
    IconData icon,
  ) {
    return OutlinedButton.icon(
      onPressed: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication, // Opens in new tab/browser
          );
        } else {
          // Fallback: copy to clipboard
          await Clipboard.setData(ClipboardData(text: url));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('URL kopieret til clipboard: $url'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      icon: Icon(icon, size: 16),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            url,
            style: const TextStyle(fontSize: 9, fontFamily: 'monospace'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue,
        side: const BorderSide(color: Colors.blue),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScorecardProvider>(
      builder: (context, provider, child) {
        final scorecard = provider.scorecard;

        if (scorecard == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Resultat')),
            body: const Center(child: Text('Ingen scorekort data')),
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

                    // Marker status (if approved)
                    if (scorecard.isMarkerApproved) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Markør godkendt: ${scorecard.markerFullName}',
                                    style: TextStyle(
                                      color: Colors.green.shade900,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (scorecard.markerSignature != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 60,
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Image.memory(
                                        base64Decode(
                                          scorecard.markerSignature!,
                                        ),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Warning if not approved
                    if (!scorecard.isMarkerApproved &&
                        !scorecard.isSubmitted) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Score skal godkendes af markør før indsendelse',
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Submission status
                    if (scorecard.isSubmitted)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_done,
                              size: 48,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Score indsendt!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                'dd.MM.yyyy HH:mm',
                              ).format(scorecard.submittedAt!),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Send to marker via Firebase
                    FilledButton.icon(
                      onPressed: () => _sendToMarker(context, scorecard),
                      icon: const Icon(Icons.send),
                      label: const Text('Send til Markør'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: Colors.blue,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Back button
                    OutlinedButton.icon(
                      onPressed: () {
                        // Reset all selections and scorecard data
                        context.read<MatchSetupProvider>().reset();
                        context.read<ScorecardProvider>().clearScorecard();

                        // Navigate back to start
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Tilbage til Start'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        foregroundColor: AppTheme.dguGreen,
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
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
        ...front9Holes.map(
          (hole) => _buildHoleRow(hole, front9Holes.indexOf(hole)),
        ),

        // Ud summary (for 18 holes)
        if (is18Holes) _buildSummaryRow('Ud', front9Holes, true),

        // Back 9 holes (for 18 holes)
        if (is18Holes)
          ...back9Holes.map(
            (hole) => _buildHoleRow(hole, back9Holes.indexOf(hole)),
          ),

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
          score: hole.isPickedUp ? '—' : (hole.strokes?.toString() ?? '-'),
          marker: hole.isPickedUp ? ScoreMarker.none : _getScoreMarker(hole),
        ),
        _DataCell(hole.stablefordPoints.toString()),
        _DataCell(hole.adjustedScore.toString()),
      ],
    );
  }

  TableRow _buildSummaryRow(
    String label,
    List<HoleScore> holes,
    bool isSubtotal,
  ) {
    final totalPar = holes.fold<int>(0, (sum, h) => sum + h.par);
    final totalPoints = holes.fold<int>(
      0,
      (sum, h) => sum + h.stablefordPoints,
    );

    // Check if any hole has null strokes (dash in Slag column)
    final hasAnyDash = holes.any((h) => h.strokes == null);

    // Calculate actual strokes total (only if no dashes)
    final totalStrokes = hasAnyDash
        ? ''
        : holes.fold<int>(0, (sum, h) => sum + (h.strokes ?? 0)).toString();

    // Calculate adjusted score total (always shown)
    final totalAdjustedScore = holes.fold<int>(
      0,
      (sum, h) => sum + h.adjustedScore,
    );

    return TableRow(
      decoration: BoxDecoration(
        color: isSubtotal ? Colors.grey.shade100 : Colors.grey.shade200,
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

  ScoreMarker _getScoreMarker(HoleScore hole) {
    if (hole.strokes == null) return ScoreMarker.none;

    // Beregn relativt til BANENS PAR (ikke netto par)
    final diff = hole.strokes! - hole.par;

    if (diff <= -2) return ScoreMarker.doubleCircle; // Eagle eller bedre
    if (diff == -1) return ScoreMarker.singleCircle; // Birdie
    if (diff == 0) return ScoreMarker.none; // Par
    if (diff == 1) return ScoreMarker.singleBox; // Bogey
    return ScoreMarker.doubleBox; // Double bogey eller værre
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

  const _MarkedScoreCell({required this.score, required this.marker});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Center(child: _buildMarkedContainer()),
    );
  }

  Widget _buildMarkedContainer() {
    const textStyle = TextStyle(fontWeight: FontWeight.w500, fontSize: 14);

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
            child: Text(score, textAlign: TextAlign.center, style: textStyle),
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
            child: Text(score, textAlign: TextAlign.center, style: textStyle),
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
            child: Text(score, textAlign: TextAlign.center, style: textStyle),
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
            _BottomInfoRow('Markør', scorecard.markerFullName ?? '__________'),
            _BottomInfoRow(
              'Score status',
              scorecard.isSubmitted ? 'Indsendt' : 'Ikke-tællende',
            ),
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
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
