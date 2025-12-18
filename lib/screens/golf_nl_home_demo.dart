import 'package:flutter/material.dart';
import 'golf_nl_demo_common.dart';

class GolfNlHomeDemo extends StatelessWidget {
  const GolfNlHomeDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.network(
          'https://www.dgu.org/wp-content/themes/custom-theme/assets/images/logo.png',
          height: 40,
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              'DANSK GOLF UNION',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Header
            const GolfNlHeader(
              title: 'Hej Nick Hüttel,',
              subtitle: 'Klar til at spille golf?',
              height: 220,
            ),
            const SizedBox(height: 24),
            
            // 3 Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 100,
                child: Row(
                  children: [
                    Expanded(
                      child: GolfNlQuickActionCard(
                        icon: Icons.calendar_today,
                        label: 'Bestil tid',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GolfNlQuickActionCard(
                        icon: Icons.edit_note,
                        label: 'DGU score',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GolfNlQuickActionCard(
                        icon: Icons.qr_code,
                        label: 'Scorekort',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Birdie Bonus Card
            _buildBirdieBonusCard(),
            const SizedBox(height: 24),

            // Social Feed
            _buildSocialFeed(),
            const SizedBox(height: 24),

            // Mine Venner Preview
            _buildFriendsPreview(),
            const SizedBox(height: 24),

            // News Carousel
            _buildNewsSection(),
            const SizedBox(height: 24),

            // Aktuelle Turneringer
            _buildTournamentsSection(),
            const SizedBox(height: 24),

            // Mine Seneste Scores
            _buildScoresSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBirdieBonusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [GolfNlColors.cyan, GolfNlColors.cyan.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: GolfNlColors.cyan.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Birdie Bonus',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '5 birdies • #143 i Syddanmark',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildSocialFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Seneste Aktivitet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildFeedItem(
          imageUrl: 'https://images.unsplash.com/photo-1592919505780-303950717480?w=800&q=80',
          icon: Icons.emoji_events,
          iconColor: Colors.amber,
          title: 'Single-Digit Handicap!',
          description: 'Jonas Meyer nåede HCP 9.8 på Dragør Golfklub',
          time: '2 timer siden',
          likes: 15,
          comments: 3,
        ),
        _buildFeedItem(
          imageUrl: 'https://images.unsplash.com/photo-1530028828-25e8270e8f08?w=800&q=80',
          icon: Icons.trending_up,
          iconColor: GolfNlColors.green,
          title: 'Stor forbedring!',
          description: 'Mit Golf Tester forbedrede sig med 1.2 slag til HCP 14.3',
          time: '5 timer siden',
          likes: 8,
          comments: 1,
        ),
        _buildFeedItem(
          imageUrl: 'https://images.unsplash.com/photo-1587174486073-ae5e5cff23aa?w=800&q=80',
          icon: Icons.sports_golf,
          iconColor: GolfNlColors.cyan,
          title: 'Perfekt runde!',
          description: 'Nick Hüttel spillede 42 points på Outrup Golfklub',
          time: '1 dag siden',
          likes: 12,
          comments: 2,
        ),
      ],
    );
  }

  Widget _buildFeedItem({
    required String imageUrl,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String time,
    required int likes,
    required int comments,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 180,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.favorite_border, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text('$likes', style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(width: 16),
                    Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text('$comments', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mine Venner',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Se alle →',
                style: TextStyle(
                  color: GolfNlColors.cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildFriendItem('Jonas Meyer', 'Dragør Golfklub', 'HCP -0.9'),
              const Divider(height: 24),
              _buildFriendItem('Mit Golf Tester', 'Rungsted Golf Klub', 'HCP 8.4'),
              const Divider(height: 24),
              _buildFriendItem('Ole Haag', 'Fredensborg Golf Club', 'HCP 16.5'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFriendItem(String name, String club, String hcp) {
    return Row(
      children: [
        const GolfNlAvatar(
          initials: 'JM',
          size: 50,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                club,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            hcp,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nyheder fra Golf.dk',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Se flere →',
                style: TextStyle(
                  color: GolfNlColors.cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildNewsCard(
                'https://images.unsplash.com/photo-1587174486073-ae5e5cff23aa?w=600',
                'Høst og Nyland klarer første cut',
                'Tre runder fra afgørelsen...',
              ),
              _buildNewsCard(
                'https://images.unsplash.com/photo-1535131749006-b7f58c99034b?w=600',
                'Danskere i fuld gang med tourskoler',
                'Går det efter planen...',
              ),
              _buildNewsCard(
                'https://images.unsplash.com/photo-1593111774240-d529f12a6c8b?w=600',
                'Ugens golf på tv',
                'To danskere er med på Mauritius...',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNewsCard(String imageUrl, String title, String subtitle) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
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
    );
  }

  Widget _buildTournamentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Aktuelle Turneringer',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildTournamentItem('AfrAsia Bank Mauritius Open', 'DP World Tour'),
              const Divider(height: 24),
              _buildTournamentItem('PNC Championship', 'Hyggeturnering for to generationer'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTournamentItem(String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.emoji_events, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mine Seneste Scores',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Se arkiv →',
                style: TextStyle(
                  color: GolfNlColors.cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildScoreItem('DGU - Ishøj - 18H', '97 points', '17. Sep 2025', true),
              const Divider(height: 24),
              _buildScoreItem('DGU Rungsted - 18H', '90 points', '30. Jul 2025', true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreItem(String course, String score, String date, bool approved) {
    return Row(
      children: [
        Icon(
          Icons.golf_course,
          color: GolfNlColors.green,
          size: 32,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$score • $date',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Icon(
          approved ? Icons.check_circle : Icons.cancel,
          color: approved ? GolfNlColors.green : GolfNlColors.red,
          size: 24,
        ),
      ],
    );
  }
}

