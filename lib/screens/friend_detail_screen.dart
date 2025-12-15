import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/friend_profile_model.dart';
import '../models/handicap_trend_model.dart';
import '../providers/friends_provider.dart';
import '../theme/app_theme.dart';

class FriendDetailScreen extends StatefulWidget {
  final FriendProfile friend;

  const FriendDetailScreen({super.key, required this.friend});

  @override
  State<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends State<FriendDetailScreen> {
  bool _isLoading = true;
  int _selectedPeriod = 6; // months
  FriendProfile? _fullProfile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFullProfile();
  }

  Future<void> _loadFullProfile() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final friendsProvider = context.read<FriendsProvider>();
      
      // Check if we have homeClubId
      if (widget.friend.homeClubId == null) {
        throw Exception('Home club ID mangler');
      }
      
      // Fetch full profile with WHS scores
      final profile = await friendsProvider.loadFriendProfile(
        widget.friend.friendshipId,
        widget.friend.unionId,
        widget.friend.homeClubId!,
        forceRefresh: true,
      );
      
      // Recalculate trend for selected period
      final trend = HandicapTrend.fromScores(
        currentHcp: profile.currentHandicap,
        scores: profile.recentScores,
        periodMonths: _selectedPeriod,
      );
      
      if (mounted) {
        setState(() {
          _fullProfile = FriendProfile(
            friendshipId: profile.friendshipId,
            unionId: profile.unionId,
            name: profile.name,
            homeClubName: profile.homeClubName,
            homeClubId: profile.homeClubId,
            currentHandicap: profile.currentHandicap,
            trend: trend,
            recentScores: profile.recentScores,
            lastUpdated: profile.lastUpdated,
            createdAt: profile.createdAt,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _changePeriod(int months) {
    setState(() => _selectedPeriod = months);
    _loadFullProfile();
  }

  @override
  Widget build(BuildContext context) {
    final displayProfile = _fullProfile ?? widget.friend;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.friend.name),
        backgroundColor: AppTheme.dguGreen,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadFullProfile,
        child: _buildBody(displayProfile),
      ),
    );
  }
  
  Widget _buildBody(FriendProfile profile) {
    if (_isLoading && _fullProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return _buildErrorState();
    }
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildHeaderCard(profile),
          _buildPeriodSelector(),
          if (profile.trend.historyPoints.isNotEmpty)
            _buildHandicapTrendChart(profile),
          if (profile.trend.historyPoints.isNotEmpty)
            _buildHandicapTrendStats(profile),
          _buildRecentScoresCard(profile),
          _buildActionsSection(context, profile),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Kunne ikke indlæse data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Ukendt fejl',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loadFullProfile,
              child: const Text('Prøv igen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(FriendProfile profile) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.dguGreen,
              child: Text(
                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Name
            Text(
              profile.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Club
            Text(
              profile.homeClubDisplay,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            
            // Handicap
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.dguGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'HCP ${profile.currentHandicap.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dguGreen,
                ),
              ),
            ),
            
            // Trend indicator
            if (profile.trend.delta != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    profile.trend.isImproving
                        ? Icons.trending_down
                        : profile.trend.isWorsening
                            ? Icons.trending_up
                            : Icons.trending_flat,
                    color: profile.trend.isImproving
                        ? Colors.green
                        : profile.trend.isWorsening
                            ? Colors.red
                            : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    profile.trend.deltaDisplay,
                    style: TextStyle(
                      fontSize: 18,
                      color: profile.trend.isImproving
                          ? Colors.green
                          : profile.trend.isWorsening
                              ? Colors.red
                              : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildPeriodButton('3 mdr.', 3),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPeriodButton('6 mdr.', 6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPeriodButton('1 år', 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, int months) {
    final isSelected = _selectedPeriod == months;
    
    return FilledButton(
      onPressed: _isLoading ? null : () => _changePeriod(months),
      style: FilledButton.styleFrom(
        backgroundColor: isSelected 
          ? AppTheme.dguGreen 
          : Colors.grey.shade300,
        foregroundColor: isSelected 
          ? Colors.white 
          : Colors.black87,
      ),
      child: Text(label),
    );
  }

  Widget _buildHandicapTrendChart(FriendProfile profile) {
    if (profile.trend.historyPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final dataPoints = profile.trend.historyPoints;
    final minHcp = dataPoints.map((p) => p.handicap).reduce((a, b) => a < b ? a : b) - 1;
    final maxHcp = dataPoints.map((p) => p.handicap).reduce((a, b) => a > b ? a : b) + 1;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Handicap Udvikling',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${dataPoints.length} runder i perioden',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            
            // Chart
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: dataPoints.length > 4 ? (dataPoints.length / 4).ceilToDouble() : 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= dataPoints.length) {
                            return const SizedBox.shrink();
                          }
                          final date = dataPoints[index].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '${date.day}/${date.month}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  minX: 0,
                  maxX: (dataPoints.length - 1).toDouble(),
                  minY: minHcp,
                  maxY: maxHcp,
                  lineBarsData: [
                    LineChartBarData(
                      spots: dataPoints
                          .asMap()
                          .entries
                          .map((entry) => FlSpot(
                                entry.key.toDouble(),
                                entry.value.handicap,
                              ))
                          .toList(),
                      isCurved: true,
                      color: AppTheme.dguGreen,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: AppTheme.dguGreen,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.dguGreen.withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.white,
                      tooltipBorder: BorderSide(color: Colors.grey.shade300),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          if (index < 0 || index >= dataPoints.length) {
                            return null;
                          }
                          final point = dataPoints[index];
                          return LineTooltipItem(
                            'HCP ${point.handicap.toStringAsFixed(1)}\n${point.date.day}/${point.date.month}/${point.date.year}',
                            TextStyle(
                              color: AppTheme.dguGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandicapTrendStats(FriendProfile profile) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistik',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTrendStat(
                  'Tendens',
                  profile.trend.trendLabel,
                  profile.trend.trendEmoji,
                ),
                _buildTrendStat(
                  'Bedste HCP',
                  profile.trend.bestHcpDisplay,
                  '🏆',
                ),
                _buildTrendStat(
                  'Udvikling',
                  profile.trend.improvementRateDisplay,
                  '📊',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendStat(String label, String value, String emoji) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentScoresCard(FriendProfile profile) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seneste Scores',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (profile.recentScores.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Ingen scores endnu',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              )
            else
              ...profile.recentScores.take(5).map((score) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.dguGreen.withOpacity(0.1),
                      child: Text(
                        '${score.totalPoints}',
                        style: TextStyle(
                          color: AppTheme.dguGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(score.courseName),
                    subtitle: Text(score.formattedDate),
                    trailing: Text(
                      'HCP ${score.handicapBefore.toStringAsFixed(1)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context, FriendProfile profile) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Remove friend button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleRemoveFriend(context, profile),
              icon: const Icon(Icons.person_remove),
              label: const Text('Fjern som ven'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRemoveFriend(BuildContext context, FriendProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fjern ven?'),
        content: Text(
          'Er du sikker på at du vil fjerne ${profile.name} som ven? '
          'Du vil ikke længere kunne se deres handicap.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuller'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Fjern'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final friendsProvider = context.read<FriendsProvider>();
      await friendsProvider.removeFriend(profile.friendshipId);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${profile.name} fjernet som ven')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fejl: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
