import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb and kDebugMode
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/add_friend_dialog.dart';
import '../models/score_record_model.dart';
import '../models/news_article_model.dart';
import '../services/whs_statistik_service.dart';
import '../services/golfdk_news_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Home Screen med bottom navigation for v2.0 Extended POC
/// Bottom navigation: Hjem, Venner, Feed, Tops, Menu
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
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
              mainAxisAlignment: MainAxisAlignment.end, // Push logo to bottom
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8), // Small margin from bottom
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      Image.asset(
                        'assets/images/dgu_logo.png',
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.mail_outline, color: AppTheme.dguGreen),
                        tooltip: 'Beskeder',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Beskeder coming soon!')),
                          );
                        },
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
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to privacy settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add, color: AppTheme.dguGreen),
              title: const Text('🧪 TEST: Tilføj Ven'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => const AddFriendDialog(),
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
      body: IndexedStack(
        index: _selectedIndex == 4 ? 0 : _selectedIndex, // If Menu tapped, show Hjem
        children: const [
          _HjemTab(),
          _VennerTab(),
          _FeedTab(),
          _TopsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false, // Don't add padding at top
          child: Container(
            padding: const EdgeInsets.only(bottom: 8), // Only bottom padding
            child: BottomNavigationBar(
              currentIndex: _selectedIndex == 4 ? 0 : _selectedIndex,
              onTap: (index) {
                if (index == 4) {
                  _scaffoldKey.currentState?.openDrawer();
                } else {
                  setState(() => _selectedIndex = index);
                }
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppTheme.dguGreen,
              unselectedItemColor: Colors.grey,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedFontSize: 12,
              unselectedFontSize: 11,
              iconSize: 28,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Hjem',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Venner',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.feed),
                  label: 'Feed',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.emoji_events),
                  label: 'Tops',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu),
                  label: 'Menu',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'DGU Scorekort',
      applicationVersion: 'v2.0 Extended POC',
      applicationLegalese: '© 2024 Dansk Golf Union',
      children: const [
        SizedBox(height: 20),
        Text(
          'Native scorecard app med handicap-focused social features.\n\n'
          'Proof of Concept for integration i DGU Mit Golf app.',
        ),
      ],
    );
  }
}

/// Hjem Tab - Dashboard med player card, quick actions og previews
class _HjemTab extends StatelessWidget {
  const _HjemTab();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final player = authProvider.currentPlayer;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player Info Card (Mit Golf style)
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
                            '# ${player.lifetimeId ?? player.memberNo}',
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
            const SizedBox(height: 24),
          ],

          // Quick Actions
          const Text(
            '🏌️ Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: double.infinity,
              child: _QuickActionCard(
                icon: Icons.golf_course,
                title: 'Start Ny Runde',
                color: AppTheme.dguGreen,
                onTap: () {
                  // Navigate to scorecard setup screen
                  context.push('/setup-round');
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Venner Preview
          const Text(
            '👥 Venner',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const _VennerPreviewCard(),
          const SizedBox(height: 24),

          // Aktivitet Preview
          const Text(
            '📰 Aktivitet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const _AktivitetPreviewCard(),
          const SizedBox(height: 24),

          // Mine Seneste Scores Preview
          const Text(
            '📜 Mine Seneste Scores',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const _ScoresPreviewCard(),
          const SizedBox(height: 24),

          // Seneste Nyheder
          const Text(
            '🗞️ Seneste Nyheder',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const _NewsPreviewCard(),
        ],
      ),
    );
  }
}

/// Quick Action Card Widget
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Venner Preview Card (Placeholder)
class _VennerPreviewCard extends StatelessWidget {
  const _VennerPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const ListTile(
              leading: CircleAvatar(child: Icon(Icons.person)),
              title: Text('Jonas Meyer'),
              subtitle: Text('Handicap: 12.0 📉 -0.8'),
              trailing: Text('Forbedret', style: TextStyle(color: Colors.green)),
            ),
            const ListTile(
              leading: CircleAvatar(child: Icon(Icons.person)),
              title: Text('Peter Hansen'),
              subtitle: Text('Handicap: 8.7 🏆 Single-digit!'),
              trailing: Icon(Icons.emoji_events, color: Colors.amber),
            ),
            const ListTile(
              leading: CircleAvatar(child: Icon(Icons.person)),
              title: Text('Anne Nielsen'),
              subtitle: Text('Handicap: 15.2 → Stabil'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to Venner tab
              },
              child: const Text('Se alle venner →'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aktivitet Preview Card (Placeholder)
class _AktivitetPreviewCard extends StatelessWidget {
  const _AktivitetPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.trending_down, color: Colors.green, size: 32),
              title: Text('Jonas sænkede handicap!'),
              subtitle: Text('12.8 → 12.0 (-0.8) • I dag'),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.emoji_events, color: Colors.amber, size: 32),
              title: Text('Peter nåede single-digit handicap!'),
              subtitle: Text('10.3 → 9.8 • I går'),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.sports_golf, color: AppTheme.dguGreen, size: 32),
              title: Text('Nick vandt match 3/2'),
              subtitle: Text('vs Jonas Meyer • I går'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to Feed tab
              },
              child: const Text('Se aktivitet feed →'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Scores Preview Card - Shows last 3 scores from WHS API
class _ScoresPreviewCard extends StatefulWidget {
  const _ScoresPreviewCard();

  @override
  State<_ScoresPreviewCard> createState() => _ScoresPreviewCardState();
}

class _ScoresPreviewCardState extends State<_ScoresPreviewCard> {
  final _whsService = WhsStatistikService();
  Future<List<ScoreRecord>>? _scoresFuture;

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  void _loadScores() {
    final authProvider = context.read<AuthProvider>();
    final player = authProvider.currentPlayer;

    if (player != null && player.unionId != null && player.homeClubId != null) {
      setState(() {
        _scoresFuture = _whsService.getPlayerScores(
          unionId: player.unionId!,
          clubId: player.homeClubId!,
          limit: 3,
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

/// Venner Tab (Placeholder)
class _VennerTab extends StatelessWidget {
  const _VennerTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'Venner',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Handicap tracking for dine venner\n\nComing soon in Phase 2!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Feed Tab (Placeholder)
class _FeedTab extends StatelessWidget {
  const _FeedTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feed, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'Activity Feed',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Handicap milestones og score highlights\n\nComing soon in Phase 2!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Tops Tab (Placeholder)
class _TopsTab extends StatelessWidget {
  const _TopsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'Leaderboards',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Handicap rankings og score leaderboards\n\nComing soon in Phase 2!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// News Preview Card - Shows latest 3 articles from Golf.dk
class _NewsPreviewCard extends StatefulWidget {
  const _NewsPreviewCard();

  @override
  State<_NewsPreviewCard> createState() => _NewsPreviewCardState();
}

class _NewsPreviewCardState extends State<_NewsPreviewCard> {
  final _newsService = GolfDkNewsService();
  Future<List<NewsArticle>>? _newsFuture;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  void _loadNews() {
    setState(() {
      _newsFuture = _newsService.getLatestNews(limit: 3);
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
                    onPressed: _loadNews,
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
