import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb and kDebugMode
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/friends_provider.dart';
import '../providers/dashboard_preferences_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/birdie_bonus_bar.dart';
import '../models/score_record_model.dart';
import '../models/news_article_model.dart';
import '../models/birdie_bonus_model.dart';
import '../models/activity_item_model.dart';
import '../models/tournament_model.dart';
import '../models/ranking_model.dart';
import '../services/whs_statistik_service.dart';
import '../services/golfdk_news_service.dart';
import '../services/birdie_bonus_service.dart';
import '../services/golf_events_service.dart';
import '../screens/privacy_settings_screen.dart';
import '../screens/dashboard_settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// Home Screen - Single-page dashboard (no bottom nav)
/// Dashboard with widgets linking to full-screen views
/// Navigation: Widgets → Full-screen → Back to dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Logo centered in full width (ignores envelope icon)
                      Center(
                        child: Image.asset(
                          'assets/images/dgu_logo.png',
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                      ),
                      // Burger menu icon positioned absolute to the right
                      Positioned(
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.menu, color: AppTheme.dguGreen),
                          tooltip: 'Menu',
                          onPressed: () {
                            _scaffoldKey.currentState?.openDrawer();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.dguGreen,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 35, color: AppTheme.dguGreen),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    authProvider.currentPlayer?.name ?? 'Bruger',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'HCP: ${authProvider.currentPlayer?.hcp.toStringAsFixed(1) ?? '-'}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.settings, color: AppTheme.dguGreen),
              title: const Text('Indstillinger'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Indstillinger coming soon!')),
                );
              },
            ),
            ListTile(
              title: const Text('Dark Mode'),
              trailing: Switch(
                value: context.watch<ThemeProvider>().isDarkMode,
                onChanged: (value) {
                  context.read<ThemeProvider>().setDarkMode(value);
                },
                activeColor: AppTheme.dguGreen,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_customize, color: AppTheme.dguGreen),
              title: const Text('Dashboard Indstillinger'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardSettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip, color: AppTheme.dguGreen),
              title: const Text('Privacy & Samtykke'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Om app'),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Log ud', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await authProvider.logout();
              },
            ),
          ],
        ),
      ),
      body: const _HjemTab(), // Single-page dashboard (no tabs, no bottom nav)
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'DGU Scorekort',
      applicationVersion: '2.0.0 Extended POC',
      applicationIcon: Image.asset('assets/images/dgu_logo.png', width: 50, height: 50),
      children: const <Widget>[
        SizedBox(height: 16),
        Text(
          '© 2025 Dansk Golf Union',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Text(
          'Native Flutter scorecard app med handicap-focused social features.',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 12),
        Text(
          'Proof of Concept for integration i DGU Mit Golf app.',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 16),
        Text(
          'Features:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text('• OAuth login med GolfBox', style: TextStyle(fontSize: 13)),
        Text('• Venner system og social feed', style: TextStyle(fontSize: 13)),
        Text('• Birdie Bonus integration', style: TextStyle(fontSize: 13)),
        Text('• Score historie fra WHS/Statistik', style: TextStyle(fontSize: 13)),
        Text('• Golf.dk news feed', style: TextStyle(fontSize: 13)),
      ],
    );
  }
}

/// Hjem Tab - Dashboard med player card, quick actions og previews
class _HjemTab extends StatefulWidget {
  const _HjemTab();

  @override
  State<_HjemTab> createState() => _HjemTabState();
}

class _HjemTabState extends State<_HjemTab> {
  final BirdieBonusService _birdieBonusService = BirdieBonusService();
  BirdieBonusData? _birdieBonusData;
  bool _isBirdieBonusParticipant = false;
  
  // CRITICAL FIX: Flags to ensure data loads only once
  // Without this, didChangeDependencies() would trigger multiple times
  // (whenever Provider data changes) causing redundant API calls
  bool _hasLoadedBirdieBonus = false;
  bool _hasLoadedFriends = false;

  @override
  void initState() {
    super.initState();
    // IMPORTANT: Do NOT load data here!
    // At this point in the lifecycle, Provider (AuthProvider) has not yet
    // established dependencies, so context.read<AuthProvider>().currentPlayer
    // will be null even if user is logged in. This caused the Birdie Bonus
    // bar to never appear - the load would fail silently in initState().
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // CRITICAL FIX: Load data here instead of initState()
    // didChangeDependencies() is called AFTER Provider dependencies are established,
    // ensuring AuthProvider.currentPlayer is available.
    //
    // Why this pattern:
    // 1. initState() runs BEFORE Provider context is ready → player is null
    // 2. didChangeDependencies() runs AFTER Provider context → player is available
    // 3. We use _hasLoadedBirdieBonus flag to prevent multiple loads
    //    (didChangeDependencies can be called multiple times during widget lifecycle)
    //
    // This pattern is necessary when loading data that depends on Provider state.
    if (!_hasLoadedBirdieBonus || !_hasLoadedFriends) {
      final authProvider = context.read<AuthProvider>();
      final player = authProvider.currentPlayer;
      
      // Check if player is fully loaded before attempting data fetch
      if (player != null && player.unionId != null && player.unionId!.isNotEmpty) {
        // Load Birdie Bonus data
        if (!_hasLoadedBirdieBonus) {
          _hasLoadedBirdieBonus = true; // Prevent re-loading on future calls
          _loadBirdieBonusData();
        }
        
        // Load friends data
        if (!_hasLoadedFriends) {
          _hasLoadedFriends = true; // Prevent re-loading on future calls
          context.read<FriendsProvider>().loadFriends(player.unionId!);
        }
      }
    }
  }

  Future<void> _loadBirdieBonusData() async {
    final authProvider = context.read<AuthProvider>();
    final player = authProvider.currentPlayer;

    print('🏌️ Loading Birdie Bonus data for unionId: ${player?.unionId}');

    if (player == null || player.unionId == null || player.unionId!.isEmpty) {
      print('⚠️ Player or unionId is null - skipping Birdie Bonus');
      setState(() {
        _isBirdieBonusParticipant = false;
      });
      return;
    }

    try {
      print('📡 Checking if ${player.unionId} is participating...');
      // First check if user is participating in Birdie Bonus
      final isParticipating = await _birdieBonusService.isParticipating(player.unionId!);
      print('✅ isParticipating result: $isParticipating');
      
      if (isParticipating) {
        print('📊 Fetching Birdie Bonus data...');
        // Only fetch data if participating
        final data = await _birdieBonusService.getBirdieBonusData(player.unionId!);
        print('🎉 Got Birdie Bonus data: $data');
        if (mounted) {
          setState(() {
            _birdieBonusData = data;
            _isBirdieBonusParticipant = true;
          });
        }
      } else {
        print('❌ User not participating - hiding bar');
        if (mounted) {
          setState(() {
            _isBirdieBonusParticipant = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading Birdie Bonus data: $e');
      if (mounted) {
        setState(() {
          _isBirdieBonusParticipant = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final player = authProvider.currentPlayer;
    final prefs = context.watch<DashboardPreferencesProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player Info Card (Mit Golf style) - Always first, non-reorderable
          if (player != null) ...[
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.account_circle, size: 48, color: AppTheme.dguGreen),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.home, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  player.homeClubName ?? 'Ingen klub',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '# ${player.unionId ?? player.memberNo}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.dguGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'HCP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            player.hcp.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Birdie Bonus Bar - Conditional, non-reorderable
            if (_isBirdieBonusParticipant && _birdieBonusData != null)
              BirdieBonusBar(data: _birdieBonusData!),
            
            const SizedBox(height: 24),
          ],

          // Quick Actions - Non-reorderable
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  'Bestil tid',
                  () => _launchUrl('https://www.golf.dk/'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  'DGU score',
                  () => context.push('/setup-round'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  'Indberet',
                  () => _launchUrl('https://www.golf.dk/'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  'Scorekort',
                  () => _launchUrl('https://www.golf.dk/'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // DYNAMIC WIDGETS - User can reorder these via settings
          ...prefs.widgetOrder.map((widgetId) => _buildWidgetById(widgetId, prefs)),
        ],
      ),
    );
  }
  
  /// Build a widget by its ID - used for dynamic rendering based on user preferences
  Widget _buildWidgetById(String id, DashboardPreferencesProvider prefs) {
    switch (id) {
      case 'news':
        return _buildNewsSection(prefs.newsCount);
      case 'friends':
        return _buildFriendsSection(prefs.friendsCount);
      case 'activities':
        return _buildActivitiesSection(prefs.activitiesCount);
      case 'scores':
        return _buildScoresSection(prefs.scoresCount);
      case 'tournaments':
        return _buildTournamentsSection(prefs.tournamentsCount);
      case 'rankings':
        return _buildRankingsSection(prefs.rankingsCount);
      default:
        return const SizedBox.shrink();
    }
  }
  
  Widget _buildNewsSection(int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nyheder fra Golf.dk',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (count > 0) const _NewsPreviewCard(),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildFriendsSection(int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mine Venner',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => context.push('/venner'),
              child: const Text('Se alle →'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (count > 0) const _MineVennerWidget(),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildActivitiesSection(int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Seneste Aktivitet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => context.push('/feed'),
              child: const Text('Se alle →'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (count > 0) const _SenesteAktivitetWidget(),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildScoresSection(int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mine Seneste Scores',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => context.push('/score-archive'),
              child: const Text('Se arkiv →'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (count > 0) const _MineSenesteScoresWidget(),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildTournamentsSection(int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TournamentsWidget(count: count),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRankingsSection(int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RankingsWidget(count: count),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.dguGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Mine Venner Widget - Shows friend summary with LIVE DATA
class _MineVennerWidget extends StatelessWidget {
  const _MineVennerWidget();

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<DashboardPreferencesProvider>();
    
    return Consumer<FriendsProvider>(
      builder: (context, friendsProvider, child) {
        final friends = friendsProvider.friends;
        final friendCount = friends.length;
        final friendsToShow = prefs.friendsCount;
        
        // Sort alphabetically for consistent order (matches "Alle" tab)
        final sortedFriends = List.from(friends)
          ..sort((a, b) => a.name.compareTo(b.name));

        return GestureDetector(
          onTap: () => context.push('/venner'),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Friend count header
                  Text(
                    friendCount == 0
                        ? 'Ingen venner endnu'
                        : '$friendCount ${friendCount == 1 ? 'ven' : 'venner'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  
                  // Empty state or friend list
                  if (friendCount == 0)
                    const ListTile(
                      leading: Icon(Icons.people_outline, color: Colors.grey, size: 32),
                      title: Text('Ingen venner endnu'),
                      subtitle: Text('Klik her for at tilføje venner'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    )
                  else
                    // Show friends alphabetically sorted
                    ...sortedFriends.take(friendsToShow).map((friend) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.dguGreen,
                              child: Text(
                                friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    friend.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'HCP ${friend.currentHandicap.toStringAsFixed(1)} • ${friend.homeClubName ?? "Ingen klub"}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Trend indicator (if available)
                            if (friend.trend.delta != null)
                              Icon(
                                friend.trend.delta! < 0 ? Icons.trending_down : Icons.trending_up,
                                color: friend.trend.delta! < 0 ? Colors.green : Colors.orange,
                                size: 20,
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Seneste Aktivitet Widget - Shows 2 most recent activities (LIVE DATA)
class _SenesteAktivitetWidget extends StatelessWidget {
  const _SenesteAktivitetWidget();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final friendsProvider = context.watch<FriendsProvider>();
    final prefs = context.watch<DashboardPreferencesProvider>();

    // Get list of friend union IDs + current user
    final friendIds = friendsProvider.friends.map((f) => f.unionId).toList();
    friendIds.add(authProvider.currentPlayer?.unionId ?? '');

    // Dynamic Firestore limit: buffer x3 for friend filtering (min 20, max 100)
    final firestoreLimit = (prefs.activitiesCount * 3).clamp(20, 100);

    return GestureDetector(
      onTap: () => context.push('/feed'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('activities')
                .orderBy('timestamp', descending: true)
                .limit(firestoreLimit) // Dynamic limit (min 20, max 100)
                .snapshots(),
            builder: (context, snapshot) {
              // Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                      color: AppTheme.dguGreen,
                    ),
                  ),
                );
              }

              // Error state
              if (snapshot.hasError) {
                return ListTile(
                  leading: const Icon(Icons.error_outline, color: Colors.red),
                  title: const Text('Kunne ikke hente aktiviteter'),
                  subtitle: Text(snapshot.error.toString()),
                  dense: true,
                );
              }

              // Parse activities and filter to friends
              final activities = snapshot.data!.docs
                  .map((doc) => ActivityItem.fromFirestore(doc))
                  .where((activity) => !activity.isDismissed)
                  .where((activity) => friendIds.contains(activity.userId))
                  .take(prefs.activitiesCount) // User's preference
                  .toList();

              // Empty state
              if (activities.isEmpty) {
                return const ListTile(
                  leading: Icon(Icons.feed_outlined, color: Colors.grey, size: 32),
                  title: Text('Ingen aktiviteter endnu'),
                  subtitle: Text('Følg venner for at se deres fremskridt'),
                  dense: true,
                );
              }

              // Render activities
              return Column(
                children: activities.asMap().entries.map((entry) {
                  final index = entry.key;
                  final activity = entry.value;
                  
                  return Column(
                    children: [
                      _buildActivityListTile(activity),
                      if (index < activities.length - 1) const Divider(),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActivityListTile(ActivityItem activity) {
    // Determine icon and color based on activity type
    IconData icon;
    Color color;
    
    switch (activity.type) {
      case ActivityType.improvement:
        icon = Icons.trending_down;
        color = Colors.green;
        break;
      case ActivityType.milestone:
        icon = Icons.emoji_events;
        color = Colors.amber;
        break;
      case ActivityType.eagle:
        icon = Icons.flight;
        color = Colors.blue;
        break;
      case ActivityType.albatross:
        icon = Icons.flight;
        color = Colors.purple;
        break;
      case ActivityType.personalBest:
        icon = Icons.star;
        color = Colors.orange;
        break;
    }

    return ListTile(
      leading: Icon(icon, color: color, size: 32),
      title: Text(activity.getTitle()),
      subtitle: Text(activity.getMessage()),
      dense: true,
    );
  }
}

/// Mine Seneste Scores Widget - Shows last 2-3 scores from WHS API
class _MineSenesteScoresWidget extends StatefulWidget {
  const _MineSenesteScoresWidget();

  @override
  State<_MineSenesteScoresWidget> createState() => _MineSenesteScoresWidgetState();
}

class _MineSenesteScoresWidgetState extends State<_MineSenesteScoresWidget> {
  final _whsService = WhsStatistikService();
  Future<List<ScoreRecord>>? _scoresFuture;
  int _lastScoresCount = 0;

  @override
  void initState() {
    super.initState();
    // Initial load will happen in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload scores when preferences change
    final prefs = context.watch<DashboardPreferencesProvider>();
    if (prefs.scoresCount != _lastScoresCount) {
      _lastScoresCount = prefs.scoresCount;
      if (prefs.scoresCount > 0) {
        _loadScores();
      }
    }
  }

  void _loadScores({int? limit}) {
    final authProvider = context.read<AuthProvider>();
    final prefs = context.read<DashboardPreferencesProvider>();
    final player = authProvider.currentPlayer;
    final scoresLimit = limit ?? prefs.scoresCount;

    if (player != null && player.unionId != null && player.homeClubId != null) {
      setState(() {
        _scoresFuture = _whsService.getPlayerScores(
          unionId: player.unionId!,
          clubId: player.homeClubId!,
          limit: scoresLimit, // Use preference
        );
      });
    } else {
      // Missing required data
      setState(() {
        _scoresFuture = Future.error('Mangler spillerinfo (unionId eller homeClubId)');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<ScoreRecord>>(
          future: _scoresFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    color: AppTheme.dguGreen,
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(
                    'Kunne ikke hente scores',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    snapshot.error.toString().replaceAll('Exception: ', ''),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _loadScores,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Prøv igen'),
                  ),
                ],
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Column(
                children: [
                  const Icon(Icons.golf_course, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'Ingen runder endnu',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Dine godkendte runder vil dukke op her',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }

            final scores = snapshot.data!;
            return Column(
              children: [
                ...scores.asMap().entries.map((entry) {
                  final index = entry.key;
                  final score = entry.value;
                  return Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.golf_course,
                          color: AppTheme.dguGreen,
                        ),
                        title: Text(
                          score.courseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${score.totalPoints} points • ${score.formattedDate}',
                        ),
                        trailing: Icon(
                          score.isQualifying
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: score.isQualifying ? Colors.green : Colors.orange,
                        ),
                      ),
                      if (index < scores.length - 1) const Divider(),
                    ],
                  );
                }),
                TextButton(
                  onPressed: () {
                    context.push('/score-archive');
                  },
                  child: const Text('Se arkiv →'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
/// Tops Tab (Placeholder)
/// News Preview Card - Shows latest 3 articles from Golf.dk
class _NewsPreviewCard extends StatefulWidget {
  const _NewsPreviewCard();

  @override
  State<_NewsPreviewCard> createState() => _NewsPreviewCardState();
}

class _NewsPreviewCardState extends State<_NewsPreviewCard> {
  final _newsService = GolfDkNewsService();
  Future<List<NewsArticle>>? _newsFuture;
  int _lastNewsCount = 0;

  @override
  void initState() {
    super.initState();
    // Initial load will happen in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load news when preferences change
    final prefs = context.watch<DashboardPreferencesProvider>();
    if (prefs.newsCount != _lastNewsCount) {
      _lastNewsCount = prefs.newsCount;
      if (prefs.newsCount > 0) {
        _loadNews(prefs.newsCount);
      }
    }
  }

  void _loadNews(int limit) {
    setState(() {
      _newsFuture = _newsService.getLatestNews(limit: limit);
    });
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kunne ikke åbne link: $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<NewsArticle>>(
          future: _newsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    color: AppTheme.dguGreen,
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(
                    'Kunne ikke hente nyheder',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    snapshot.error.toString().replaceAll('Exception: ', ''),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      final prefs = context.read<DashboardPreferencesProvider>();
                      _loadNews(prefs.newsCount);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Prøv igen'),
                  ),
                ],
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Column(
                children: [
                  const Icon(Icons.article, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'Ingen nyheder',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              );
            }

            final news = snapshot.data!;
            return Column(
              children: [
                ...news.asMap().entries.map((entry) {
                  final index = entry.key;
                  final article = entry.value;
                  // Proxy image URLs through corsproxy.io for web production to avoid CORS
                  final imageUrl = kIsWeb && !kDebugMode
                      ? 'https://corsproxy.io/?${Uri.encodeComponent(article.image)}'
                      : article.image;
                  
                  return Column(
                    children: [
                      InkWell(
                        onTap: () => _launchUrl(article.url),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image_not_supported),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      article.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      article.manchet,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (index < news.length - 1) const Divider(),
                    ],
                  );
                }),
                TextButton(
                  onPressed: () => _launchUrl('https://www.golf.dk'),
                  child: const Text('Se flere nyheder på Golf.dk →'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Turneringer & Ranglister Widget
/// 
/// Fetches tournaments and rankings from Firestore cache (updated nightly at 02:30 CET).
/// Shows first 3 of each by default, with "Vis alle →" / "Vis færre" toggle.
/// Turneringer Widget - Shows tournaments with independent expand/collapse
class _TournamentsWidget extends StatefulWidget {
  final int count; // Number of items to show (0-10)
  
  const _TournamentsWidget({required this.count});

  @override
  State<_TournamentsWidget> createState() => _TournamentsWidgetState();
}

class _TournamentsWidgetState extends State<_TournamentsWidget> {
  final GolfEventsService _eventsService = GolfEventsService();
  bool _isExpanded = false;
  List<Tournament> _tournaments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final tournaments = await _eventsService.getCurrentTournaments();
      setState(() {
        _tournaments = tournaments;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading tournaments: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (always visible)
            const Text(
              'Aktuelle Turneringer',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Loading state
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            // Empty state
            else if (_tournaments.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'Ingen turneringer tilgængelige',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            // Data loaded
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show items based on collapsed/expanded state
                  // Collapsed: widget.count (0-10), Expanded: ALL
                  if (!_isExpanded && widget.count > 0)
                    ..._tournaments.take(widget.count).map((tournament) => _buildTournamentItem(tournament)).toList()
                  else if (_isExpanded)
                    ..._tournaments.map((tournament) => _buildTournamentItem(tournament)).toList(),
                  
                  // "Vis alle" / "Vis færre" button
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Text(
                        _isExpanded ? 'Vis færre' : 'Vis alle →',
                        style: const TextStyle(fontWeight: FontWeight.w500),
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

  Widget _buildTournamentItem(Tournament tournament) {
    return InkWell(
      onTap: () => _launchUrl(tournament.url),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon with FutureBuilder for cached image
            FutureBuilder<String?>(
              future: _eventsService.getIconUrl(tournament.icon),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  // Use HTML img tag to bypass CORS
                  return _buildHtmlImage(snapshot.data!, 48, 48);
                }
                // Fallback icon while loading or if no URL
                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.emoji_events, color: Colors.grey),
                );
              },
            ),
            const SizedBox(width: 12),
            // Tournament info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tournament.title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tournament.tour} • ${tournament.starts} - ${tournament.ends}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    if (urlString.isEmpty) return;
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Build HTML img element to bypass CORS restrictions
  Widget _buildHtmlImage(String imageUrl, double width, double height) {
    final String viewType = 'img-${imageUrl.hashCode}';
    
    // Register view factory (only once per unique URL)
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final img = html.ImageElement()
          ..src = imageUrl
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover'
          ..style.borderRadius = '4px';
        return img;
      },
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: HtmlElementView(viewType: viewType),
      ),
    );
  }
}

/// Ranglister Widget - Shows rankings with independent expand/collapse
class _RankingsWidget extends StatefulWidget {
  final int count; // Number of items to show (0-10)
  
  const _RankingsWidget({required this.count});

  @override
  State<_RankingsWidget> createState() => _RankingsWidgetState();
}

class _RankingsWidgetState extends State<_RankingsWidget> {
  final GolfEventsService _eventsService = GolfEventsService();
  bool _isExpanded = false;
  List<Ranking> _rankings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final rankings = await _eventsService.getCurrentRankings();
      setState(() {
        _rankings = rankings;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading rankings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (always visible)
            const Text(
              'Aktuelle Ranglister',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Loading state
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            // Empty state
            else if (_rankings.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'Ingen ranglister tilgængelige',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            // Data loaded
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show items based on collapsed/expanded state
                  // Collapsed: widget.count (0-10), Expanded: ALL
                  if (!_isExpanded && widget.count > 0)
                    ..._rankings.take(widget.count).map((ranking) => _buildRankingItem(ranking)).toList()
                  else if (_isExpanded)
                    ..._rankings.map((ranking) => _buildRankingItem(ranking)).toList(),
                  
                  // "Vis alle" / "Vis færre" button
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Text(
                        _isExpanded ? 'Vis færre' : 'Vis alle →',
                        style: const TextStyle(fontWeight: FontWeight.w500),
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

  Widget _buildRankingItem(Ranking ranking) {
    return InkWell(
      onTap: () => _launchUrl(ranking.url),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon with FutureBuilder for cached image
            FutureBuilder<String?>(
              future: _eventsService.getIconUrl(ranking.icon),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  // Use HTML img tag to bypass CORS
                  return _buildHtmlImage(snapshot.data!, 48, 48);
                }
                // Fallback icon while loading or if no URL
                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.leaderboard, color: Colors.grey),
                );
              },
            ),
            const SizedBox(width: 12),
            // Ranking info
            Expanded(
              child: Text(
                ranking.title,
                style: const TextStyle(fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    if (urlString.isEmpty) return;
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Build HTML img element to bypass CORS restrictions
  Widget _buildHtmlImage(String imageUrl, double width, double height) {
    final String viewType = 'img-${imageUrl.hashCode}';
    
    // Register view factory (only once per unique URL)
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final img = html.ImageElement()
          ..src = imageUrl
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover'
          ..style.borderRadius = '4px';
        return img;
      },
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: HtmlElementView(viewType: viewType),
      ),
    );
  }
}
