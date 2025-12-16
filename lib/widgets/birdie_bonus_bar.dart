import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/birdie_bonus_model.dart';

/// Birdie Bonus Bar Widget
/// 
/// Displays player's birdie count and leaderboard position in a compact card.
/// Design based on Mit Golf app screenshot with bird and trophy icons.
/// 
/// Tappable - opens Birdie Bonus leaderboard on golf.dk
/// 
/// Layout:
/// - Left side: Bird icon (48px) + birdie count
/// - Right side: Trophy icon (40px) + ranking position
/// - Orange/golden text color for numbers
class BirdieBonusBar extends StatelessWidget {
  final BirdieBonusData data;

  const BirdieBonusBar({
    super.key,
    required this.data,
  });

  Future<void> _launchBirdieBonusUrl() async {
    final uri = Uri.parse('https://www.golf.dk/birdie-bonus-ranglisten');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _launchBirdieBonusUrl,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(
                iconPath: 'assets/icons/birdie_icon.svg',
                iconSize: 48, // Birdie icon larger
                value: data.birdieCount.toString(),
                label: 'Birdies',
              ),
              _buildStat(
                iconPath: 'assets/icons/trophy_icon.svg',
                iconSize: 40, // Trophy icon smaller
                value: data.rankingPosition.toString(),
                label: 'Placering',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat({
    required String iconPath,
    required double iconSize,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // SVG Icon
        SvgPicture.asset(
          iconPath,
          width: iconSize,
          height: iconSize,
        ),
        const SizedBox(width: 16),
        // Value
        Text(
          value,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE1A740), // Orange/golden color from Mit Golf
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

