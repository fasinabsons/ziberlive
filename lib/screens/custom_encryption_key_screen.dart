import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ziberlive/providers/app_state_provider.dart';
// Assuming flutter_secure_storage will be used via AppStateProvider for actual storage

class CustomEncryptionKeyScreen extends StatefulWidget {
  const CustomEncryptionKeyScreen({super.key});

  @override
  State<CustomEncryptionKeyScreen> createState() => _CustomEncryptionKeyScreenState();
}

class _CustomEncryptionKeyScreenState extends State<CustomEncryptionKeyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customKeyController = TextEditingController();
  bool _isLoading = false;
  String? _currentKeyHint; // To show if a key is set, without showing the key itself

  @override
  void initState() {
    super.initState();
    _loadCurrentKeyHint();
  }

  Future<void> _loadCurrentKeyHint() async {
    // This is conceptual. AppStateProvider would fetch from secure storage.
    // For UI purposes, we'll just get a hint if a custom key is active.
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    // String? key = await appState.getCustomEncryptionKey(); // Conceptual method
    // For now, let's use a placeholder from AppStateProvider if it had such a property
    if (appState.isCustomKeySet) { // Assuming AppStateProvider has a boolean like isCustomKeySet
        _currentKeyHint = "A custom key is currently active.";
    } else {
        _currentKeyHint = "Using default (less secure) key.";
    }
    if (mounted) setState(() {});
  }


  Future<void> _saveCustomKey() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final key = _customKeyController.text;
      final appState = Provider.of<AppStateProvider>(context, listen: false);

      // AppStateProvider would handle secure storage and then update BackupService
      bool success = await appState.setAndSaveCustomEncryptionKey(key); // Conceptual method

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          _customKeyController.clear(); // Clear field after successful save
          _loadCurrentKeyHint(); // Refresh hint
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Custom encryption key saved and applied!'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save custom key.'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _revertToDefaultKey() async {
    // Confirmation dialog
    bool? confirmRevert = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Revert to Default Key?'),
            content: const Text('This will remove your custom key. Previous backups made with the custom key will NOT be readable unless you set it again. The default key is less secure.\nAre you sure?'),
            actions: <Widget>[
                TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(dialogContext).pop(false)),
                TextButton(child: const Text('Revert to Default', style: TextStyle(color: Colors.orange)), onPressed: () => Navigator.of(dialogContext).pop(true)),
            ],
        ),
    );

    if (confirmRevert == true) {
        setState(() => _isLoading = true);
        final appState = Provider.of<AppStateProvider>(context, listen: false);
        await appState.setAndSaveCustomEncryptionKey(null); // Pass null to revert
        if (mounted) {
            setState(() => _isLoading = false);
            _loadCurrentKeyHint(); // Refresh hint
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reverted to default encryption key.'), backgroundColor: Colors.orangeAccent),
            );
        }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Encryption Key'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Icon(Icons.key_rounded, size: 60, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Manage Backup Encryption Key',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.yellow[100],
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    "WARNING:\n• Changing this key will make previous backups unrecoverable unless you re-enter the exact old key.\n• Losing your custom key means losing access to backups encrypted with it.\n• A strong, unique key (minimum 32 characters recommended for AES-256) significantly improves backup security.",
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange[800]),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_currentKeyHint != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text("Status: $_currentKeyHint", style: theme.textTheme.labelLarge, textAlign: TextAlign.center,),
                ),
              TextFormField(
                controller: _customKeyController,
                decoration: const InputDecoration(
                  labelText: 'Enter Custom Key (min 32 chars recommended)',
                  hintText: 'Leave blank to revert to default (less secure)',
                  border: OutlineInputBorder(),
                  helperText: 'If you set a key, you MUST remember it.',
                ),
                obscureText: true, // Hide the key input
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 8) { // Example: Basic minimum length
                    return 'Key is too short (min 8 characters for this demo, 32 recommended).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save Custom Key'),
                      onPressed: _saveCustomKey,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
              const SizedBox(height: 12),
               TextButton.icon(
                  icon: Icon(Icons.settings_backup_restore_rounded, color: Colors.orangeAccent[700]),
                  label: Text('Revert to Default Key', style: TextStyle(color: Colors.orangeAccent[700])),
                  onPressed: _isLoading ? null : _revertToDefaultKey,
               ),
            ],
          ),
        ),
      ),
    );
  }
}
