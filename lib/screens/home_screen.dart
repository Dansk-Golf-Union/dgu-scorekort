import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove hamburger menu
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'DANSK GOLF UNION',
              style: TextStyle(
                color: AppTheme.dguGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Container(
              height: 2,
              width: 200,
              decoration: const BoxDecoration(
                color: AppTheme.dguGreen,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: AppTheme.dguGreen),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.dguGreen),
            tooltip: 'Indstillinger',
            onPressed: () {
              // TODO: Navigate to settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Indstillinger coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.dguGreen),
            tooltip: 'Notifikationer',
            onPressed: () {
              // TODO: Show notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifikationer coming soon!')),
              );
            },
          ),
        ],
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
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Indstillinger'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to settings
              },
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex == 4 ? 0 : _selectedIndex, // Don't highlight Menu
        onTap: (index) {
          if (index == 4) {
            // Menu tapped - open drawer without changing selected index
            _scaffoldKey.currentState?.openDrawer();
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.dguGreen,
        unselectedItemColor: Colors.grey,
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

/// Scores Preview Card (Placeholder - vil blive erstattet med WHS API data)
class _ScoresPreviewCard extends StatelessWidget {
  const _ScoresPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.golf_course, color: AppTheme.dguGreen),
              title: Text('Nordvestjysk GC'),
              subtitle: Text('42 points • 10. Dec 2024'),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.golf_course, color: AppTheme.dguGreen),
              title: Text('Aarhus GC'),
              subtitle: Text('39 points • 5. Dec 2024'),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.golf_course, color: AppTheme.dguGreen),
              title: Text('Outrup Golfklub'),
              subtitle: Text('38 points • 1. Dec 2024'),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to score arkiv
              },
              child: const Text('Se arkiv →'),
            ),
          ],
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
