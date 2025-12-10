import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import '../services/scorecard_storage_service.dart';
import '../theme/app_theme.dart';

/// Standalone screen for marker approval via external URL
/// Can be accessed directly via /marker-approval/{documentId}
class MarkerApprovalFromUrlScreen extends StatefulWidget {
  final String documentId;

  const MarkerApprovalFromUrlScreen({
    super.key,
    required this.documentId,
  });

  @override
  State<MarkerApprovalFromUrlScreen> createState() =>
      _MarkerApprovalFromUrlScreenState();
}

class _MarkerApprovalFromUrlScreenState
    extends State<MarkerApprovalFromUrlScreen> {
  final _storage = ScorecardStorageService();
  Map<String, dynamic>? _scorecardData;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadScorecard();
  }

  Future<void> _loadScorecard() async {
    print('🔍 Loading scorecard with ID: ${widget.documentId}');
    
    try {
      final data = await _storage.getScorecardById(widget.documentId);
      
      print('📦 Got data from Firestore: ${data != null ? 'YES' : 'NO'}');
      if (data != null) {
        print('📊 Data keys: ${data.keys}');
        print('📊 Status: ${data['status']}');
      }

      if (data == null) {
        print('❌ No data found');
        setState(() {
          _errorMessage = 'Scorekort ikke fundet';
          _isLoading = false;
        });
        return;
      }

      // Load data regardless of status - we'll show appropriate UI
      print('📋 Scorecard status: ${data['status']}');

      print('✅ Scorecard loaded successfully');
      setState(() {
        _scorecardData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading scorecard: $e');
      setState(() {
        _errorMessage = 'Fejl ved indlæsning: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _approveScorecard() async {
    if (_scorecardData == null) return;

    setState(() => _isProcessing = true);

    try {
      // For now, we'll use marker info from the scorecard
      // In production, you'd get this from authentication
      await _storage.approveScorecardById(
        documentId: widget.documentId,
        markerLifetimeId: _scorecardData!['markerId'] as String,
        markerHomeClubName: 'Godkendt via URL',
        markerSignature: 'URL_APPROVAL_${DateTime.now().millisecondsSinceEpoch}',
      );

      setState(() {
        _scorecardData!['status'] = 'approved';
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Scorekort godkendt!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fejl ved godkendelse: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<String?> _showRejectDialog() async {
    return await showDialog<String>(
      context: context,
      builder: (context) => _RejectDialog(),
    );
  }

  Future<void> _rejectScorecard() async {
    if (_scorecardData == null) return;

    // Show dialog/bottom sheet to get rejection reason
    final reason = await _showRejectDialog();

    if (reason == null || reason.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      await _storage.rejectScorecardById(
        documentId: widget.documentId,
        reason: reason,
      );

      setState(() {
        _scorecardData!['status'] = 'rejected';
        _scorecardData!['rejectionReason'] = reason;
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Scorekort afvist'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fejl ved afvisning: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Markør Godkendelse'),
        centerTitle: true,
        backgroundColor: AppTheme.dguGreen,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    print('🎨 Building body - isLoading: $_isLoading, hasError: ${_errorMessage != null}, hasData: ${_scorecardData != null}');
    
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Henter scorekort...'),
          ],
        ),
      );
    }

    // Show error only if we don't have data at all
    if (_scorecardData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Scorekort ikke fundet',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    print('📱 Rendering scorecard UI');
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildMarkerInfo(),
              const SizedBox(height: 16),
              _buildPlayerInfo(),
              const SizedBox(height: 16),
              _buildCourseInfo(),
              const SizedBox(height: 16),
              _buildScoresTable(),
              const SizedBox(height: 16),
              _buildSummary(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final status = _scorecardData!['status'] as String;
    Color statusColor = Colors.orange;
    String statusText = 'Afventer Godkendelse';
    IconData statusIcon = Icons.hourglass_empty;

    if (status == 'approved') {
      statusColor = Colors.green;
      statusText = 'Godkendt';
      statusIcon = Icons.check_circle;
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusText = 'Afvist';
      statusIcon = Icons.cancel;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dokument ID: ${widget.documentId}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spiller Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildInfoRow('Navn', _scorecardData!['playerName']),
            _buildInfoRow('DGU Nummer', _scorecardData!['playerId']),
            _buildInfoRow(
              'Handicap',
              _scorecardData!['playerHandicap'].toStringAsFixed(1),
            ),
            _buildInfoRow(
              'Spillehandicap',
              _scorecardData!['playingHandicap'].toString(),
            ),
            if (_scorecardData!['playerHomeClubName'] != null)
              _buildInfoRow('Hjemmeklub', _scorecardData!['playerHomeClubName']),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkerInfo() {
    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment_ind, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Tildelt Markør',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Navn', _scorecardData!['markerName']),
            _buildInfoRow('DGU Nummer', _scorecardData!['markerId']),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Du er tildelt som markør for dette scorekort',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseInfo() {
    final playedDate = (_scorecardData!['playedDate'] as dynamic).toDate();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bane Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildInfoRow('Bane', _scorecardData!['courseName']),
            _buildInfoRow('Tee', _scorecardData!['teeName']),
            _buildInfoRow(
              'Course Rating',
              _scorecardData!['courseRating'].toStringAsFixed(1),
            ),
            _buildInfoRow('Slope Rating', _scorecardData!['slopeRating'].toString()),
            _buildInfoRow(
              'Spillet',
              DateFormat('dd.MM.yyyy').format(playedDate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoresTable() {
    final holes = _scorecardData!['holes'] as List;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scorekort',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                columns: const [
                  DataColumn(label: Text('Hul', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Par', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Index', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Slag', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Points', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: holes.map((hole) {
                  final holeNumber = hole['holeNumber'] as int;
                  final par = hole['par'] as int;
                  final index = hole['index'] as int;
                  final strokes = hole['strokes'] as int?;
                  final strokesReceived = hole['strokesReceived'] as int;

                  // Calculate points
                  int points = 0;
                  if (strokes != null) {
                    points = par + strokesReceived - strokes + 2;
                    if (points < 0) points = 0;
                  }

                  return DataRow(
                    cells: [
                      DataCell(Text(holeNumber.toString())),
                      DataCell(Text(par.toString())),
                      DataCell(Text(index.toString())),
                      DataCell(Text(strokes?.toString() ?? '-')),
                      DataCell(Text(points.toString())),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Card(
      elevation: 2,
      color: AppTheme.dguGreen.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Resultat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Point',
                  _scorecardData!['totalPoints'].toString(),
                  Icons.emoji_events,
                ),
                if (_scorecardData!['totalStrokes'] != null)
                  _buildSummaryItem(
                    'Slag',
                    _scorecardData!['totalStrokes'].toString(),
                    Icons.golf_course,
                  ),
                _buildSummaryItem(
                  'Score',
                  _scorecardData!['adjustedGrossScore'].toString(),
                  Icons.scoreboard,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.dguGreen, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final status = _scorecardData!['status'] as String;

    if (status != 'pending') {
      // Already processed
      return Card(
        elevation: 2,
        color: status == 'approved' ? Colors.green.shade50 : Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                status == 'approved' ? Icons.check_circle : Icons.cancel,
                color: status == 'approved' ? Colors.green : Colors.red,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                status == 'approved' ? 'Dette scorekort er godkendt' : 'Dette scorekort er afvist',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (status == 'rejected' && _scorecardData!['rejectionReason'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Årsag: ${_scorecardData!['rejectionReason']}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  // Try to close the browser tab/window
                  html.window.close();
                },
                icon: const Icon(Icons.close),
                label: const Text('Luk Scorekort'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  foregroundColor: Colors.grey.shade700,
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Pending - show action buttons
    return Column(
      children: [
        FilledButton.icon(
          onPressed: _isProcessing ? null : _approveScorecard,
          icon: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.check_circle),
          label: const Text('✅ Godkend Scorekort'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(double.infinity, 56),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isProcessing ? null : _rejectScorecard,
          icon: const Icon(Icons.cancel),
          label: const Text('❌ Afvis Scorekort'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            minimumSize: const Size(double.infinity, 56),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectDialog extends StatefulWidget {
  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Afvis Scorekort'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Angiv venligst en årsag til afvisningen:'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'F.eks. "Forkerte scores på hul 3 og 5"',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            autofocus: false,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuller'),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Afvis'),
        ),
      ],
    );
  }
}

