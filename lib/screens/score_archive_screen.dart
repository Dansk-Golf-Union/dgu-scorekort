import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/score_record_model.dart';
import '../providers/auth_provider.dart';
import '../services/whs_statistik_service.dart';
import '../theme/app_theme.dart';

/// Score Archive Screen
/// 
/// Displays full list of player's WHS scores fetched from Statistik API.
/// Features:
/// - Pull-to-refresh
/// - Loading states
/// - Error handling
/// - Empty state
class ScoreArchiveScreen extends StatefulWidget {
  const ScoreArchiveScreen({super.key});

  @override
  State<ScoreArchiveScreen> createState() => _ScoreArchiveScreenState();
}

class _ScoreArchiveScreenState extends State<ScoreArchiveScreen> {
  final _whsService = WhsStatistikService();
  List<ScoreRecord>? _scores;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final player = authProvider.currentPlayer;

      if (player == null || player.unionId == null) {
        throw Exception('Ingen spiller logget ind');
      }
      
      if (player.homeClubId == null) {
        throw Exception('Mangler hjemmeklub info');
      }

      final scores = await _whsService.getPlayerScores(
        unionId: player.unionId!,
        clubId: player.homeClubId!,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _scores = scores;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadScores();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.dguGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scorearkiv',
          style: TextStyle(color: AppTheme.dguGreen),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.dguGreen,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.dguGreen,
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_scores == null || _scores!.isEmpty) {
      return _buildEmptyState();
    }

    return _buildScoresList();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Kunne ikke hente scores',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Ukendt fejl',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadScores,
              icon: const Icon(Icons.refresh),
              label: const Text('Prøv igen'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.dguGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.golf_course,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Ingen runder endnu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dine godkendte runder vil dukke op her',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoresList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _scores!.length,
      itemBuilder: (context, index) {
        final score = _scores![index];
        return _ScoreCard(score: score);
      },
    );
  }
}

/// Individual score card widget
class _ScoreCard extends StatelessWidget {
  final ScoreRecord score;

  const _ScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course name
            Row(
              children: [
                const Icon(
                  Icons.golf_course,
                  size: 20,
                  color: AppTheme.dguGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    score.courseName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Points and strokes
            Row(
              children: [
                _InfoChip(
                  label: '${score.totalPoints} points',
                  icon: Icons.stars,
                  color: AppTheme.dguGreen,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  label: '${score.totalStrokes} slag',
                  icon: Icons.sports_golf,
                  color: Colors.grey[700]!,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Date and handicap
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  score.formattedDate,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                Text(
                  score.handicapDisplay,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Qualifying status
            Row(
              children: [
                Text(
                  score.qualifyingEmoji,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 4),
                Text(
                  score.qualifyingText,
                  style: TextStyle(
                    fontSize: 14,
                    color: score.isQualifying ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (score.holesPlayed != 18) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${score.holesPlayed} huller)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small info chip widget
class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

