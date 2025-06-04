import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import 'premium_features_screen.dart';
import 'bulk_import_export_screen.dart';
import 'package:ziberlive/config.dart'; // Import config for kSettingsAdsDailyCap
import 'amazon_coupons_screen.dart'; // Import the new AmazonCouponsScreen
import 'paypal_rewards_screen.dart'; // Import the new PayPalRewardsScreen
import 'income_pool_screen.dart'; // Import the new IncomePoolScreen
import 'qr_sync_screen.dart'; // Import the new QrSyncScreen
import 'sync_button_style_screen.dart'; // Import the new SyncButtonStyleScreen

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    //final theme = Theme.of(context);
    final user = appState.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.wifi),
              title: const Text('Network Configuration'),
              subtitle: Text(appState.networkSSID ?? 'Not set'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  showDialog(
  context: context,
  builder: (context) {
    final ssidController = TextEditingController(text: appState.networkSSID ?? '');
    return AlertDialog(
      title: const Text('Edit SSID'),
      content: TextField(
        controller: ssidController,
        decoration: const InputDecoration(labelText: 'SSID'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            appState.setNetworkSSID(ssidController.text.trim());
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  },
);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.backup_rounded),
              title: const Text('Backup Management'),
              subtitle: Text(appState.isPremium ? 'Cloud Backup enabled' : 'Local Backup only'),
              trailing: Switch(
                value: appState.isPremium,
                onChanged: (value) {
                  if (!appState.isPremium) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => const PremiumFeaturesScreen()),
  );
} else {
  appState.setPremium(!appState.isPremium);
}
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_add_alt_1_rounded),
              title: const Text('Multi-Login'),
              subtitle: Text(appState.multiLoginEnabled ? 'Enabled' : 'Disabled'),
              trailing: Switch(
                value: appState.multiLoginEnabled,
                onChanged: (value) {
                  appState.setMultiLoginEnabled(!appState.multiLoginEnabled);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.workspace_premium_rounded),
              title: const Text('Premium Features'),
              subtitle: const Text('Analytics, photo uploads, and more'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const PremiumFeaturesScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.import_export_rounded),
              title: const Text('Bulk Import & Export'),
              subtitle: const Text('Import/export your data in bulk'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const BulkImportExportScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.label_important_rounded),
              title: const Text('Custom Labels'),
              subtitle: Text('Edit bill/service names'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  showDialog(
  context: context,
  builder: (context) {
    final labelController = TextEditingController();
    return AlertDialog(
      title: const Text('Edit Custom Labels'),
      content: TextField(
        controller: labelController,
        decoration: const InputDecoration(labelText: 'New label'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Simulate label update
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Label updated (demo)')),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  },
);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_user_rounded),
              title: const Text('Role Management'),
              subtitle: Text(user?.isOwnerAdmin == true ? 'Owner-Admin' : user?.isRoommateAdmin == true ? 'Roommate-Admin' : 'User'),
              trailing: IconButton(
                icon: const Icon(Icons.swap_horiz),
                onPressed: () {
                  showDialog(
  context: context,
  builder: (context) {
    return AlertDialog(
      title: const Text('Change Role'),
      content: const Text('Role change demo. Implement real logic as needed.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Simulate role change
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Role changed (demo)')),
            );
          },
          child: const Text('Change'),
        ),
      ],
    );
  },
);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_active_rounded),
              title: const Text('Notification Preferences'),
              subtitle: Text('Configure which notifications to receive'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Notification Preferences'),
                      content: const Text('Notification settings UI coming soon.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16), // Spacing before new card
          Card(
            child: Consumer<AppStateProvider>( // Use Consumer to easily update UI based on ad state
              builder: (context, appStateConsumer, child) {
                bool canWatchAd = appStateConsumer.canWatchSettingsAd();
                return ListTile(
                  leading: Icon(
                    Icons.slow_motion_video_rounded, // Icon for rewarded video
                    color: canWatchAd ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor,
                  ),
                  title: Text(
                    'Watch Ad for Rewards',
                    style: TextStyle(
                      color: canWatchAd ? null : Theme.of(context).disabledColor,
                    ),
                  ),
                  subtitle: Text(
                    canWatchAd
                      ? "${appStateConsumer.settingsAdsLeftToday} of $kSettingsAdsDailyCap ads left today"
                      : "Daily ad limit reached. Try again tomorrow.",
                    style: TextStyle(
                      color: canWatchAd ? null : Theme.of(context).disabledColor,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: canWatchAd ? null : Theme.of(context).disabledColor,
                  ),
                  enabled: canWatchAd,
                  onTap: canWatchAd
                      ? () async {
                          bool adInitiated = await appStateConsumer.showSettingsRewardedAd();
                          if (adInitiated) {
                            // Optionally show a brief confirmation that ad process started
                            // Actual reward confirmation will come from ad callbacks via AppStateProvider
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Attempting to show ad...'), duration: Duration(seconds: 2)),
                            );
                          } else {
                            // This case (cap reached) is handled by enabled state, but as a fallback:
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cannot show ad now. Daily limit might be reached.'), duration: Duration(seconds: 2)),
                            );
                          }
                        }
                      : null, // onTap is null if disabled
                );
              },
            ),
          ),
          const SizedBox(height: 16), // Spacing before new card
          Card(
            child: ListTile(
              leading: const Icon(Icons.shopping_cart_checkout_rounded), // Icon for Amazon/coupons
              title: const Text('Amazon Coupons'),
              subtitle: const Text('View and redeem your Amazon coupon points'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AmazonCouponsScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16), // Spacing before new card
          Card(
            child: ListTile(
              leading: Icon(Icons.paypal_rounded, color: Colors.blue[800]), // Icon for PayPal
              title: const Text('PayPal Rewards'),
              subtitle: const Text('View and redeem your PayPal points for cash'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const PayPalRewardsScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(Icons.group_work_rounded, color: Colors.orangeAccent),
              title: const Text('Income Pool Collaboration'),
              subtitle: const Text('View collective goals and contribute points'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const IncomePoolScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.qr_code_scanner_rounded),
              title: const Text('Manual Sync / QR Code'),
              subtitle: const Text('Initiate P2P sync using QR codes'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const QrSyncScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.timer_rounded),
              title: const Text('Automatic Sync Interval'),
              subtitle: Text(appState.currentSyncIntervalLabel), // Assuming getter in AppStateProvider
              onTap: () => _showSyncIntervalDialog(context, appState),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings_ethernet_rounded),
              title: const Text('Preferred Sync Technology'),
              subtitle: Text(appState.currentSyncMethodPriorityLabel), // Assuming getter
              onTap: () => _showSyncMethodPriorityDialog(context, appState),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.palette_rounded),
              title: const Text('Customize Sync Button Style'),
              subtitle: const Text('Change color and icon of the manual sync button'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SyncButtonStyleScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSyncIntervalDialog(BuildContext context, AppStateProvider appState) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Sync Interval'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: SyncIntervalOption.values.map((option) {
              return RadioListTile<SyncIntervalOption>(
                title: Text(kSyncIntervalLabels[option] ?? option.toString()),
                value: option,
                groupValue: appState.selectedSyncInterval, // Assuming getter
                onChanged: (SyncIntervalOption? value) {
                  if (value != null) {
                    appState.setSelectedSyncInterval(value);
                  }
                  Navigator.of(dialogContext).pop();
                },
              );
            }).toList(),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSyncMethodPriorityDialog(BuildContext context, AppStateProvider appState) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Preferred Sync Technology'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: SyncMethodPriority.values.map((option) {
              return RadioListTile<SyncMethodPriority>(
                title: Text(kSyncMethodPriorityLabels[option] ?? option.toString()),
                value: option,
                groupValue: appState.selectedSyncMethodPriority, // Assuming getter
                onChanged: (SyncMethodPriority? value) {
                  if (value != null) {
                    appState.setSelectedSyncMethodPriority(value);
                  }
                  Navigator.of(dialogContext).pop();
                },
              );
            }).toList(),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
