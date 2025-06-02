import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_state_provider.dart';
import '../models/app_models.dart';
import '../widgets/custom_widget.dart';
import 'package:uuid/uuid.dart';

class ApartmentManagementScreen extends StatefulWidget {
  const ApartmentManagementScreen({super.key});

  @override
  State<ApartmentManagementScreen> createState() => _ApartmentManagementScreenState();
}

class _ApartmentManagementScreenState extends State<ApartmentManagementScreen> with SingleTickerProviderStateMixin {
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
        title: const Text('Apartment Management'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Apartments'),
            Tab(text: 'Rooms'),
            Tab(text: 'Occupants'),
          ],
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha:0.7),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ApartmentsTab(),
          _RoomsTab(),
          _OccupantsTab(),
        ],
      ),
      floatingActionButton: _getFloatingActionButton(),
    );
  }
  
  Widget _getFloatingActionButton() {
    final theme = Theme.of(context);
    
    // Different FAB for each tab
    switch (_tabController.index) {
      case 0:
        return FloatingActionButton(
          onPressed: () => _showAddApartmentDialog(),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          heroTag: 'add_apartment',
          child: const Icon(Icons.add_home_rounded),
        ).animate().scale(duration: 300.ms, curve: Curves.easeOut);
      case 1:
        return FloatingActionButton(
          onPressed: () => _showAddRoomDialog(),
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.onSecondary,
          heroTag: 'add_room',
          child: const Icon(Icons.meeting_room_rounded),
        ).animate().scale(duration: 300.ms, curve: Curves.easeOut);
      case 2:
        return FloatingActionButton(
          onPressed: () => _showAddOccupantDialog(),
          backgroundColor: theme.colorScheme.tertiary,
          foregroundColor: theme.colorScheme.onTertiary,
          heroTag: 'add_occupant',
          child: const Icon(Icons.person_add_rounded),
        ).animate().scale(duration: 300.ms, curve: Curves.easeOut);
      default:
        return const SizedBox.shrink();
    }
  }
  
  void _showAddApartmentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => const _AddApartmentForm(),
      ),
    );
  }
  
  void _showAddRoomDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => const _AddRoomForm(),
      ),
    );
  }
  
  void _showAddOccupantDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => const _AddOccupantForm(),
      ),
    );
  }
}

class _ApartmentsTab extends StatelessWidget {
  const _ApartmentsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Mock data - would use actual data from AppStateProvider
    final apartments = [
      Apartment(
        id: '1',
        name: 'Main House',
        rooms: [],
      ),
      Apartment(
        id: '2',
        name: 'Guest House',
        rooms: [],
      ),
    ];
    
    if (apartments.isEmpty) {
      return const EmptyStateView(
        icon: Icons.apartment_rounded,
        message: 'No apartments added yet',
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: apartments.length,
      itemBuilder: (context, index) {
        final apartment = apartments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.apartment_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
            title: Text(
              apartment.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${apartment.rooms.length} rooms',
              style: theme.textTheme.bodyMedium,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_rounded, color: theme.colorScheme.primary),
                  onPressed: () {
                    // Edit apartment
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  onPressed: () {
                    // Delete apartment
                  },
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms);
      },
    );
  }
}

class _RoomsTab extends StatelessWidget {
  const _RoomsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Mock data - would use actual data from AppStateProvider
    final rooms = [
      Room(
        id: '1',
        name: 'Bedroom 1',
        isVacant: false,
        beds: [],
      ),
      Room(
        id: '2',
        name: 'Bedroom 2',
        isVacant: true,
        beds: [],
      ),
      Room(
        id: '3',
        name: 'Living Room',
        isVacant: false,
        beds: [],
      ),
    ];
    
    if (rooms.isEmpty) {
      return const EmptyStateView(
        icon: Icons.meeting_room_rounded,
        message: 'No rooms added yet',
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.meeting_room_rounded,
                color: theme.colorScheme.secondary,
              ),
            ),
            title: Text(
              room.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${room.beds.length} beds',
              style: theme.textTheme.bodyMedium,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusBadge(
                  text: room.isVacant ? 'Vacant' : 'Occupied',
                  color: room.isVacant ? Colors.green : Colors.orange,
                  isActive: true,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.edit_rounded, color: theme.colorScheme.secondary),
                  onPressed: () {
                    // Edit room
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  onPressed: () {
                    // Delete room
                  },
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms);
      },
    );
  }
}

class _OccupantsTab extends StatelessWidget {
  const _OccupantsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppStateProvider>(context);
    
    if (appState.users.isEmpty) {
      return const EmptyStateView(
        icon: Icons.person_rounded,
        message: 'No users added yet',
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appState.users.length,
      itemBuilder: (context, index) {
        final user = appState.users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: UserAvatar(
              name: user.name,
              size: 50,
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
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  'Credits: ${user.credits}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_rounded, color: theme.colorScheme.tertiary),
                  onPressed: () {
                    // Edit user
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  onPressed: () {
                    // Delete user
                  },
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms);
      },
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
}

// Simple form components for adding entities
class _AddApartmentForm extends StatefulWidget {
  const _AddApartmentForm();

  @override
  State<_AddApartmentForm> createState() => _AddApartmentFormState();
}

class _AddApartmentFormState extends State<_AddApartmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _numberOfRooms = 1;
  int _bedsPerRoom = 1;
  
  @override
  void dispose() {
    _nameController.dispose();
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Apartment',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Apartment Name',
                hintText: 'e.g. Main House',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Number of Rooms',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  if (_numberOfRooms > 1) _numberOfRooms--;
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                '$_numberOfRooms',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  _numberOfRooms++;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Beds per Room',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  if (_bedsPerRoom > 1) _bedsPerRoom--;
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                '$_bedsPerRoom',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  _bedsPerRoom++;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveApartment,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add Apartment'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _saveApartment() {
    if (_formKey.currentState!.validate()) {
      // Create and save apartment with rooms and beds
      final uuid = const Uuid();
      final List<Room> rooms = [];
      
      // Create rooms with beds
      for (int i = 1; i <= _numberOfRooms; i++) {
        final List<Bed> beds = [];
        
        // Create beds for each room
        for (int j = 1; j <= _bedsPerRoom; j++) {
          beds.add(
            Bed(
              id: uuid.v4(),
              name: 'Bed $j',
              isVacant: true,
            ),
          );
        }
        
        // Add room with beds
        rooms.add(
          Room(
            id: uuid.v4(),
            name: 'Room $i',
            isVacant: true,
            beds: beds,
          ),
        );
      }
      
      // Create apartment with rooms
      final apartment = Apartment(
        id: uuid.v4(),
        name: _nameController.text.trim(),
        rooms: rooms,
      );
      
      // In a real app, would save this to the provider
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${apartment.name} with $_numberOfRooms rooms')),
      );
      
      Navigator.pop(context);
    }
  }
}

class _AddRoomForm extends StatefulWidget {
  const _AddRoomForm();

  @override
  State<_AddRoomForm> createState() => _AddRoomFormState();
}

class _AddRoomFormState extends State<_AddRoomForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isVacant = true;
  String? _selectedApartmentId;
  
  // Mock apartments - would use actual data
  final _apartments = [
    Apartment(id: '1', name: 'Main House', rooms: []),
    Apartment(id: '2', name: 'Guest House', rooms: []),
  ];
  
  @override
  void dispose() {
    _nameController.dispose();
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Room',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Apartment',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _apartments.map((apartment) {
                return DropdownMenuItem(
                  value: apartment.id,
                  child: Text(apartment.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedApartmentId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select an apartment';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Room Name',
                hintText: 'e.g. Bedroom 1',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Vacant'),
              value: _isVacant,
              onChanged: (value) {
                setState(() {
                  _isVacant = value;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add Room'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _saveRoom() {
    if (_formKey.currentState!.validate()) {
      // Create and save room
      final room = Room(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        isVacant: _isVacant,
        beds: [],
      );
      
      // In a real app, would save this to the provider
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${room.name} to ${_apartments.firstWhere((a) => a.id == _selectedApartmentId).name}')),
      );
      
      Navigator.pop(context);
    }
  }
}

class _AddOccupantForm extends StatefulWidget {
  const _AddOccupantForm();

  @override
  State<_AddOccupantForm> createState() => _AddOccupantFormState();
}

class _AddOccupantFormState extends State<_AddOccupantForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  UserRole _selectedRole = UserRole.user;
  
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New User',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.tertiary,
                foregroundColor: theme.colorScheme.onTertiary,
                minimumSize: const Size(double.infinity, 50),
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
      // Create and save user
      final user = User(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        credits: 0,
        role: _selectedRole,
      );
      
      // In a real app, would save this to the provider
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added user ${user.name}')),
      );
      
      Navigator.pop(context);
    }
  }
} 