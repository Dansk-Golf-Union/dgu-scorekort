import 'package:flutter/material.dart';
import '../models/activity_item_model.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Activity card widget for the feed
/// Similar to FriendCard structure
class ActivityCard extends StatelessWidget {
  final ActivityItem activity;
  final VoidCallback? onDismiss; // For future swipe-to-dismiss

  const ActivityCard({
    super.key,
    required this.activity,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (icon + title)
            Row(
              children: [
                _buildIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.getTitle(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(activity.timestamp),
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
            // Message
            Text(
              activity.getMessage(),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (activity.type) {
      case ActivityType.milestone:
        icon = Icons.emoji_events;
        color = Colors.amber;
        break;
      case ActivityType.improvement:
        icon = Icons.trending_down;
        color = Colors.green;
        break;
      case ActivityType.personalBest:
        icon = Icons.star;
        color = AppTheme.dguGreen;
        break;
      case ActivityType.eagle:
        icon = Icons.flight;
        color = Colors.blue;
        break;
      case ActivityType.albatross:
        icon = Icons.flight_takeoff;
        color = Colors.purple;
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0) {
      return 'I dag';
    } else if (diff.inDays == 1) {
      return 'I går';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} dage siden';
    } else {
      return DateFormat('d. MMM yyyy', 'da').format(timestamp);
    }
  }
}

