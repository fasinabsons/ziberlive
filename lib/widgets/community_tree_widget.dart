import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Fixed Community tree visualization that avoids infinite width constraint
class CommunityTreeWidget extends StatelessWidget {
  final double treeLevel;
  final double height;
  final double width;

  const CommunityTreeWidget({
    super.key,
    required this.treeLevel,
    this.height = 200,
    this.width = 200, // Added width parameter with default
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Calculate the tree fullness (1-3 levels)
    final level = treeLevel.clamp(1, 3).toInt();
    final progress = treeLevel - level + 1;
    
    return SizedBox(
      height: height,
      width: width, // Set explicit width
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Ground - with fixed width instead of double.infinity
          Container(
            height: 20,
            width: width * 0.8, // Fixed width relative to parent
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary.withValues(alpha:0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(100)),
            ),
          ),
          
          // Tree trunk
          Positioned(
            bottom: 15,
            child: Container(
              height: height * 0.4 * progress,
              width: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5E3C),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
          
          // Tree foliage
          if (level >= 1)
            Positioned(
              bottom: height * 0.35 * progress,
              child: Container(
                height: height * 0.3 * progress,
                width: height * 0.3 * progress,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha:0.7),
                  shape: BoxShape.circle,
                ),
              ).animate().scale(duration: Duration(milliseconds: 1000), curve: Curves.elasticOut),
            ),
            
          if (level >= 2)
            Positioned(
              bottom: height * 0.45 * progress,
              child: Container(
                height: height * 0.25 * progress,
                width: height * 0.25 * progress,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha:0.7),
                  shape: BoxShape.circle,
                ),
              ).animate().scale(delay: Duration(milliseconds: 300), duration: Duration(milliseconds: 1000), curve: Curves.elasticOut),
            ),
            
          if (level >= 3)
            Positioned(
              bottom: height * 0.55 * progress,
              child: Container(
                height: height * 0.2 * progress,
                width: height * 0.2 * progress,
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withValues(alpha:0.7),
                  shape: BoxShape.circle,
                ),
              ).animate().scale(delay: Duration(milliseconds: 600), duration: Duration(milliseconds: 1000), curve: Curves.elasticOut),
            ),
        ],
      ),
    );
  }
}