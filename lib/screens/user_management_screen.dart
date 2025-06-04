import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/app_models.dart';
import '../widgets/custom_widget.dart';
import 'package:uuid/uuid.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => appState.refreshData(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomCard(
              title: 'All Users',
              titleIcon: Icons.people_rounded,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => appState.refreshData(),
                ),
              ],
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Manage all users of your co-living space',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (appState.users.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 64,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: appState.users.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final user = appState.users[index];
                        return _UserListItem(user: user);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(context),
        backgroundColor: theme.colorScheme.primary,
        heroTag: 'add_user',
        child: const Icon(Icons.person_add_rounded),
      ),
    );
  }
  
  void _showAddUserDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => const _AddUserForm(),
      ),
    );
  }
}

class _UserListItem extends StatelessWidget {
  final User user;
  
  const _UserListItem({required this.user});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppStateProvider>(context);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: UserAvatar(
        name: user.name,
        size: 50,
        backgroundColor: _getRoleColor(user.role, theme),
      ),
      title: Text(
        user.name,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getRoleName(user.role),
            style: TextStyle(
              color: _getRoleColor(user.role, theme),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.stars_rounded, size: 14, color: theme.colorScheme.tertiary),
              const SizedBox(width: 4),
              Text(
                '${user.credits} credits',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: 12),
              Icon(Icons.subscriptions_rounded, size: 14, color: theme.colorScheme.secondary),
              const SizedBox(width: 4),
              Text(
                '${user.subscriptions.where((s) => s.isActive).length} subscriptions',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => _showEditUserDialog(context, user),
            tooltip: 'Edit user',
          ),
          if (appState.currentUser?.isAdmin ?? false) // Only admins can mark device as lost
            IconButton(
              icon: Icon(
                user.isDeviceLost ? Icons.phonelink_erase_rounded : Icons.phonelink_lock_rounded,
                color: user.isDeviceLost ? Colors.orange : Colors.grey,
              ),
              onPressed: () => _confirmToggleDeviceLost(context, appState, user),
              tooltip: user.isDeviceLost ? 'Mark Device as Found' : 'Mark Device as Lost',
            ),
          if (user.id != appState.currentUser?.id && (appState.currentUser?.isAdmin ?? false))
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: Colors.red),
              onPressed: () => _confirmDeleteUser(context, user),
              tooltip: 'Delete user',
            ),
        ],
      ),
    );
  }
  
  void _showEditUserDialog(BuildContext context, User user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit user: ${user.name}')),
    );
  }
  
  void _confirmDeleteUser(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${user.name}?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Delete user logic here
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('User ${user.name} deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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

class _AddUserForm extends StatefulWidget {
  const _AddUserForm();

  @override
  State<_AddUserForm> createState() => _AddUserFormState();
}

class _AddUserFormState extends State<_AddUserForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  UserRole _selectedRole = UserRole.user;
  int _initialCredits = 0;
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add New User',
                  style: theme.textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.person_rounded),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.email_rounded),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UserRole>(
              decoration: InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.admin_panel_settings_rounded),
              ),
              value: _selectedRole,
              items: UserRole.values.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(_getRoleName(role)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRole = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Initial Credits',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.stars_rounded),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: _initialCredits.toString(),
                    onChanged: (value) {
                      setState(() {
                        _initialCredits = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add User'),
            ),
          ],
        ),
      ),
    );
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
  
  void _saveUser() {
    if (_formKey.currentState!.validate()) {
      // Create new user
      final newUser = User(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        credits: _initialCredits,
        role: _selectedRole,
      );
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added user ${newUser.name}')),
      );
      
      // Close dialog
      Navigator.pop(context);
    }
  }
} 