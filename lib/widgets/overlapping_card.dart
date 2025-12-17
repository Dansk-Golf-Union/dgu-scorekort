import 'package:flutter/material.dart';

/// Card der overlapper hero banner (moderne design pattern)
class OverlappingCard extends StatelessWidget {
  final Widget child;
  final double overlapAmount; // Hvor meget der overlapper hero
  final EdgeInsets? margin;
  
  const OverlappingCard({
    super.key,
    required this.child,
    this.overlapAmount = 40,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -overlapAmount), // Træk op over hero
      child: Padding(
        padding: margin ?? const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      ),
    );
  }
}

