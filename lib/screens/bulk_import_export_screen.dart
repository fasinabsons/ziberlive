import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ziberlive/providers/app_state_provider.dart';
import 'package:ziberlive/config.dart'; // For options
import 'package:file_picker/file_picker.dart';
import 'package:confetti/confetti.dart'; // For success animation
import 'dart:math'; // For confetti direction
import 'custom_encryption_key_screen.dart'; // For navigation

class BulkImportExportScreen extends StatefulWidget {
  const BulkImportExportScreen({super.key});

  @override
  State<BulkImportExportScreen> createState() => _BulkImportExportScreenState();
}

class _BulkImportExportScreenState extends State<BulkImportExportScreen> {
  bool _isLoading = false;
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

  Future<void> _handleExportBackup(BuildContext context) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    setState(() => _isLoading = true);
    // Simple dialog for progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const AlertDialog(
          title: Text('Exporting Backup...'),
          content: Row(
            children: [CircularProgressIndicator(), SizedBox(width: 20), Text("Please wait...")],
          ),
        );
      },
    );

    String? filePath = await appState.exportEncryptedBackup(); // Assumed async in AppStateProvider

    if (mounted) Navigator.of(context, rootNavigator: true).pop(); // Close progress dialog
    setState(() => _isLoading = false);

    if (context.mounted) {
      if (filePath != null) {
        _confettiController.play();
        showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                  title: const Text("Backup Complete!"),
                  content: Text('Encrypted backup saved to app documents: $filePath.\n\nNOTE: To access this file, you might need to use your device\'s file browser to navigate to the app\'s data folder, or use a share function (developer TODO). For now, file path logged in console.'),
                  actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("OK"))],
                ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup failed.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleImportBackup(BuildContext context) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['encjson'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        bool? confirmImport = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Confirm Import'),
            content: const Text('Importing a backup will OVERWRITE current data. This action cannot be undone. Are you sure?'),
            actions: <Widget>[
              TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(dialogContext).pop(false)),
              TextButton(child: const Text('Import Data', style: TextStyle(color: Colors.red)), onPressed: () => Navigator.of(dialogContext).pop(true)),
            ],
          ),
        );

        if (confirmImport == true && mounted) {
          setState(() => _isLoading = true);
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
              return const AlertDialog(
                title: Text('Importing Backup...'),
                content: Row(
                  children: [CircularProgressIndicator(), SizedBox(width: 20), Text("Restoring data...")],
                ),
              );
            },
          );

          bool success = await appState.importEncryptedBackup(filePath);

          if (mounted) Navigator.of(context, rootNavigator: true).pop(); // Close progress dialog
          setState(() => _isLoading = false);

          if (mounted) {
            if (success) {
              _confettiController.play();
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                      title: const Text("Data Restored!"),
                      content: const Text('Backup imported and data restored successfully! The app has been refreshed with the backup data.'),
                      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Awesome!"))],
                    ));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Import failed. File might be corrupted, invalid, or wrong encryption key.'), backgroundColor: Colors.red),
              );
            }
          }
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No file selected.')));
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error during file picking or import: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $e'), backgroundColor: Colors.red));
    }
  }

  void _showBackupScheduleDialog(BuildContext context, AppStateProvider appState) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Backup Schedule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: BackupScheduleOption.values.map((option) {
              return RadioListTile<BackupScheduleOption>(
                title: Text(kBackupScheduleLabels[option] ?? option.toString()),
                value: option,
                groupValue: appState.selectedBackupSchedule, // Assumes getter in AppState
                onChanged: (BackupScheduleOption? value) {
                  if (value != null) {
                    appState.setSelectedBackupSchedule(value); // Assumes setter in AppState
                  }
                  Navigator.of(dialogContext).pop();
                },
              );
            }).toList(),
          ),
          actions: <Widget>[TextButton(child: const Text('Cancel'),onPressed: () => Navigator.of(dialogContext).pop())],
        );
      },
    );
  }

   void _showBackupScopeDialog(BuildContext context, AppStateProvider appState) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Backup Scope'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: BackupScopeOption.values.map((option) { // Only "Full" for now
              return RadioListTile<BackupScopeOption>(
                title: Text(kBackupScopeLabels[option] ?? option.toString()),
                value: option,
                groupValue: appState.selectedBackupScope, // Assumes getter
                onChanged: (BackupScopeOption? value) {
                  if (value != null) {
                    appState.setSelectedBackupScope(value); // Assumes setter
                  }
                  Navigator.of(dialogContext).pop();
                },
              );
            }).toList(),
          ),
           actions: <Widget>[TextButton(child: const Text('Cancel'),onPressed: () => Navigator.of(dialogContext).pop())],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context); // Listen for changes to update UI

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore Settings'),
        centerTitle: true,
      ),
      body: Stack( // For Confetti
        alignment: Alignment.topCenter,
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ImportExportCard(
                icon: Icons.enhanced_encryption_rounded,
                title: 'Export Encrypted Backup',
                description: 'Create a secure, encrypted backup of all your app data. Saved to app documents.',
                actionLabel: 'Export Backup',
                onPressed: _isLoading ? (){} : () => _handleExportBackup(context), // Disable button while loading
              ),
              const SizedBox(height: 16),
              _ImportExportCard(
                icon: Icons.system_update_alt_rounded,
                title: 'Import Encrypted Backup',
                description: 'Restore data from an encrypted backup. This will overwrite existing data.',
                actionLabel: 'Import Backup',
                onPressed: _isLoading ? (){} : () => _handleImportBackup(context), // Disable button
              ),
              const Divider(height: 32, thickness: 1),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.key_rounded),
                  title: const Text('Custom Encryption Key'),
                  subtitle: Text(appState.isCustomKeySet ? "Custom key is active" : "Using default key (less secure)"),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CustomEncryptionKeyScreen())),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.schedule_rounded),
                  title: const Text('Backup Schedule'),
                  subtitle: Text(appState.currentBackupScheduleLabel), // Assumes getter
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  onTap: () => _showBackupScheduleDialog(context, appState),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.rule_folder_rounded),
                  title: const Text('Backup Scope'),
                  subtitle: Text(appState.currentBackupScopeLabel), // Assumes getter
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  onTap: () => _showBackupScopeDialog(context, appState),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Security Note: Using a strong, unique custom encryption key is highly recommended. Ensure you store your custom key securely if you set one.",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportExportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onPressed;

  const _ImportExportCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onPressed,
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
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(description, style: theme.textTheme.bodySmall), // Changed to bodySmall for more text
                  const SizedBox(height: 16),
                  ElevatedButton.icon( // Changed to ElevatedButton.icon
                    icon: Icon(actionLabel == 'Export Backup' ? Icons.cloud_upload_outlined : Icons.cloud_download_outlined),
                    onPressed: onPressed,
                    label: Text(actionLabel),
                     style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        textStyle: const TextStyle(fontSize: 15)
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
