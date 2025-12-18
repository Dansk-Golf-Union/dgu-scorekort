import 'package:flutter/material.dart';
import 'golf_nl_demo_common.dart';

class GolfNlNewsDemo extends StatelessWidget {
  const GolfNlNewsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Banner
            Stack(
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1535131749006-b7f58c99034b?w=1200',
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      color: GolfNlColors.green,
                      child: const Center(
                        child: Icon(Icons.image, size: 80, color: Colors.white),
                      ),
                    );
                  },
                ),
                Container(
                  height: 250,
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
                  top: 40,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nyheder fra Golf.dk',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Følg med i de seneste nyheder fra dansk golf',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Categories
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildCategoryChip('Alle', true),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Turneringer', false),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Danske Spillere', false),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Regler', false),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Featured News Carousel
            SizedBox(
              height: 260,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildFeaturedCard(
                    'https://images.unsplash.com/photo-1587174486073-ae5e5cff23aa?w=800',
                    'Høst og Nyland klarer første cut på Asian Tour',
                    'Tre runder fra afgørelsen lever chancen for danske medlemmer',
                    '2 timer siden',
                  ),
                  _buildFeaturedCard(
                    'https://images.unsplash.com/photo-1535131749006-b7f58c99034b?w=800',
                    'Danskere i fuld gang med tourskoler i Asien og Afrika',
                    'Går det efter planen, vil der være nye danske navne på LET',
                    '5 timer siden',
                  ),
                  _buildFeaturedCard(
                    'https://images.unsplash.com/photo-1593111774240-d529f12a6c8b?w=800',
                    'Ugens golf på tv - årsfarvel i ferieparadiset',
                    'To danskere er med på Mauritius, hvor en sidste chance for en sejr',
                    '8 timer siden',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Dark Blue Section - Seneste Nyheder
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: GolfNlColors.darkBlue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seneste Nyheder',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildNewsListItem(
                    'https://images.unsplash.com/photo-1596727362302-b8d891c42ab8?w=400',
                    'Bomalarm på Royal Liverpool',
                    'The Open-baan gesloten na vondst WW2-artilleriegranaat',
                    '7 uur geleden',
                  ),
                  const SizedBox(height: 16),
                  _buildNewsListItem(
                    'https://images.unsplash.com/photo-1587174486073-ae5e5cff23aa?w=400',
                    'Truust-Jørgensen golftalent Louise',
                    'Er her til at vise hvad hun vil have uithalen',
                    '10 timer siden',
                  ),
                  const SizedBox(height: 16),
                  _buildNewsListItem(
                    'https://images.unsplash.com/photo-1593111774240-d529f12a6c8b?w=400',
                    'Ny rekord for danske golfspillere',
                    'Flere medlemmer end nogensinde før',
                    '12 timer siden',
                  ),
                  const SizedBox(height: 16),
                  _buildNewsListItem(
                    'https://images.unsplash.com/photo-1535131749006-b7f58c99034b?w=400',
                    'Sæsonstart på Nordjyllands baner',
                    'Klubberne melder om stor interesse',
                    '1 dag siden',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? GolfNlColors.cyan : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? GolfNlColors.cyan.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.white : Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(String imageUrl, String title, String subtitle, String time) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.image, size: 60, color: Colors.grey),
                  ),
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
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: GolfNlColors.cyan,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      time,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
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

  Widget _buildNewsListItem(String imageUrl, String title, String subtitle, String time) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
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
                  color: Colors.grey.shade700,
                  child: const Icon(Icons.image, color: Colors.grey),
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
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: TextStyle(
                    color: GolfNlColors.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

