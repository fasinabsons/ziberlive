import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:list_rooster/providers/app_state_provider.dart';
import 'package:list_rooster/models/app_models.dart'; // For Bed, Room
import 'package:list_rooster/models/bed_type_model.dart'; // For BedType
import 'package:list_rooster/models/user_model.dart'; // For AppUser

class BedManagementScreen extends StatelessWidget {
  final String roomId;
  final String apartmentId; // Keep apartmentId for context if needed, e.g. for breadcrumbs or complex lookups

  const BedManagementScreen({Key? key, required this.roomId, required this.apartmentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final Room? room = appState.rooms.firstWhere(
      (r) => r.id == roomId,
      orElse: () => null,
    );

    if (room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Room not found.')),
      );
    }

    final List<Bed> bedsInRoom = appState.beds.where((bed) => bed.roomId == roomId).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Beds in ${room.name}'),
      ),
      body: ListView.builder(
        itemCount: bedsInRoom.length,
        itemBuilder: (context, index) {
          final bed = bedsInRoom[index];
          BedType? bedType = appState.bedTypes.firstWhere(
            (bt) => bt.typeName == bed.bedTypeName,
            orElse: () => null,
          );
          AppUser? assignedUser;
          try {
            assignedUser = appState.users.firstWhere((user) => user.assignedBedId == bed.id);
          } catch (e) {
            assignedUser = null; // No user assigned or user not found
          }

          String subtitle = 'Type: ${bed.bedTypeName}';
          if (bedType != null) {
            subtitle += ' (\$${bedType.price.toStringAsFixed(2)})';
          }
          if (assignedUser != null) {
            subtitle += '\nAssigned: ${assignedUser.name}';
          } else {
            subtitle += '\nAssigned: None';
          }

          return ListTile(
            title: Text(bed.name),
            subtitle: Text(subtitle),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _showAddEditBedDialog(context, appState, roomId, bed: bed);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // TODO: Implement delete bed confirmation & logic
                    // appState.deleteBed(bed.id);
                    debugPrint('TODO: Delete bed ${bed.id}');
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditBedDialog(context, appState, roomId);
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Bed',
      ),
    );
  }

  Future<void> _showAddEditBedDialog(
    BuildContext context,
    AppStateProvider appState,
    String roomId, {
    Bed? bed,
  }) async {
    final _formKey = GlobalKey<FormState>();
    String _bedName = bed?.name ?? '';
    String? _selectedBedTypeName = bed?.bedTypeName;
    String? _selectedUserId = bed?.id != null ? appState.users.firstWhere((u) => u.assignedBedId == bed!.id, orElse: () => null)?.id : null;

    // Controllers
    final TextEditingController nameController = TextEditingController(text: _bedName);

    // Available bed types for dropdown
    final availableBedTypes = appState.bedTypes;
    if (_selectedBedTypeName == null && availableBedTypes.isNotEmpty) {
      // _selectedBedTypeName = availableBedTypes.first.typeName; // Default if not editing
    }

    // Available users for assignment: users not assigned to any other bed, OR current user if editing this bed
    List<AppUser?> availableUsers = [null]; // For "None" option
    availableUsers.addAll(appState.users.where((user) {
      return user.assignedBedId == null || (bed != null && user.assignedBedId == bed.id);
    }));

    // Ensure _selectedUserId is valid among availableUsers, if not, set to null.
    if (_selectedUserId != null && !availableUsers.any((u) => u?.id == _selectedUserId)) {
        _selectedUserId = null;
    }


    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder( // Needed for updating dropdowns if their lists change
          builder: (context, setState) {
            return AlertDialog(
              title: Text(bed == null ? 'Add Bed' : 'Edit Bed'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Bed Name*'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bed name is required';
                          }
                          return null;
                        },
                        onSaved: (value) => _bedName = value!,
                      ),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Bed Type*'),
                        value: _selectedBedTypeName,
                        hint: const Text('Select Bed Type'),
                        items: availableBedTypes.map<DropdownMenuItem<String>>((BedType bedType) {
                          return DropdownMenuItem<String>(
                            value: bedType.typeName,
                            child: Text('${bedType.typeName} (\$${bedType.price.toStringAsFixed(2)})'),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedBedTypeName = newValue;
                          });
                        },
                        validator: (value) => value == null ? 'Bed type is required' : null,
                      ),
                      DropdownButtonFormField<String?>(
                        decoration: const InputDecoration(labelText: 'Assign User'),
                        value: _selectedUserId,
                        hint: const Text('Select User (Optional)'),
                        items: availableUsers.map<DropdownMenuItem<String?>>((AppUser? user) {
                          return DropdownMenuItem<String?>(
                            value: user?.id,
                            child: Text(user?.name ?? 'None'),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedUserId = newValue;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                TextButton(
                  child: const Text('Save'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      final newOrUpdatedBed = Bed(
                        id: bed?.id ?? Uuid().v4(), // Use existing ID if editing, else generate new
                        name: _bedName,
                        roomId: roomId,
                        bedTypeName: _selectedBedTypeName!,
                        isVacant: _selectedUserId == null,
                        // The assignedUserId is handled by AppStateProvider methods to sync AppUser
                      );

                      // Pass selectedUserId separately to AppStateProvider methods for handling user assignment logic
                      if (bed == null) {
                        appState.addBed(newOrUpdatedBed, assignedUserId: _selectedUserId);
                      } else {
                        appState.updateBed(newOrUpdatedBed, newAssignedUserId: _selectedUserId);
                      }
                      Navigator.of(dialogContext).pop();
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }
}
