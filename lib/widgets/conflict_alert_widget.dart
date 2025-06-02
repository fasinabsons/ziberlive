import 'package:flutter/material.dart';

class ConflictAlertWidget extends StatelessWidget {
  final String conflictMessage;
  final VoidCallback? onResolve;
  const ConflictAlertWidget({required this.conflictMessage, this.onResolve, super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Schedule Conflict'),
      content: Text(conflictMessage),
      actions: [
        if (onResolve != null)
          TextButton(
            onPressed: onResolve,
            child: const Text('Resolve'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
