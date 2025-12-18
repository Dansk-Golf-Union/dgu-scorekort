import 'package:flutter/material.dart';
import 'golf_nl_demo_common.dart';

class GolfNlFriendsDemo extends StatelessWidget {
  const GolfNlFriendsDemo({super.key});

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
      ),
      body: Column(
        children: [
          // Grøn header
          const GolfNlHeader(
            title: 'Mine Venner',
            height: 160,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildFriendCard(
                  name: 'Jonas Meyer',
                  club: 'Dragør Golfklub',
                  hcp: '-0.9',
                  medal: '🥇',
                  rank: 1,
                ),
                const SizedBox(height: 12),
                _buildFriendCard(
                  name: 'Mit Golf Tester',
                  club: 'Rungsted Golf Klub',
                  hcp: '8.4',
                  medal: '🥈',
                  rank: 2,
                ),
                const SizedBox(height: 12),
                _buildFriendCard(
                  name: 'Test Mellemnavn',
                  club: 'Dansk Golf Union',
                  hcp: '10.2',
                  medal: '🥉',
                  rank: 3,
                ),
                const SizedBox(height: 12),
                _buildFriendCard(
                  name: 'Ole Haag',
                  club: 'Fredensborg Golf Club',
                  hcp: '16.5',
                  rank: 4,
                ),
                const SizedBox(height: 12),
                _buildFriendCard(
                  name: 'Peter Jensen',
                  club: 'København Golf Klub',
                  hcp: '18.2',
                  rank: 5,
                ),
                const SizedBox(height: 12),
                _buildFriendCard(
                  name: 'Lars Nielsen',
                  club: 'Rungsted Golf Klub',
                  hcp: '21.5',
                  rank: 6,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: GolfNlColors.cyan,
        icon: const Icon(Icons.person_add),
        label: const Text('Tilføj Ven'),
      ),
    );
  }

  Widget _buildFriendCard({
    required String name,
    required String club,
    required String hcp,
    String? medal,
    required int rank,
  }) {
    return Container(
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
      child: Row(
        children: [
          // Avatar med rank badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              GolfNlAvatar(
                initials: name.split(' ').map((n) => n[0]).join(),
                size: 56,
                backgroundColor: _getColorForRank(rank),
              ),
              if (medal != null)
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      medal,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        club,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: GolfNlColors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'HCP',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  hcp,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: GolfNlColors.darkBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForRank(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Guld
      case 2:
        return const Color(0xFFC0C0C0); // Sølv
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return GolfNlColors.green;
    }
  }
}

