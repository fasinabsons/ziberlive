import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ziberlive/providers/app_state_provider.dart';
import 'package:ziberlive/widgets/custom_widget.dart';
import 'package:ziberlive/models/app_models.dart';
import 'package:ziberlive/widgets/community_tree_widget.dart';
import 'package:ziberlive/config.dart'; // For kPointsPerCommunityTreeVisualLevel
import 'package:ziberlive/screens/premium_features_screen.dart'; // For navigation to premium screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showPromotionBanner = true; // To control visibility of the dismissible banner

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final theme = Theme.of(context); // Get theme for styling

    if (appState.isLoading) {
      return const _LoadingScreen();
    }

    // Decide if promotion banner should be shown based on premium status and dismiss state
    final bool shouldDisplayPromo = !appState.isPremium && _showPromotionBanner;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CoLivify'),
        centerTitle: true,
        actions: [
          if (appState.isSyncing)
            const _SyncingIndicator()
          else
            IconButton(
              icon: const Icon(Icons.sync_rounded),
              onPressed: () => appState.startSync(),
              tooltip: 'Sync data',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => appState.refreshData(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Promotional Banner (Dismissible)
            if (shouldDisplayPromo)
              Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                color: theme.colorScheme.primaryContainer.withOpacity(0.95),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Icon(Icons.star_purple500_outlined, color: theme.colorScheme.onPrimaryContainer, size: 36),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Unlock Premium Features!",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Go Ad-Free, get Cloud Backup & more benefits.",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8)
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PremiumFeaturesScreen()));
                        },
                        child: Text("View Offers", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 20, color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7)),
                        onPressed: () {
                          setState(() {
                            _showPromotionBanner = false;
                          });
                        },
                        tooltip: "Dismiss",
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0, curve: Curves.easeOutCubic, duration: 400.ms),

            // Welcome Message
            Text(
              'Hello, ${appState.currentUser?.name ?? 'User'}! 👋',
              style: Theme.of(context).textTheme.headlineSmall,
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 8),

            Text(
              'Here\'s what\'s happening in your co-living space:',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7), // Corrected withOpacity
                  ),
            ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

            const SizedBox(height: 24),

            // Action buttons
            _ActionButtonsRow(
              onSyncPressed: () => appState.startSync(),
            ),

            const SizedBox(height: 24),

            // Community Tree Preview
            _CommunityTreePreview(
              totalCommunityPoints: appState.totalCommunityTreePoints,
              currentTreeGrowthFactor: appState.treeLevel,
            ),

            const SizedBox(height: 16),

            // Bill Summary Card
            _BillSummaryCard(
              unpaidBills: appState.unpaidBills,
              onPayBill: (billId) => appState.payBill(billId),
            ),

            const SizedBox(height: 16),

            // Tasks Preview Card
            _TaskPreviewCard(
              tasks: appState.userTasks,
              onCompleteTask: (taskId) => appState.completeTask(taskId),
            ),

            const SizedBox(height: 16),

            // Recent Votes Preview
            _VotePreviewCard(
              votes: appState.openVotes,
            ),

            const SizedBox(height: 16),

            // Credits Preview
            _CreditsPreviewCard(
              credits: appState.currentUser?.credits ?? 0,
            ),
          ],
        ),
      ),
    );
  }
}

// _LoadingScreen, _SyncingIndicator, _ActionButtonsRow, _ActionButton,
// _CommunityTreePreview, _BillSummaryCard, _TaskPreviewCard, _VotePreviewCard, _CreditsPreviewCard
// and their helper methods like _getBillIcon, _getBillColor remain the same as before.
// (Assuming these widgets were part of the original home_screen.dart content that was not shown but is expected to be there)

// Re-defining these widgets as they were in the original file (based on previous tool outputs for home_screen.dart)

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ).animate().scale(duration: 700.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              'Loading your co-living space...',
              style: Theme.of(context).textTheme.titleMedium,
            ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}

class _SyncingIndicator extends StatelessWidget {
  const _SyncingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Syncing...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtonsRow extends StatelessWidget {
  final VoidCallback onSyncPressed;

  const _ActionButtonsRow({required this.onSyncPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: Icons.receipt_long_rounded,
          label: 'Bills',
          color: theme.colorScheme.primary,
          onPressed: () {
            DefaultTabController.of(context).animateTo(1);
          },
        ),
        _ActionButton(
          icon: Icons.check_circle_outline_rounded,
          label: 'Tasks',
          color: theme.colorScheme.secondary,
          onPressed: () {
            DefaultTabController.of(context).animateTo(3);
          },
        ),
        _ActionButton(
          icon: Icons.how_to_vote_rounded,
          label: 'Vote',
          color: theme.colorScheme.tertiary,
          onPressed: () {
            DefaultTabController.of(context).animateTo(2);
          },
        ),
        _ActionButton(
          icon: Icons.sync_rounded,
          label: 'Sync',
          color: Colors.teal, // Keep consistent if this was the original color
          onPressed: onSyncPressed,
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.2, end: 0, duration: 500.ms);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), // Corrected withOpacity
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityTreePreview extends StatelessWidget {
  final int totalCommunityPoints;
  final double currentTreeGrowthFactor;

  const _CommunityTreePreview({
    required this.totalCommunityPoints,
    required this.currentTreeGrowthFactor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double visualLevelForWidget = 1.0 + (totalCommunityPoints / kPointsPerCommunityTreeVisualLevel);
    if (kPointsPerCommunityTreeVisualLevel == 0 && totalCommunityPoints > 0) visualLevelForWidget = 3.0; // Max out if no points per level but has points
    else if (kPointsPerCommunityTreeVisualLevel == 0) visualLevelForWidget = 1.0;


    double progressWithinCurrentStage = 0.0;
    if (kPointsPerCommunityTreeVisualLevel > 0) {
      progressWithinCurrentStage = (totalCommunityPoints % kPointsPerCommunityTreeVisualLevel) / kPointsPerCommunityTreeVisualLevel;
    } else if (totalCommunityPoints > 0) {
        progressWithinCurrentStage = 1.0;
    }


    return CustomCard(
      title: 'Community Tree ($totalCommunityPoints pts)',
      titleIcon: Icons.nature_people_rounded,
      actions: [
        TextButton(
          onPressed: () {
            DefaultTabController.of(context).animateTo(2); // Assuming CommunityScreen is tab 2
          },
          child: Text(
            'Details',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
      ],
      child: Column(
        children: [
          Text(
            'Stage ${(visualLevelForWidget).floor().clamp(1, double.infinity)}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Earn points by watching ads and contributing to the community! Total Points: $totalCommunityPoints',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7), // Corrected withOpacity
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: CommunityTreeWidget(
                  treeLevel: visualLevelForWidget,
                  height: 150,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LabeledProgressIndicator(
            value: progressWithinCurrentStage.clamp(0.0, 1.0),
            label: 'Progress to next visual stage',
            progressColor: theme.colorScheme.secondary,
          ),
        ],
      ),
    );
  }
}

class _BillSummaryCard extends StatelessWidget {
  final List<Bill> unpaidBills;
  final Function(String) onPayBill;

  const _BillSummaryCard({
    required this.unpaidBills,
    required this.onPayBill,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      title: 'Unpaid Bills',
      titleIcon: Icons.receipt_long_rounded,
      actions: [
        TextButton(
          onPressed: () {
            DefaultTabController.of(context).animateTo(1); // Assuming BillsScreen is tab 1
          },
          child: Text(
            'View All',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (unpaidBills.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: theme.colorScheme.secondary,
                      size: 48,
                    )
                        .animate()
                        .scale(duration: 700.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 16),
                    Text(
                      'All caught up!',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You have no pending bills to pay',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: unpaidBills.length > 2 ? 2 : unpaidBills.length,
              itemBuilder: (context, index) {
                final bill = unpaidBills[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getBillColor(bill.type, theme)
                              .withOpacity(0.1), // Corrected withOpacity
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getBillIcon(bill.type),
                          color: _getBillColor(bill.type, theme),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bill.title,
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              'Due: ${bill.getFormattedDueDate()}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: bill.isOverdue()
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurface
                                        .withOpacity(0.7), // Corrected withOpacity
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${bill.getAmountPerUser().toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: bill.isOverdue()
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => onPayBill(bill.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Pay'),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.05, end: 0, duration: 300.ms);
              },
            ),
          if (unpaidBills.length > 2) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  DefaultTabController.of(context).animateTo(1); // Assuming BillsScreen is tab 1
                },
                child: Text(
                  'View ${unpaidBills.length - 2} more bills',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getBillIcon(BillType type) {
    switch (type) {
      case BillType.rent: return Icons.home_rounded;
      case BillType.utility: return Icons.bolt_rounded;
      case BillType.communityMeals: return Icons.restaurant_rounded;
      case BillType.drinkingWater: return Icons.water_drop_rounded;
      case BillType.groceries: return Icons.shopping_cart_rounded;
      default: return Icons.receipt_rounded;
    }
  }

  Color _getBillColor(BillType type, ThemeData theme) {
    switch (type) {
      case BillType.rent: return theme.colorScheme.primary;
      case BillType.utility: return Colors.amber;
      case BillType.communityMeals: return theme.colorScheme.tertiary;
      case BillType.drinkingWater: return theme.colorScheme.secondary;
      case BillType.groceries: return Colors.green;
      default: return Colors.grey;
    }
  }
}

class _TaskPreviewCard extends StatelessWidget {
  final List<Task> tasks;
  final Function(String) onCompleteTask;

  const _TaskPreviewCard({
    required this.tasks,
    required this.onCompleteTask,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final incompleteTasks = tasks.where((task) => !task.isCompleted).toList();

    return CustomCard(
      title: 'Your Tasks',
      titleIcon: Icons.check_circle_outline_rounded,
      actions: [
        TextButton(
          onPressed: () {
            DefaultTabController.of(context).animateTo(3); // Assuming TaskScreen is tab 3
          },
          child: Text(
            'View All',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (incompleteTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.task_alt_rounded,
                      color: theme.colorScheme.secondary,
                      size: 48,
                    ).animate().scale(duration: 700.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 16),
                    Text('All done!', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('You have no pending tasks', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: incompleteTasks.length > 2 ? 2 : incompleteTasks.length,
              itemBuilder: (context, index) {
                final task = incompleteTasks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withOpacity(0.1), // Corrected withOpacity
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.check_circle_outline_rounded, color: theme.colorScheme.secondary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task.title, style: theme.textTheme.titleSmall),
                            Text(
                              'Due: ${task.getFormattedDueDate()}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: task.isOverdue() ? theme.colorScheme.error : theme.colorScheme.onSurface.withOpacity(0.7), // Corrected withOpacity
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          StatusBadge(text: '+${task.creditReward} credits', color: theme.colorScheme.tertiary),
                          const SizedBox(height: 4),
                          ElevatedButton(
                            onPressed: () => onCompleteTask(task.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: theme.colorScheme.onSecondary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Complete'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0, duration: 300.ms);
              },
            ),
          if (incompleteTasks.length > 2) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  DefaultTabController.of(context).animateTo(3); // Assuming TaskScreen is tab 3
                },
                child: Text('View ${incompleteTasks.length - 2} more tasks', style: TextStyle(color: theme.colorScheme.primary)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VotePreviewCard extends StatelessWidget {
  final List<Vote> votes;

  const _VotePreviewCard({required this.votes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      title: 'Active Polls',
      titleIcon: Icons.how_to_vote_rounded,
      actions: [
        TextButton(
          onPressed: () {
             DefaultTabController.of(context).animateTo(2); // Assuming CommunityScreen (where votes might be) is tab 2
          },
          child: Text('Vote Now', style: TextStyle(color: theme.colorScheme.primary)),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (votes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.how_to_vote_rounded, color: theme.colorScheme.tertiary, size: 48).animate().scale(duration: 700.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 16),
                    Text('No active polls', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.tertiary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Check back later for community polls', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: votes.length > 1 ? 1 : votes.length, // Show max 1 preview
              itemBuilder: (context, index) {
                final vote = votes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiary.withOpacity(0.1), // Corrected withOpacity
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.how_to_vote_rounded, color: theme.colorScheme.tertiary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(vote.title, style: theme.textTheme.titleSmall),
                                Text(
                                  'Ends: ${vote.getFormattedEndDate()}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)), // Corrected withOpacity
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(text: '${vote.getTotalVotes()} votes', color: theme.colorScheme.tertiary),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(vote.description, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          DefaultTabController.of(context).animateTo(2); // Assuming CommunityScreen is tab 2
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.tertiary,
                          foregroundColor: theme.colorScheme.onTertiary,
                          minimumSize: const Size(double.infinity, 40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Vote Now'),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0, duration: 300.ms);
              },
            ),
          if (votes.length > 1) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  DefaultTabController.of(context).animateTo(2); // Assuming CommunityScreen is tab 2
                },
                child: Text('View ${votes.length - 1} more polls', style: TextStyle(color: theme.colorScheme.primary)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreditsPreviewCard extends StatelessWidget {
  final int credits;

  const _CreditsPreviewCard({required this.credits});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      title: 'Co-Living Credits',
      titleIcon: Icons.stars_rounded,
      actions: [
        TextButton(
          onPressed: () {
             DefaultTabController.of(context).animateTo(2); // Assuming CommunityScreen or a rewards screen might be tab 2
          },
          child: Text('Leaderboard', style: TextStyle(color: theme.colorScheme.primary)),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withOpacity(0.1), // Corrected withOpacity
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.stars_rounded, color: theme.colorScheme.tertiary, size: 40),
              ).animate().scale(duration: 700.ms, curve: Curves.elasticOut),
              const SizedBox(width: 16),
              Text(
                '$credits',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.1, end: 0),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Earn credits by paying bills, completing tasks, and voting in polls. Redeem credits for community perks!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CreditItem(icon: Icons.receipt_long_rounded, label: 'Pay Bills', value: '+10', color: theme.colorScheme.primary),
              _CreditItem(icon: Icons.check_circle_outline_rounded, label: 'Complete Tasks', value: '+15', color: theme.colorScheme.secondary),
              _CreditItem(icon: Icons.how_to_vote_rounded, label: 'Vote', value: '+5', color: theme.colorScheme.tertiary),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreditItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _CreditItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), // Corrected withOpacity
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

// Ensure CustomCard, LabeledProgressIndicator, StatusBadge are defined elsewhere or were part of the original code.
// For this tool, I'm assuming they exist. If not, they would need to be created or stubbed.
// Example stubs if they weren't part of original and are needed for compilation:
// class CustomCard extends StatelessWidget {
//   final String title;
//   final IconData titleIcon;
//   final List<Widget>? actions;
//   final Widget child;
//   const CustomCard({super.key, required this.title, required this.titleIcon, this.actions, required this.child});
//   @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(8.0), child: Column(children: [Text(title), child])));}
// class LabeledProgressIndicator extends StatelessWidget {
//   final double value;
//   final String label;
//   final Color progressColor;
//   const LabeledProgressIndicator({super.key, required this.value, required this.label, required this.progressColor});
//   @override Widget build(BuildContext context) => Column(children: [Text(label), LinearProgressIndicator(value: value, color: progressColor)]);
// }
// class StatusBadge extends StatelessWidget {
//   final String text;
//   final Color color;
//   const StatusBadge({super.key, required this.text, required this.color});
//   @override Widget build(BuildContext context) => Chip(label: Text(text), backgroundColor: color.withOpacity(0.2));
// }
