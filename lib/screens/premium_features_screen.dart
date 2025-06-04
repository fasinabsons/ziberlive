import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ziberlive/providers/app_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ziberlive/providers/app_state_provider.dart';
import 'package:ziberlive/config.dart'; // For kMicrotransactionProducts and kSubscriptionPlans
import 'package:intl/intl.dart'; // For date formatting

/// Screen for premium features, store, and subscriptions.
class PremiumFeaturesScreen extends StatelessWidget {
  const PremiumFeaturesScreen({super.key});

  // Helper to format dates nicely
  String _formatDate(DateTime? date) {
    if (date == null) return "N/A";
    return DateFormat.yMMMd().format(date);
  }

  Future<void> _handlePurchase(BuildContext context, AppStateProvider appState, MicrotransactionProduct product) async {
    // Simulate purchase flow
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Confirm Purchase: ${product.name}?'),
          content: Text('Price: \$${product.priceUSD.toStringAsFixed(2)}\n\nThis is a simulated purchase. No real money will be charged.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Confirm Purchase'),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close confirmation dialog
                bool success = await appState.purchaseProduct(product);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} purchased successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Optionally, play an animation or update UI further
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Purchase failed for ${product.name}.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context); // listen:true to rebuild on status change
    final currentUser = appState.currentUser;

    String subscriptionStatusText = "No active subscription.";
    if (currentUser != null) {
      if (currentUser.isFreeTrialActive && currentUser.freeTrialExpiryDate != null && currentUser.freeTrialExpiryDate!.isAfter(DateTime.now())) {
        subscriptionStatusText = "Free Trial active until: ${_formatDate(currentUser.freeTrialExpiryDate)}";
      } else if (currentUser.activeSubscriptionId != null && currentUser.subscriptionExpiryDate != null && currentUser.subscriptionExpiryDate!.isAfter(DateTime.now())) {
        final plan = kSubscriptionPlans.firstWhere((p) => p.id == currentUser.activeSubscriptionId, orElse: () => kSubscriptionPlans.first); // Fallback for safety
        subscriptionStatusText = "Active: ${plan.name} until ${_formatDate(currentUser.subscriptionExpiryDate)}";
      }
    }

    bool canStartTrial = currentUser != null && !currentUser.isFreeTrialActive && currentUser.activeSubscriptionId == null && !(currentUser.freeTrialExpiryDate != null && currentUser.freeTrialExpiryDate!.isAfter(DateTime.now())); // check if trial was already used and expired based on date

    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Premium & Store'), // Updated title
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Subscription Status Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text("Subscription Status", style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(subscriptionStatusText, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  if (currentUser?.activeSubscriptionId != null)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cancel_schedule_send_rounded),
                      label: const Text("Cancel Subscription"),
                      onPressed: () async {
                        // Confirmation dialog
                        bool? confirmCancel = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext dialogContext) => AlertDialog(
                            title: const Text('Cancel Subscription?'),
                            content: const Text('Are you sure you want to cancel your current subscription? This action cannot be undone immediately.'),
                            actions: <Widget>[
                              TextButton(child: const Text('No'), onPressed: () => Navigator.of(dialogContext).pop(false)),
                              TextButton(child: const Text('Yes, Cancel'), onPressed: () => Navigator.of(dialogContext).pop(true)),
                            ],
                          ),
                        );
                        if (confirmCancel == true) {
                          await appState.cancelSubscription();
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription cancelled (simulated).')));
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    )
                  else if (canStartTrial)
                     ElevatedButton.icon(
                      icon: const Icon(Icons.star_border_purple500_rounded),
                      label: Text("Start ${kFreeTrialDuration.inDays}-Day Free Trial"),
                      onPressed: () async {
                        await appState.startFreeTrial();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Free Trial started!')));
                      },
                    ),
                ],
              ),
            )
          ),
          const Divider(height: 32, thickness: 1),

          // Subscription Plans Section
           Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Subscription Plans",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          if (kSubscriptionPlans.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("No subscription plans available currently."),
            )),
          ...kSubscriptionPlans.map((plan) {
            bool isActivePlan = currentUser?.activeSubscriptionId == plan.id;
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isActivePlan ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  width: 2
                )
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(plan.description, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text("Benefits:", style: Theme.of(context).textTheme.titleSmall),
                    ...plan.benefits.map((benefit) => Text("• ${benefit.name.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}').trim()}", style: Theme.of(context).textTheme.bodySmall)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${plan.priceUSD.toStringAsFixed(2)} / ${plan.duration.inDays ~/ 30} month(s)', //粗略显示
                           style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: isActivePlan || (currentUser?.activeSubscriptionId != null && currentUser?.activeSubscriptionId != plan.id) // Disable if current plan or another plan is active
                              ? null
                              : () async {
                                  await appState.subscribeToPlan(plan);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Subscribed to ${plan.name}! (Simulated)')));
                                },
                          child: Text(isActivePlan ? "Current Plan" : "Subscribe"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

          const Divider(height: 32, thickness: 1, indent: 16, endIndent: 16),

          // Section for Microtransaction Products
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Store - Get Extras",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          if (kMicrotransactionProducts.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("No items available in the store currently."),
            )),
          ...kMicrotransactionProducts.map((product) {
            return _ProductCard(
              product: product,
              onPurchase: () => _handlePurchase(context, appState, product),
            );
          }).toList(),

          const Divider(height: 32, thickness: 1, indent: 16, endIndent: 16),

          // Existing Premium Features Section (can be kept or moved)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Premium Features Overview",
               style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
               textAlign: TextAlign.center,
            ),
          ),
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

// Widget to display a single microtransaction product
class _ProductCard extends StatelessWidget {
  final MicrotransactionProduct product;
  final VoidCallback onPurchase;

  const _ProductCard({required this.product, required this.onPurchase});

  IconData _getProductIcon(ProductType type) {
    switch (type) {
      case ProductType.coins:
        return Icons.monetization_on_rounded;
      case ProductType.treeSkin:
        return Icons.forest_rounded;
      case ProductType.featureUnlock:
        return Icons.lock_open_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getProductIcon(product.type), size: 30, color: theme.colorScheme.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(product.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(product.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${product.priceUSD.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_cart_checkout_rounded),
                  label: const Text('Purchase'),
                  onPressed: onPurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Existing _FeatureCard widget (can be kept as is)

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
