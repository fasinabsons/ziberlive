import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:list_rooster/providers/app_state_provider.dart';
import 'package:list_rooster/models/app_models.dart'; // For Apartment
import 'package:uuid/uuid.dart'; // Import Uuid
import 'room_management_screen.dart'; // Import RoomManagementScreen

class ApartmentManagementScreen extends StatelessWidget {
  const ApartmentManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Apartments'),
      ),
      body: ListView.builder(
        itemCount: appState.apartments.length,
        itemBuilder: (context, index) {
          final apartment = appState.apartments[index];
          return ListTile(
            title: Text(apartment.name),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => RoomManagementScreen(apartmentId: apartment.id)));
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _showAddEditApartmentDialog(context, appState, apartment: apartment);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // TODO: Implement delete apartment confirmation
                    // appState.deleteApartment(apartment.id);
                    debugPrint('TODO: Delete apartment ${apartment.id}');
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditApartmentDialog(context, appState);
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Apartment',
      ),
    );
  }

  Future<void> _showAddEditApartmentDialog(
    BuildContext context,
    AppStateProvider appState,
    {Apartment? apartment}
  ) async {
    final _formKey = GlobalKey<FormState>();
    String _apartmentName = apartment?.name ?? '';
    final TextEditingController nameController = TextEditingController(text: _apartmentName);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(apartment == null ? 'Add Apartment' : 'Edit Apartment Name'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Apartment Name*'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Apartment name is required';
                      }
                      // Optional: Check for uniqueness if needed, though not specified for apartments
                      // bool isUnique = !appState.apartments.any((apt) => apt.name == value && (apartment == null || apt.id != apartment.id));
                      // if (!isUnique) {
                      //   return 'Apartment name must be unique';
                      // }
                      return null;
                    },
                    onSaved: (value) => _apartmentName = value!,
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

                  if (apartment == null) {
                    final newApartment = Apartment(id: Uuid().v4(), name: _apartmentName, rooms: []);
                    appState.addApartment(newApartment);
                  } else {
                    // Assuming Apartment has a copyWith method or similar for updates
                    // If not, this needs to be adjusted: e.g., create new instance with old ID and new name
                    final updatedApartment = Apartment(id: apartment.id, name: _apartmentName, rooms: apartment.rooms); // Manual update if no copyWith
                    appState.updateApartment(updatedApartment);
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
