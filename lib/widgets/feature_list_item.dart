import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Feature list item med lock state (inspireret af moderne apps)
class FeatureListItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool isLocked;
  final VoidCallback? onTap;
  
  const FeatureListItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = isLocked ? AppTheme.lockedGrey : iconColor;
    final effectiveTextColor = isLocked ? AppTheme.lockedTextGrey : Colors.black87;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: effectiveIconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: effectiveIconColor,
          size: 28,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: effectiveTextColor,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: effectiveTextColor.withOpacity(0.7),
          ),
        ),
      ),
      trailing: isLocked
          ? const Icon(
              Icons.lock_outline,
              color: AppTheme.lockedGrey,
              size: 24,
            )
          : const Icon(
              Icons.chevron_right,
              color: Colors.black38,
              size: 24,
            ),
      onTap: isLocked ? null : onTap,
    );
  }
}

