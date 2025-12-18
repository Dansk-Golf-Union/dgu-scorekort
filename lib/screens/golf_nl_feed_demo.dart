import 'package:flutter/material.dart';
import 'golf_nl_demo_common.dart';

class GolfNlFeedDemo extends StatelessWidget {
  const GolfNlFeedDemo({super.key});

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
            title: 'Aktivitetsfeed',
            subtitle: 'Følg med i dine venners præstationer',
            height: 180,
          ),
          
          // Tabs (statisk)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _buildTab('Alle', true),
                const SizedBox(width: 12),
                _buildTab('Milestones', false),
                const SizedBox(width: 12),
                _buildTab('Forbedringer', false),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildFeedItem(
                  imageUrl: 'https://images.unsplash.com/photo-1592919505780-303950717480?w=800&q=80',
                  icon: Icons.emoji_events,
                  iconColor: Colors.amber,
                  name: 'Nick Hüttel',
                  title: 'Single-Digit Handicap!',
                  description: 'Nick Hüttel nåede HCP 9.8 på Rungsted Golf Klub',
                  time: '3 dage siden',
                  likes: 24,
                  comments: 5,
                ),
                const SizedBox(height: 16),
                _buildFeedItem(
                  imageUrl: 'https://images.unsplash.com/photo-1530028828-25e8270e8f08?w=800&q=80',
                  icon: Icons.trending_up,
                  iconColor: GolfNlColors.green,
                  name: 'Mit Golf Tester',
                  title: 'Stor forbedring!',
                  description: 'Mit Golf Tester forbedrede sig med 1.2 slag til HCP 14.3',
                  time: '4 dage siden',
                  likes: 18,
                  comments: 3,
                ),
                const SizedBox(height: 16),
                _buildFeedItem(
                  imageUrl: 'https://images.unsplash.com/photo-1587174486073-ae5e5cff23aa?w=800&q=80',
                  icon: Icons.local_fire_department,
                  iconColor: GolfNlColors.red,
                  name: 'Jonas Meyer',
                  title: '3 Birdies på række!',
                  description: 'Jonas Meyer spillede en fantastisk runde på Dragør Golfklub',
                  time: '5 dage siden',
                  likes: 31,
                  comments: 7,
                ),
                const SizedBox(height: 16),
                _buildFeedItem(
                  imageUrl: 'https://images.unsplash.com/photo-1592919505780-303950717480?w=800&q=80',
                  icon: Icons.star,
                  iconColor: Colors.purple,
                  name: 'Ole Haag',
                  title: 'Første Eagle!',
                  description: 'Ole Haag fik sit første eagle på hul 15 på Fredensborg Golf Club',
                  time: '1 uge siden',
                  likes: 42,
                  comments: 12,
                ),
                const SizedBox(height: 16),
                _buildFeedItem(
                  imageUrl: 'https://images.unsplash.com/photo-1530028828-25e8270e8f08?w=800&q=80',
                  icon: Icons.workspace_premium,
                  iconColor: GolfNlColors.cyan,
                  name: 'Peter Jensen',
                  title: 'Turnerings Sejr!',
                  description: 'Peter Jensen vandt klubmesterskabet med 2 slag',
                  time: '2 uger siden',
                  likes: 67,
                  comments: 15,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? GolfNlColors.cyan : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: GolfNlColors.cyan.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.white : Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildFeedItem({
    required String imageUrl,
    required IconData icon,
    required Color iconColor,
    required String name,
    required String title,
    required String description,
    required String time,
    required int likes,
    required int comments,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                Image.network(
                  imageUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 220,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.image, size: 50, color: Colors.grey),
                      ),
                    );
                  },
                ),
                // Badge overlay
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info
                Row(
                  children: [
                    GolfNlAvatar(
                      initials: name.split(' ').map((n) => n[0]).join(),
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                
                // Description
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Interactions
                Row(
                  children: [
                    _buildInteractionButton(
                      Icons.favorite,
                      likes,
                      GolfNlColors.red,
                    ),
                    const SizedBox(width: 24),
                    _buildInteractionButton(
                      Icons.chat_bubble,
                      comments,
                      GolfNlColors.cyan,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.share_outlined,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton(IconData icon, int count, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

