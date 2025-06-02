import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_state_provider.dart';
import '../models/app_models.dart';
import '../widgets/custom_widget.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:ziberlive/widgets/community_tree_widget.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tree'),
            Tab(text: 'Credits'),
            Tab(text: 'Voting'),
          ],
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CommunityTreeTab(),
          _CreditsTab(),
          _VotingTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton(
              onPressed: () => _showCreateVoteDialog(context),
              backgroundColor: theme.colorScheme.tertiary,
              foregroundColor: theme.colorScheme.onTertiary,
              heroTag: 'community_add_vote',
              child: const Icon(Icons.add_rounded),
            ).animate().scale(duration: 300.ms, curve: Curves.easeOut)
          : null,
    );
  }
  
  void _showCreateVoteDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => const _CreateVoteForm(),
      ),
    );
  }
}

class _CommunityTreeTab extends StatelessWidget {
  const _CommunityTreeTab();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    
    return RefreshIndicator(
      onRefresh: () => appState.refreshData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TreeLevelCard(
            treeLevel: appState.treeLevel,
          ),
          
          const SizedBox(height: 16),
          
          _CommunityTreeInfoCard(),
          
          const SizedBox(height: 16),
          
          _TreeActionCard(),
        ],
      ),
    );
  }
}

class _TreeLevelCard extends StatelessWidget {
  final double treeLevel;
  
  const _TreeLevelCard({required this.treeLevel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return CustomCard(
      title: 'Community Tree',
      titleIcon: Icons.nature_people_rounded,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Level ${treeLevel.toStringAsFixed(1)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Next level: ${treeLevel.floor() + 1}.0',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 120,
                    child: LabeledProgressIndicator(
                      value: treeLevel % 1,
                      label: 'Progress',
                      progressColor: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              _AnimatedCommunityTree(
                treeLevel: treeLevel,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Your community tree grows together with your co-living space. Pay bills on time, complete tasks, and participate in votes to make it flourish!',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.share_rounded),
            label: const Text('Share Tree Progress'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedCommunityTree extends StatelessWidget {
  final double treeLevel;
  
  const _AnimatedCommunityTree({required this.treeLevel});

  @override
  Widget build(BuildContext context) {
    return CommunityTreeWidget(
      treeLevel: treeLevel,
      height: 180,
    );
  }
}

class _CommunityTreeInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return CustomCard(
      title: 'How to Grow Your Tree',
      titleIcon: Icons.eco_rounded,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'Your community tree grows when all members contribute to the co-living space.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          const _TreeGrowthItem(
            icon: Icons.receipt_long_rounded,
            title: 'Pay Bills On Time',
            description: 'Each bill payment grows the tree by 5%',
            iconColor: Colors.amber,
          ),
          const Divider(),
          const _TreeGrowthItem(
            icon: Icons.check_circle_outline_rounded,
            title: 'Complete Tasks',
            description: 'Each task completion grows the tree by 10%',
            iconColor: Colors.teal,
          ),
          const Divider(),
          const _TreeGrowthItem(
            icon: Icons.how_to_vote_rounded,
            title: 'Participate in Votes',
            description: 'Each vote grows the tree by 2%',
            iconColor: Colors.purple,
          ),
          const Divider(),
          const _TreeGrowthItem(
            icon: Icons.sync_rounded,
            title: 'Sync Data with Others',
            description: 'Each sync session grows the tree by 1%',
            iconColor: Colors.blue,
          ),
        ],
      ),
    );
  }
}

class _TreeGrowthItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;
  
  const _TreeGrowthItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TreeActionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppStateProvider>(context);
    
    return CustomCard(
      title: 'Quick Actions',
      titleIcon: Icons.bolt_rounded,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'Take these actions to help your community tree grow:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.receipt_long_rounded,
                label: 'Pay Bills',
                color: theme.colorScheme.primary,
                onPressed: () {
                  DefaultTabController.of(context).animateTo(1);
                },
              ),
              _ActionButton(
                icon: Icons.check_circle_outline_rounded,
                label: 'Do Tasks',
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
                  // Access tabController from the state class
                  (context.findAncestorStateOfType<_CommunityScreenState>() as _CommunityScreenState)
                      ._tabController.animateTo(2);
                },
              ),
              _ActionButton(
                icon: Icons.sync_rounded,
                label: 'Sync',
                color: Colors.blue,
                onPressed: () {
                  appState.startSync();
                },
              ),
            ],
          ),
        ],
      ),
    );
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 500.ms, curve: Curves.easeOut);
  }
}

class _CreditsTab extends StatelessWidget {
  const _CreditsTab();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    
    return RefreshIndicator(
      onRefresh: () => appState.refreshData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CreditsSummaryCard(
            credits: appState.currentUser?.credits ?? 0,
          ),
          
          const SizedBox(height: 16),
          
          _LeaderboardCard(
            users: appState.users,
          ),
          
          const SizedBox(height: 16),
          
          _CreditsInfoCard(),
        ],
      ),
    );
  }
}

class _CreditsSummaryCard extends StatelessWidget {
  final int credits;
  
  const _CreditsSummaryCard({required this.credits});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return CustomCard(
      title: 'Your Co-Living Credits',
      titleIcon: Icons.stars_rounded,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.tertiary.withValues(alpha: 0.5),
                      theme.colorScheme.tertiary.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.tertiary.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stars_rounded,
                        color: theme.colorScheme.tertiary,
                        size: 32,
                      ),
                      Text(
                        credits.toString(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.tertiary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'CREDITS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().scale(duration: 700.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(
            'Co-Living Credits can be earned by contributing to your community and redeemed for benefits.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pay Bills',
                    style: theme.textTheme.labelMedium,
                  ),
                  Text(
                    '+10 credits',
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                ],
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      color: theme.colorScheme.secondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete Tasks',
                    style: theme.textTheme.labelMedium,
                  ),
                  Text(
                    '+15 credits',
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                  ),
                ],
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.how_to_vote_rounded,
                      color: theme.colorScheme.tertiary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vote in Polls',
                    style: theme.textTheme.labelMedium,
                  ),
                  Text(
                    '+5 credits',
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.tertiary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final List<User> users;
  
  const _LeaderboardCard({required this.users});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppStateProvider>(context);
    
    // Sort users by credits in descending order
    final sortedUsers = List<User>.from(users);
    sortedUsers.sort((a, b) => b.credits.compareTo(a.credits));
    
    return CustomCard(
      title: 'Credits Leaderboard',
      titleIcon: Icons.leaderboard_rounded,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'See who\'s contributing the most to your co-living community!',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          
          // Top 3 with special styling
          if (sortedUsers.length >= 3)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _LeaderboardPosition(
                    user: sortedUsers[1],
                    position: 2,
                    isCurrentUser: sortedUsers[1].id == appState.currentUser?.id,
                  ),
                  _LeaderboardPosition(
                    user: sortedUsers[0],
                    position: 1,
                    isCurrentUser: sortedUsers[0].id == appState.currentUser?.id,
                  ),
                  _LeaderboardPosition(
                    user: sortedUsers[2],
                    position: 3,
                    isCurrentUser: sortedUsers[2].id == appState.currentUser?.id,
                  ),
                ],
              ),
            ),
            
          // Rest of the leaderboard
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedUsers.length > 3 ? sortedUsers.length - 3 : 0,
            itemBuilder: (context, index) {
              final position = index + 4; // Start from position 4
              final user = sortedUsers[index + 3]; // Skip the first 3 users
              final isCurrentUser = user.id == appState.currentUser?.id;
              
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: isCurrentUser
                    ? BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCurrentUser
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          position.toString(),
                          style: TextStyle(
                            color: isCurrentUser
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          color: isCurrentUser
                              ? theme.colorScheme.primary
                              : theme.colorScheme.tertiary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.credits.toString(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isCurrentUser
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LeaderboardPosition extends StatelessWidget {
  final User user;
  final int position;
  final bool isCurrentUser;
  
  const _LeaderboardPosition({
    required this.user,
    required this.position,
    required this.isCurrentUser,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color positionColor;
    IconData crownIcon;
    double size;
    
    switch (position) {
      case 1:
        positionColor = Colors.amber;
        crownIcon = Icons.emoji_events_rounded;
        size = 100;
        break;
      case 2:
        positionColor = Colors.grey.shade400;
        crownIcon = Icons.emoji_events_rounded;
        size = 80;
        break;
      case 3:
        positionColor = Colors.brown.shade300;
        crownIcon = Icons.emoji_events_rounded;
        size = 80;
        break;
      default:
        positionColor = theme.colorScheme.outline.withValues(alpha: 0.7);
        crownIcon = Icons.emoji_events_rounded;
        size = 80;
    }
    
    return Column(
      children: [
        if (position == 1) 
          Icon(
            crownIcon,
            color: positionColor,
            size: 32,
          ).animate().scale(delay: 300.ms, duration: 700.ms, curve: Curves.elasticOut),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              width: size,
              height: size,
              margin: EdgeInsets.only(top: position == 1 ? 0 : 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrentUser
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : theme.colorScheme.surface,
                border: Border.all(
                  color: isCurrentUser
                      ? theme.colorScheme.primary
                      : positionColor,
                  width: position == 1 ? 3 : 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  UserAvatar(
                    name: user.name,
                    size: position == 1 ? 50 : 40,
                    backgroundColor: isCurrentUser
                        ? theme.colorScheme.primary
                        : positionColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.name.split(' ').first,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stars_rounded,
                        color: positionColor,
                        size: 16,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        user.credits.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: positionColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (position <= 3)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: positionColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#$position',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 800.ms).scale(duration: 500.ms);
  }
}

class _CreditsInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return CustomCard(
      title: 'Credits System',
      titleIcon: Icons.info_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Co-Living Credits are a way to reward members for contributing to the community.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          
          Text(
            'How to earn credits:',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const _CreditEarnItem(
            icon: Icons.receipt_long_rounded,
            title: 'Pay bills on time',
            description: 'Get rewarded for timely payments',
            credits: '+10',
          ),
          const _CreditEarnItem(
            icon: Icons.check_circle_outline_rounded,
            title: 'Complete assigned tasks',
            description: 'Each task has its own credit reward',
            credits: '+10~20',
          ),
          const _CreditEarnItem(
            icon: Icons.how_to_vote_rounded,
            title: 'Participate in community votes',
            description: 'Have your say in community decisions',
            credits: '+5',
          ),
          const _CreditEarnItem(
            icon: Icons.people_rounded,
            title: 'Invite new roommates',
            description: 'Help grow your community',
            credits: '+25',
          ),
          
          const SizedBox(height: 16),
          Text(
            'How to use credits:',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const _CreditUseItem(
            title: 'Priority in room selection',
            description: 'When new rooms become available',
            cost: '100 credits',
          ),
          const _CreditUseItem(
            title: 'Community meal discount',
            description: '10% off for a week of meals',
            cost: '50 credits',
          ),
          const _CreditUseItem(
            title: 'Skip a cleaning task',
            description: 'Someone else will cover for you',
            cost: '75 credits',
          ),
        ],
      ),
    );
  }
}

class _CreditEarnItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String credits;
  
  const _CreditEarnItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.credits,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.tertiary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        description,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          credits,
          style: TextStyle(
            color: theme.colorScheme.tertiary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _CreditUseItem extends StatelessWidget {
  final String title;
  final String description;
  final String cost;
  
  const _CreditUseItem({
    required this.title,
    required this.description,
    required this.cost,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        description,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          cost,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _VotingTab extends StatelessWidget {
  const _VotingTab();
  
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final theme = Theme.of(context);
    final currentUser = appState.currentUser;
    
    final votes = appState.votes;
    
    if (votes.isEmpty) {
      return EmptyStateView(
        icon: Icons.how_to_vote_rounded,
        message: 'No active polls',
        actionLabel: currentUser?.isAdmin ?? false ? 'Create Poll' : null,
        onActionPressed: currentUser?.isAdmin ?? false
            ? () {
                (context.findAncestorStateOfType<_CommunityScreenState>() as _CommunityScreenState)
                    ._showCreateVoteDialog(context);
              }
            : null,
      );
    }
    
    // Separate votes by active/closed
    final activeVotes = votes.where((v) => v.isVotingOpen()).toList();
    final closedVotes = votes.where((v) => !v.isVotingOpen()).toList();
    
    return RefreshIndicator(
      onRefresh: () => appState.refreshData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Voting allows everyone to have a say in community decisions.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          
          if (activeVotes.isNotEmpty) ...[            
            Row(
              children: [
                Icon(
                  Icons.how_to_vote_rounded,
                  color: theme.colorScheme.tertiary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Active Polls',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeVotes.length,
              itemBuilder: (context, index) {
                return _VoteCard(
                  vote: activeVotes[index],
                  isActive: true,
                );
              },
            ),
            const SizedBox(height: 24),
          ],
          
          if (closedVotes.isNotEmpty) ...[            
            Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Completed Polls',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: closedVotes.length,
              itemBuilder: (context, index) {
                return _VoteCard(
                  vote: closedVotes[index],
                  isActive: false,
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _VoteCard extends StatelessWidget {
  final Vote vote;
  final bool isActive;
  
  const _VoteCard({
    required this.vote,
    required this.isActive,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppStateProvider>(context);
    final currentUser = appState.currentUser;
    
    if (currentUser == null) return const SizedBox.shrink();
    
    // Check if the current user has voted
    final hasVoted = vote.userVotes.containsKey(currentUser.id);
    final selectedOptionId = hasVoted ? vote.userVotes[currentUser.id] : null;
    
    // Get winning option for closed votes
    final winningOption = !isActive ? vote.getWinningOption() : null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isActive
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.secondary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isActive ? Icons.how_to_vote_rounded : Icons.check_circle_rounded,
                    color: isActive ? theme.colorScheme.tertiary : theme.colorScheme.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vote.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isActive
                                ? 'Ends: ${vote.getFormattedEndDate()}'
                                : 'Ended: ${vote.getFormattedEndDate()}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  text: '${vote.getTotalVotes()} votes',
                  color: isActive ? theme.colorScheme.tertiary : theme.colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              vote.description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Options
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vote.options.length,
              itemBuilder: (context, index) {
                final option = vote.options[index];
                final isSelected = selectedOptionId == option.id;
                final isWinner = winningOption?.id == option.id;
                
                return VoteOptionItem(
                  optionText: option.text,
                  voteCount: option.count,
                  totalVotes: vote.getTotalVotes(),
                  isSelected: isSelected || isWinner,
                  onTap: isActive && !hasVoted
                      ? () => appState.castVote(vote.id, option.id)
                      : () {},
                );
              },
            ),
            
            if (isActive && !hasVoted) ...[              
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.tertiary,
                  foregroundColor: theme.colorScheme.onTertiary,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tap an option to vote'),
              ),
            ],
            
            if (isActive && hasVoted) ...[              
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'You\'ve voted! Thanks for participating.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            if (!isActive) ...[              
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.amber,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Winner: ${winningOption?.text ?? 'No votes cast'}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms);
  }
}

class _CreateVoteForm extends StatefulWidget {
  const _CreateVoteForm();

  @override
  State<_CreateVoteForm> createState() => _CreateVoteFormState();
}

class _CreateVoteFormState extends State<_CreateVoteForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));
  bool _isAnonymous = false;
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create New Poll',
                  style: theme.textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Poll Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Poll Title',
                hintText: 'e.g. Weekend Dinner Menu',
                prefixIcon: Icon(Icons.title_rounded, color: theme.colorScheme.tertiary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title for the poll';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Poll Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Provide more details about this poll',
                prefixIcon: Icon(Icons.description_rounded, color: theme.colorScheme.tertiary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // End Date
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: theme.colorScheme.tertiary),
                const SizedBox(width: 12),
                Text(
                  'Voting Ends: ${DateFormat.yMMMd().add_jm().format(_endDate)}',
                  style: theme.textTheme.titleSmall,
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
final pickedDate = await showDatePicker(
  context: context,
  initialDate: _endDate,
  firstDate: DateTime.now(),
  lastDate: DateTime.now().add(const Duration(days: 365)),
);

if (!context.mounted) return; // ✅ Check if the context is still valid

if (pickedDate != null) {
  final pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(_endDate),
  );

  if (!context.mounted) return; // ✅ Again, check before using context

  if (pickedTime != null) {
    setState(() {
      _endDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }
}
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                    foregroundColor: theme.colorScheme.tertiary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Change'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Anonymous voting option
            SwitchListTile(
              title: Text(
                'Anonymous Voting',
                style: theme.textTheme.titleSmall,
              ),
              subtitle: Text(
                'Hide who voted for which option',
                style: theme.textTheme.bodySmall,
              ),
              value: _isAnonymous,
              onChanged: (value) {
                setState(() {
                  _isAnonymous = value;
                });
              },
              activeColor: theme.colorScheme.tertiary,
            ),
            const SizedBox(height: 24),
            
            // Options
            Text(
              'Poll Options',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _optionControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _optionControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Option ${index + 1}',
                            hintText: 'Enter an option',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: Icon(
                              Icons.circle_outlined,
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Option ${index + 1} cannot be empty';
                            }
                            return null;
                          },
                        ),
                      ),
                      if (_optionControllers.length > 2)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _optionControllers[index].dispose();
                              _optionControllers.removeAt(index);
                            });
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
            
            // Add option button
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _optionControllers.add(TextEditingController());
                });
              },
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Add Option'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: 32),
            
            // Create Button
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Create vote options
                  final options = _optionControllers.map((controller) {
                    return VoteOption(
                      id: const Uuid().v4(),
                      text: controller.text.trim(),
                    );
                  }).toList();
                  
                  // Create vote
                  final newVote = Vote(
                    id: const Uuid().v4(),
                    title: _titleController.text.trim(),
                    description: _descriptionController.text.trim(),
                    options: options,
                    deadline: _endDate,
                    userVotes: {},
                    isAnonymous: _isAnonymous,
                  );
                  
                  appState.createVote(newVote);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.tertiary,
                foregroundColor: theme.colorScheme.onTertiary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Create Poll'),
            ),
          ],
        ),
      ),
    );
  }
}