import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ziberlive/providers/app_state_provider.dart';
import 'package:ziberlive/config.dart'; // For kPayPalCashTiers

class PayPalRewardsScreen extends StatefulWidget {
  const PayPalRewardsScreen({super.key});

  @override
  State<PayPalRewardsScreen> createState() => _PayPalRewardsScreenState();
}

class _PayPalRewardsScreenState extends State<PayPalRewardsScreen> with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void _playRedemptionAnimation() {
    _animationController?.reset();
    _animationController?.forward();
  }

  void _showRedemptionSuccess(PayPalCashTier tier) {
    _playRedemptionAnimation();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully redeemed ${tier.description}!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showRedemptionFailure(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final currentUser = appState.currentUser;
    final currentPoints = currentUser?.payPalPoints ?? 0;

    // Determine the next tier for progress bar
    PayPalCashTier? nextTierForProgress;
    // Ensure tiers are sorted by pointsRequired for correct progress calculation
    List<PayPalCashTier> sortedTiers = List.from(kPayPalCashTiers)..sort((a, b) => a.pointsRequired.compareTo(b.pointsRequired));

    for (final tier in sortedTiers) {
      if (currentPoints < tier.pointsRequired) {
        nextTierForProgress = tier;
        break;
      }
    }

    double progressPercentage = 0.0;
    String progressLabel = "All rewards achieved!";
    if (nextTierForProgress != null) {
      progressPercentage = currentPoints / nextTierForProgress.pointsRequired;
      progressLabel = "$currentPoints / ${nextTierForProgress.pointsRequired} points towards ${nextTierForProgress.description}";
    } else if (sortedTiers.isNotEmpty && currentPoints >= sortedTiers.last.pointsRequired) {
      progressPercentage = 1.0; // Achieved highest tier
      progressLabel = "You've achieved the highest PayPal reward tier!";
    } else if (sortedTiers.isEmpty) {
      progressLabel = "No PayPal reward tiers available.";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PayPal Rewards'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Display current points
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Your PayPal Points:',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ScaleTransition(
                      scale: _scaleAnimation ?? const AlwaysStoppedAnimation(1.0),
                      child: Icon(Icons.paypal, size: 40, color: Colors.blue[800]),
                    ),
                    Text(
                      '$currentPoints',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: Colors.blue[800], // PayPal blue
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Progress Bar for next tier
            if (sortedTiers.isNotEmpty) ...[
              Text(progressLabel, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progressPercentage.isNaN || progressPercentage.isInfinite
                       ? 0.0
                       : progressPercentage.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[800]!), // PayPal blue
              ),
              const SizedBox(height: 20),
            ],

            // List of PayPal Tiers
            Expanded(
              child: ListView.builder(
                itemCount: sortedTiers.length,
                itemBuilder: (context, index) {
                  final tier = sortedTiers[index];
                  final canRedeem = currentPoints >= tier.pointsRequired;
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Icon(Icons.monetization_on, color: Colors.green[700], size: 40),
                      title: Text(tier.description, style: Theme.of(context).textTheme.titleMedium),
                      subtitle: Text('${tier.pointsRequired} Points'),
                      trailing: ElevatedButton(
                        onPressed: canRedeem
                            ? () async {
                                bool success = await appState.redeemPayPalCash(tier);
                                if (success) {
                                  _showRedemptionSuccess(tier);
                                } else {
                                  _showRedemptionFailure('Redemption failed. Not enough points or server error.');
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canRedeem ? Colors.blue[700] : Colors.grey,
                        ),
                        child: const Text('Redeem Cash', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
