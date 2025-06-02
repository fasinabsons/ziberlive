import 'package:flutter/material.dart';

class AuditTrailWidget extends StatelessWidget {
  final List<String> logs;
  const AuditTrailWidget({required this.logs, super.key});
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('Audit Trail'),
      children: logs.map((log) => ListTile(title: Text(log))).toList(),
    );
  }
}
