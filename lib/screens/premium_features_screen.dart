import 'package:flutter/material.dart';

/// A placeholder screen for premium features such as analytics, photo uploads, and listings.
/// UI polish and full logic are planned for future releases.
class PremiumFeaturesScreen extends StatelessWidget {
  const PremiumFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
   // final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Features'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _FeatureCard(
            icon: Icons.analytics,
            title: 'Analytics & Forecasting',
            description: 'Advanced analytics and forecasting features coming soon for premium users.',
          ),
          const SizedBox(height: 16),
          _FeatureCard(
            icon: Icons.photo_library,
            title: 'Photo Uploads',
            description: 'Upload and manage photos for receipts and listings (UI polish in progress).',
          ),
          const SizedBox(height: 16),
          _FeatureCard(
            icon: Icons.list_alt,
            title: 'Listings',
            description: 'Enhanced listings for premium members. UI improvements and new features coming soon.',
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.primary),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(description, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
