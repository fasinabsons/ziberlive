import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:list_rooster/providers/app_state_provider.dart';
import 'package:list_rooster/models/app_models.dart'; // For Room, Apartment
import 'package:uuid/uuid.dart'; // Import Uuid
import 'bed_management_screen.dart'; // Import BedManagementScreen

class RoomManagementScreen extends StatelessWidget {
  final String apartmentId;

  const RoomManagementScreen({Key? key, required this.apartmentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final Apartment? apartment = appState.apartments.firstWhere(
      (apt) => apt.id == apartmentId,
      orElse: () => null, // Should handle if apartment not found
    );

    if (apartment == null) {
      // Handle case where apartment is not found, perhaps pop navigator or show error
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Apartment not found.')),
      );
    }

    // Filter rooms for the current apartment.
    // Note: AppStateProvider currently has _rooms as a flat list.
    // If rooms were nested in Apartment objects, this would be apartment.rooms
    final List<Room> roomsForApartment = appState.rooms.where((room) => room.apartmentId == apartmentId).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Rooms in ${apartment.name}'),
      ),
      body: ListView.builder(
        itemCount: roomsForApartment.length,
        itemBuilder: (context, index) {
          final room = roomsForApartment[index];
          return ListTile(
            title: Text(room.name),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => BedManagementScreen(roomId: room.id, apartmentId: apartmentId),
              ));
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _showAddEditRoomDialog(context, appState, apartment.id, room: room);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // TODO: Implement delete room confirmation
                    // appState.deleteRoom(room.id);
                    debugPrint('TODO: Delete room ${room.id}');
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditRoomDialog(context, appState, apartment.id);
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Room',
      ),
    );
  }

  Future<void> _showAddEditRoomDialog(
    BuildContext context,
    AppStateProvider appState,
    String apartmentId, // apartmentId is crucial here
    {Room? room}
  ) async {
    final _formKey = GlobalKey<FormState>();
    String _roomName = room?.name ?? '';
    final TextEditingController nameController = TextEditingController(text: _roomName);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(room == null ? 'Add Room' : 'Edit Room Name'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Room Name*'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Room name is required';
                      }
                      // Optional: Check for uniqueness within the same apartment if needed
                      // bool isUniqueInApartment = !appState.rooms.any((r) =>
                      //    r.apartmentId == apartmentId && r.name == value && (room == null || r.id != room.id));
                      // if (!isUniqueInApartment) {
                      //   return 'Room name must be unique within this apartment';
                      // }
                      return null;
                    },
                    onSaved: (value) => _roomName = value!,
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

                  if (room == null) {
                    final newRoom = Room(id: Uuid().v4(), name: _roomName, apartmentId: apartmentId, beds: []);
                    appState.addRoom(newRoom);
                  } else {
                    // Assuming Room has a copyWith method or similar for updates
                    // If not, this needs to be adjusted
                    final updatedRoom = Room(id: room.id, name: _roomName, apartmentId: room.apartmentId, beds: room.beds); // Manual update if no copyWith
                    appState.updateRoom(updatedRoom);
                  }
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
