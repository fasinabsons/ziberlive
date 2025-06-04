import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ziberlive/providers/app_state_provider.dart';
import 'package:ziberlive/config.dart'; // For style options

class SyncButtonStyleScreen extends StatelessWidget {
  const SyncButtonStyleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final theme = Theme.of(context);

    // Correcting the potentially problematic loop icon codepoint for display
    Map<String, int> displayIconOptions = Map.from(kSyncButtonIconOptions);
    if (displayIconOptions.containsKey("Loop") && displayIconOptions["Loop"] == 0xe3ループ) {
        displayIconOptions["Loop (Fixed)"] = 0xe3a5; // Using correct Icons.loop.codePoint
        displayIconOptions.remove("Loop"); // Remove potentially problematic key if names must be unique
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Sync Button'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          Text("Preview Sync Button:", style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          Center(
            child: IconButton(
              icon: Icon(appState.syncButtonIconData, color: appState.syncButtonColor),
              iconSize: 40,
              onPressed: () {
                // Dummy action for preview
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("This is a preview of your sync button!"))
                );
              },
            ),
          ),
          const Divider(height: 30, thickness: 1),

          Text("Button Icon", style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: displayIconOptions.entries.map((entry) {
              final String iconName = entry.key;
              final int iconCodepoint = entry.value;
              final bool isSelected = appState.syncButtonIconData.codePoint == iconCodepoint;

              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(IconData(iconCodepoint, fontFamily: 'MaterialIcons'),
                         color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface),
                    const SizedBox(width: 8),
                    Text(iconName),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    appState.setSyncButtonIcon(iconCodepoint);
                  }
                },
                selectedColor: theme.colorScheme.primary,
                labelStyle: TextStyle(color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface),
              );
            }).toList(),
          ),
          const Divider(height: 30, thickness: 1),

          Text("Button Color", style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: kSyncButtonColorOptions.entries.map((entry) {
              final String colorName = entry.key;
              final int colorValue = entry.value;
              final Color displayColor = Color(colorValue);
              final bool isSelected = appState.syncButtonColor.value == colorValue;

              return ChoiceChip(
                avatar: CircleAvatar(backgroundColor: displayColor, radius: 10),
                label: Text(colorName),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    appState.setSyncButtonColor(colorValue);
                  }
                },
                selectedColor: displayColor.withOpacity(0.8),
                labelStyle: TextStyle(color: isSelected ? Colors.white : null), // Basic contrast
                backgroundColor: displayColor.withOpacity(0.2),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
