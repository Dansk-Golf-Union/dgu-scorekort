import 'package:flutter/material.dart';
import '../models/friend_profile_model.dart';
import '../screens/friend_detail_screen.dart';

class FriendCard extends StatelessWidget {
  final FriendProfile friend;

  const FriendCard({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          friend.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          friend.homeClubName ?? 'Ingen hjemmeklub',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: _buildHandicapInfo(),
        onTap: () {
          // Navigate to detail screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FriendDetailScreen(friend: friend),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandicapInfo() {
    final hcp = friend.currentHandicap;
    final delta = friend.trend.delta;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'HCP ${hcp.toStringAsFixed(1)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (delta != null) _buildDeltaIndicator(delta),
      ],
    );
  }

  Widget _buildDeltaIndicator(double delta) {
    final isImproving = delta < -0.1;
    final isWorsening = delta > 0.1;
    final color = isImproving 
        ? Colors.green 
        : (isWorsening ? Colors.red : Colors.grey);
    final icon = isImproving 
        ? Icons.trending_down 
        : (isWorsening ? Icons.trending_up : Icons.trending_flat);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          delta > 0 ? '+${delta.toStringAsFixed(1)}' : delta.toStringAsFixed(1),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

