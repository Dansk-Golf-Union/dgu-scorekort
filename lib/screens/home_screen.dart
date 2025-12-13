import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

/// Home Screen med tab navigation for v2.0 Extended POC
/// 4 tabs: Hjem, Venner, Feed, Tops
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Menu',
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text('DGU Scorekort'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Indstillinger',
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifikationer',
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Hjem'),
            Tab(icon: Icon(Icons.people), text: 'Venner'),
            Tab(icon: Icon(Icons.feed), text: 'Feed'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Tops'),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
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
      body: TabBarView(
        controller: _tabController,
        children: const [
          _HjemTab(),
          _VennerTab(),
          _FeedTab(),
          _TopsTab(),
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

/// Hjem Tab - Dashboard med quick actions og previews
class _HjemTab extends StatelessWidget {
  const _HjemTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions
          const Text(
            '🏌️ Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.golf_course,
                  title: 'Start Ny\nRunde',
                  color: AppTheme.dguGreen,
                  onTap: () {
                    // Navigate to scorecard setup screen
                    context.push('/setup-round');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.people,
                  title: 'Match Play',
                  color: AppTheme.dguGreen.withOpacity(0.8),
                  onTap: () {
                    context.go('/match-play');
                  },
                ),
              ),
            ],
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

