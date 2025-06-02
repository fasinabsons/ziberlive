import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_state_provider.dart';
import '../models/app_models.dart';
import '../widgets/custom_widget.dart';
import '../screens/apartment_management_screen.dart';
import '../screens/user_management_screen.dart';
//import 'package:share_plus/share_plus.dart';
//import 'package:uuid/uuid.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    //final theme = Theme.of(context);
    
    if (appState.currentUser == null) {
      return const Center(
        child: Text('User not found'),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => appState.refreshData(),
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => appState.refreshData(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _UserInfoCard(user: appState.currentUser!),
            
            const SizedBox(height: 16),
            
            _SubscriptionsCard(user: appState.currentUser!),
            
            const SizedBox(height: 16),
            
            _SettingsSection(),
            
            const SizedBox(height: 16),
            
            if (appState.currentUser!.isAdmin)
              _AdminActionsCard(),
              
            const SizedBox(height: 16),
            
            _AboutCard(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _UserInfoCard extends StatelessWidget {
  final User user;
  
  const _UserInfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return CustomCard(
      title: 'Profile Information',
      titleIcon: Icons.person_rounded,
      child: Column(
        children: [
          const SizedBox(height: 16),
          // User Avatar
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    UserAvatar(
                      name: user.name,
                      size: 100,
                      backgroundColor: theme.colorScheme.primary,
                    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user.role, theme),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        _getRoleIcon(user.role),
                        color: theme.colorScheme.onPrimary,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
                Text(
                  _getRoleName(user.role),
                  style: TextStyle(
                    color: _getRoleColor(user.role, theme),
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Profile details
          _ProfileInfoItem(
            icon: Icons.stars_rounded,
            title: 'Credits',
            value: user.credits.toString(),
            valueColor: theme.colorScheme.tertiary,
          ),
          const Divider(),
          _ProfileInfoItem(
            icon: Icons.subscriptions_rounded,
            title: 'Active Subscriptions',
            value: user.subscriptions.where((s) => s.isActive).length.toString(),
            valueColor: theme.colorScheme.secondary,
          ),
          const Divider(),
          _ProfileInfoItem(
            icon: Icons.calendar_today_rounded,
            title: 'Member Since',
            value: 'March 2023', // Placeholder - would use actual join date
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.user:
        return Icons.person_rounded;
      case UserRole.roommateAdmin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.ownerAdmin:
        return Icons.stars_rounded;
      case UserRole.guest:
        return Icons.person_outline_rounded;
    }
  }
  
  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.user:
        return 'Community Member';
      case UserRole.roommateAdmin:
        return 'Roommate Admin';
      case UserRole.ownerAdmin:
        return 'Owner Admin';
      case UserRole.guest:
        return 'Guest';
    }
  }
  
  Color _getRoleColor(UserRole role, ThemeData theme) {
    switch (role) {
      case UserRole.user:
        return theme.colorScheme.primary;
      case UserRole.roommateAdmin:
        return theme.colorScheme.secondary;
      case UserRole.ownerAdmin:
        return theme.colorScheme.tertiary;
      case UserRole.guest:
        return theme.colorScheme.outline;
    }
  }
}

class _ProfileInfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;
  
  const _ProfileInfoItem({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionsCard extends StatelessWidget {
  final User user;
  
  const _SubscriptionsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return CustomCard(
      title: 'Your Subscriptions',
      titleIcon: Icons.subscriptions_rounded,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'Manage your active subscriptions and services',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          const _SubscriptionItem(
            title: 'Community Meals',
            icon: Icons.restaurant_rounded,
            isActive: true,
            description: 'Shared meals with the community',
          ),
          const Divider(),
          const _SubscriptionItem(
            title: 'Drinking Water',
            icon: Icons.water_drop_rounded,
            isActive: true,
            description: 'Clean drinking water service',
          ),
          const Divider(),
          const _SubscriptionItem(
            title: 'Room Rent',
            icon: Icons.home_rounded,
            isActive: true,
            description: 'Monthly room rental fee',
          ),
          const Divider(),
          const _SubscriptionItem(
            title: 'Utilities',
            icon: Icons.bolt_rounded,
            isActive: true,
            description: 'Electricity, water, and internet',
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Show subscription management dialog
            },
            icon: const Icon(Icons.settings_rounded),
            label: const Text('Manage Subscriptions'),
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

class _SubscriptionItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final String description;
  
  const _SubscriptionItem({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isActive
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.outline).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isActive
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.outline,
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
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: (value) {
              // Request to change subscription
            },
            activeColor: theme.colorScheme.secondary,
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    //final theme = Theme.of(context);
    
    return CustomCard(
      title: 'Settings',
      titleIcon: Icons.settings_rounded,
      child: Column(
        children: [
          _SettingItem(
            icon: Icons.sync_rounded,
            title: 'Sync Data',
            subtitle: 'Connect with nearby devices to share data',
            onTap: () => appState.startSync(),
          ),
          const Divider(),
          _SettingItem(
            icon: Icons.wifi_rounded,
            title: 'Network Settings',
            subtitle: 'Configure WiFi networks',
            onTap: () {
              // Show network settings dialog
            },
          ),
          const Divider(),
          _SettingItem(
            icon: Icons.color_lens_rounded,
            title: 'Appearance',
            subtitle: 'Change theme and appearance',
            onTap: () {
              // Show appearance settings
            },
          ),
          const Divider(),
          _SettingItem(
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () {
              // Show notification settings
            },
          ),
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  
  const _SettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
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
        subtitle,
        style: theme.textTheme.bodySmall,
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: theme.colorScheme.outline,
      ),
      onTap: onTap,
    );
  }
}

class _AdminActionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    //final appState = Provider.of<AppStateProvider>(context);
    
    return CustomCard(
      title: 'Admin Actions',
      titleIcon: Icons.admin_panel_settings_rounded,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'Special actions available to administrators',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AdminActionButton(
                icon: Icons.person_add_rounded,
                label: 'Add User',
                onPressed: () {
                  // Navigate to UserManagementScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserManagementScreen(),
                    ),
                  );
                },
              ),
              _AdminActionButton(
                icon: Icons.add_task_rounded,
                label: 'Create Task',
                onPressed: () {
                  // Navigate to task screen instead of using DefaultTabController
                  Navigator.pushNamed(context, '/tasks');
                },
              ),
              _AdminActionButton(
                icon: Icons.receipt_long_rounded,
                label: 'Create Bill',
                onPressed: () {
                  // Navigate to bills screen instead of using DefaultTabController
                  Navigator.pushNamed(context, '/bills');
                },
              ),
              _AdminActionButton(
                icon: Icons.how_to_vote_rounded,
                label: 'Create Poll',
                onPressed: () {
                  // Navigate to community screen instead of using DefaultTabController
                  Navigator.pushNamed(context, '/community');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AdminActionButton(
                icon: Icons.home_work_rounded,
                label: 'Manage Apt',
                onPressed: () {
                  // Show manage apartments dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ApartmentManagementScreen(),
                    ),
                  );
                },
              ),
              _AdminActionButton(
                icon: Icons.bed_rounded,
                label: 'Vacancy',
                onPressed: () {
                  // Show vacancy management dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ApartmentManagementScreen(),
                    ),
                  );
                },
              ),
              _AdminActionButton(
                icon: Icons.restaurant_menu_rounded,
                label: 'Meals',
                onPressed: () {
                  // Show community cooking management dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('This would open the meal management view')),
                  );
                },
              ),
              _AdminActionButton(
                icon: Icons.trending_up_rounded,
                label: 'Stats',
                onPressed: () {
                  // Show community statistics dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('This would open the community statistics view')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  
  const _AdminActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return CustomCard(
      title: 'About',
      titleIcon: Icons.info_outline_rounded,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'CoLivify',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            'Version 1.0.0',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(
            'A platform for managing co-living spaces with ease. Track bills, assign tasks, vote on community decisions, and build a thriving community together.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.privacy_tip_outlined,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () {
                  // Show privacy policy
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.description_outlined,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () {
                  // Show terms of service
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.contact_support_outlined,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () {
                  // Show contact support
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.favorite_outline,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () {
                  // Show acknowledgments
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}