import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:ziberlive/providers/app_state_provider.dart';
import 'package:ziberlive/config.dart'; // For kIncomePoolGoals
import 'dart:math'; // For confetti

class IncomePoolScreen extends StatefulWidget {
  const IncomePoolScreen({super.key});

  @override
  State<IncomePoolScreen> createState() => _IncomePoolScreenState();
}

class _IncomePoolScreenState extends State<IncomePoolScreen> {
  final _contributionController = TextEditingController();
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _contributionController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _handleContribute(AppStateProvider appState) async {
    final pointsText = _contributionController.text;
    if (pointsText.isEmpty) {
      _showErrorMessage("Please enter points to contribute.");
      return;
    }
    final points = int.tryParse(pointsText);
    if (points == null || points <= 0) {
      _showErrorMessage("Please enter a valid positive number of points.");
      return;
    }

    bool success = await appState.contributeToIncomePool(points);
    if (success) {
      _showSuccessMessage("Successfully contributed $points points to the Income Pool!");
      _contributionController.clear();
      FocusScope.of(context).unfocus(); // Dismiss keyboard
    } else {
      // AppStateProvider likely printed a more specific error
      _showErrorMessage("Contribution failed. Check your available points.");
    }
  }

  Future<void> _handleRedeemGoal(AppStateProvider appState, IncomePoolGoal goal) async {
    bool success = await appState.redeemIncomePoolGoal(goal);
    if (success) {
      _confettiController.play();
      _showSuccessMessage("Goal '${goal.description}' redeemed successfully!");
    } else {
      _showErrorMessage("Failed to redeem goal. Not enough points or not an admin.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final currentUser = appState.currentUser;
    final userIncomePoolPoints = currentUser?.incomePoolPoints ?? 0;
    final totalPoolPoints = appState.totalRoomIncomePoolPoints; // This is the persisted global pool

    // Determine the next goal for progress bar
    IncomePoolGoal? nextGoalForProgress;
    List<IncomePoolGoal> sortedGoals = List.from(kIncomePoolGoals)..sort((a,b) => a.pointsRequired.compareTo(b.pointsRequired));
    for (final goal in sortedGoals) {
      if (totalPoolPoints < goal.pointsRequired) {
        nextGoalForProgress = goal;
        break;
      }
    }

    double progressPercentage = 0.0;
    String progressLabel = "All goals achieved or no goals defined!";
    if (nextGoalForProgress != null) {
      progressPercentage = totalPoolPoints / nextGoalForProgress.pointsRequired;
      progressLabel = "$totalPoolPoints / ${nextGoalForProgress.pointsRequired} towards ${nextGoalForProgress.description}";
    } else if (sortedGoals.isNotEmpty && totalPoolPoints >= sortedGoals.last.pointsRequired) {
      progressPercentage = 1.0;
      progressLabel = "Highest goal achieved! Current Pool: $totalPoolPoints points";
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Income Pool Collaboration'),
        centerTitle: true,
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView( // To prevent overflow if content is too long
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User's contribution points
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Your Income Pool Points:',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$userIncomePoolPoints',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contribution section
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text('Contribute to the Pool', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _contributionController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              labelText: 'Points to contribute',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.add_circle_outline),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => _handleContribute(appState),
                            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
                            child: const Text('Contribute Points'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Total Room Pool Points and Progress
                  Text('Total Room Income Pool: $totalPoolPoints points', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  if (sortedGoals.isNotEmpty) ...[
                    Text(progressLabel, style: Theme.of(context).textTheme.titleSmall, textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: LinearProgressIndicator(
                        value: progressPercentage.isNaN || progressPercentage.isInfinite
                               ? 0.0
                               : progressPercentage.clamp(0.0, 1.0),
                        minHeight: 12,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrangeAccent),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Collective Goals
                  Text('Collective Reward Goals', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                  const Divider(height: 20, thickness: 1),
                  if (sortedGoals.isEmpty)
                    const Center(child: Text("No collective goals defined yet.")),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedGoals.length,
                    itemBuilder: (context, index) {
                      final goal = sortedGoals[index];
                      final canRedeem = totalPoolPoints >= goal.pointsRequired && (currentUser?.isAdmin ?? false);
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading: Icon(_getGoalIcon(goal.rewardType), color: Theme.of(context).colorScheme.secondary, size: 40),
                          title: Text(goal.description, style: Theme.of(context).textTheme.titleMedium),
                          subtitle: Text('Requires: ${goal.pointsRequired} Pool Points\nReward: ${goal.rewardValue} (${goal.rewardType.name})'),
                          isThreeLine: true,
                          trailing: ElevatedButton(
                            onPressed: canRedeem ? () => _handleRedeemGoal(appState, goal) : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canRedeem ? Theme.of(context).colorScheme.secondary : Colors.grey,
                            ),
                            child: const Text('Redeem Goal', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Confetti for goal redemption
          Align(
            alignment: Alignment.center, // Centered for group celebration
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 50, // More particles for group achievement
              gravity: 0.2,
              emissionFrequency: 0.03,
              maxBlastForce: 30,
              minBlastForce: 10,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple, Colors.yellow],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getGoalIcon(IncomePoolRewardType type) {
    switch (type) {
      case IncomePoolRewardType.payPal:
        return Icons.paypal_rounded;
      case IncomePoolRewardType.amazonCoupon:
        return Icons.shopping_cart_checkout_rounded;
      case IncomePoolRewardType.other:
      default:
        return Icons.star_rounded;
    }
  }
}
