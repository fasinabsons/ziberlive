import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart'; // Placeholder for confetti animation
import 'package:ziberlive/providers/app_state_provider.dart';
import 'package:ziberlive/config.dart'; // For kAmazonCouponTiers
import 'dart:math'; // For confetti controller

class AmazonCouponsScreen extends StatefulWidget {
  const AmazonCouponsScreen({super.key});

  @override
  State<AmazonCouponsScreen> createState() => _AmazonCouponsScreenState();
}

class _AmazonCouponsScreenState extends State<AmazonCouponsScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _showRedemptionSuccess(AmazonCouponTier tier) {
    _confettiController.play();
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
    final currentPoints = currentUser?.amazonCouponPoints ?? 0;

    // Determine the next tier for progress bar
    AmazonCouponTier? nextTierForProgress;
    kAmazonCouponTiers.sort((a, b) => a.pointsRequired.compareTo(b.pointsRequired)); // Ensure sorted by points
    for (final tier in kAmazonCouponTiers) {
      if (currentPoints < tier.pointsRequired) {
        nextTierForProgress = tier;
        break;
      }
    }
    // If all tiers are achieved, progress can be shown for the highest tier or just 100%
    double progressPercentage = 0.0;
    String progressLabel = "All coupons achieved!";
    if (nextTierForProgress != null) {
      progressPercentage = currentPoints / nextTierForProgress.pointsRequired;
      progressLabel = "$currentPoints / ${nextTierForProgress.pointsRequired} points towards ${nextTierForProgress.description}";
    } else if (kAmazonCouponTiers.isNotEmpty && currentPoints >= kAmazonCouponTiers.last.pointsRequired) {
      progressPercentage = 1.0; // Achieved highest tier
      progressLabel = "You've achieved the highest coupon tier!";
    } else if (kAmazonCouponTiers.isEmpty){
      progressLabel = "No coupon tiers available.";
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Amazon Coupons'),
        centerTitle: true,
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Padding(
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
                          'Your Amazon Coupon Points:',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$currentPoints',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
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
                if (kAmazonCouponTiers.isNotEmpty) ...[
                  Text(progressLabel, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progressPercentage.isNaN || progressPercentage.isInfinite
                           ? 0.0
                           : progressPercentage.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 20),
                ],

                // List of Coupon Tiers
                Expanded(
                  child: ListView.builder(
                    itemCount: kAmazonCouponTiers.length,
                    itemBuilder: (context, index) {
                      final tier = kAmazonCouponTiers[index];
                      final canRedeem = currentPoints >= tier.pointsRequired;
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading: Icon(Icons.card_giftcard, color: Theme.of(context).colorScheme.primary, size: 40),
                          title: Text(tier.description, style: Theme.of(context).textTheme.titleMedium),
                          subtitle: Text('${tier.pointsRequired} Points'),
                          trailing: ElevatedButton(
                            onPressed: canRedeem
                                ? () async {
                                    bool success = await appState.redeemAmazonCoupon(tier);
                                    if (success) {
                                      _showRedemptionSuccess(tier);
                                    } else {
                                      // AppStateProvider already prints error, but can show generic message
                                      _showRedemptionFailure('Redemption failed. Not enough points or server error.');
                                    }
                                  }
                                : null, // Button disabled if not enough points
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canRedeem ? Theme.of(context).colorScheme.primary : Colors.grey,
                            ),
                            child: const Text('Redeem', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 20,
              gravity: 0.3,
              emissionFrequency: 0.05,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }
}
