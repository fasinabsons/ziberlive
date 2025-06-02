import 'package:flutter/material.dart';

/// Placeholder for AdMob banner ad integration.
/// Replace this with actual AdMob widget when SDK is added.
class AdMobBannerPlaceholder extends StatelessWidget {
  const AdMobBannerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.yellow[700]?.withValues(alpha:0.2),
        border: Border.all(color: Colors.yellow[800]!, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'AdMob Banner Placeholder',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
