import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';


/// Admin toggles for including/excluding users from bill splitting.
class AdminBillTogglesScreen extends StatelessWidget {
  const AdminBillTogglesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final bills = appState.bills;
    final users = appState.users;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Bill Toggles'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bills.length,
        itemBuilder: (context, billIdx) {
          final bill = bills[billIdx];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              title: Text(bill.title, style: theme.textTheme.titleMedium),
              subtitle: Text('Type: ${bill.type.name}'),
              children: users.map((user) {
                final isExempt = bill.exemptUsers[user.id] ?? false;
                return SwitchListTile(
                  title: Text(user.name),
                  subtitle: Text('Role: ${user.role.name}'),
                  value: !isExempt,
                  onChanged: (value) {
                    appState.toggleUserInBillSplitting(bill.id, user.id, !value);
                  },
                  secondary: Icon(
                    isExempt ? Icons.block : Icons.check_circle,
                    color: isExempt ? theme.colorScheme.error : theme.colorScheme.primary,
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
