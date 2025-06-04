import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:list_rooster/providers/app_state_provider.dart';
import 'package:list_rooster/models/bed_type_model.dart';

class BedTypeManagementScreen extends StatelessWidget {
  const BedTypeManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Access AppStateProvider
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bed Types'),
      ),
      body: ListView.builder(
        itemCount: appState.bedTypes.length,
        itemBuilder: (context, index) {
          final bedType = appState.bedTypes[index];
          // Display BedType information (details to be added)
          return ListTile(
            title: Text(bedType.typeName),
            subtitle: Text(
                'Price: \$${bedType.price.toStringAsFixed(2)}' +
                (bedType.customLabel != null && bedType.customLabel!.isNotEmpty ? '\nLabel: ${bedType.customLabel}' : '') +
                (bedType.premiumFixedAmount != null ? '\nPremium Fixed: \$${bedType.premiumFixedAmount!.toStringAsFixed(2)}' : '') +
                (bedType.premiumPercentage != null ? '\nPremium %: ${(bedType.premiumPercentage! * 100).toStringAsFixed(0)}%' : '')
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _showAddEditBedTypeDialog(context, appState, bedType: bedType);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditBedTypeDialog(context, appState);
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Bed Type',
      ),
    );
  }

  Future<void> _showAddEditBedTypeDialog(
    BuildContext context,
    AppStateProvider appState,
    {BedType? bedType}
  ) async {
    final _formKey = GlobalKey<FormState>();
    String _typeName = bedType?.typeName ?? '';
    double _price = bedType?.price ?? 0.0;
    String? _customLabel = bedType?.customLabel;
    double? _premiumFixedAmount = bedType?.premiumFixedAmount;
    double? _premiumPercentage = bedType?.premiumPercentage;

    // Controllers for text fields
    final TextEditingController typeNameController = TextEditingController(text: _typeName);
    final TextEditingController priceController = TextEditingController(text: _price > 0 ? _price.toString() : '');
    final TextEditingController customLabelController = TextEditingController(text: _customLabel);
    final TextEditingController premiumFixedController = TextEditingController(text: _premiumFixedAmount?.toString() ?? '');
    final TextEditingController premiumPercentageController = TextEditingController(text: _premiumPercentage != null ? (_premiumPercentage! * 100).toString() : '');

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(bedType == null ? 'Add Bed Type' : 'Edit Bed Type'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: typeNameController,
                    decoration: const InputDecoration(labelText: 'Type Name*'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Type name is required';
                      }
                      // Check for uniqueness if adding, or if changed when editing
                      bool isUnique = !appState.bedTypes.any((bt) => bt.typeName == value && (bedType == null || bt.typeName != bedType.typeName));
                      if (!isUnique) {
                        return 'Type name must be unique';
                      }
                      return null;
                    },
                    onSaved: (value) => _typeName = value!,
                    readOnly: bedType != null, // Type name is PK, not editable after creation
                  ),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Price*'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Price is required';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Price must be a positive number';
                      }
                      return null;
                    },
                    onSaved: (value) => _price = double.parse(value!),
                  ),
                  TextFormField(
                    controller: customLabelController,
                    decoration: const InputDecoration(labelText: 'Custom Label'),
                    onSaved: (value) => _customLabel = value,
                  ),
                  TextFormField(
                    controller: premiumFixedController,
                    decoration: const InputDecoration(labelText: 'Premium Fixed Amount'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final amount = double.tryParse(value);
                        if (amount == null || amount < 0) {
                          return 'Must be a non-negative number';
                        }
                      }
                      return null;
                    },
                    onSaved: (value) => _premiumFixedAmount = (value == null || value.isEmpty) ? null : double.parse(value),
                  ),
                  TextFormField(
                    controller: premiumPercentageController,
                    decoration: const InputDecoration(labelText: 'Premium Percentage (0-100)'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                     validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final perc = double.tryParse(value);
                        if (perc == null || perc < 0 || perc > 100) {
                          return 'Must be between 0 and 100';
                        }
                      }
                      return null;
                    },
                    onSaved: (value) {
                      if (value == null || value.isEmpty) {
                        _premiumPercentage = null;
                      } else {
                        _premiumPercentage = double.parse(value) / 100.0; // Convert to 0.0-1.0
                      }
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
                  final newBedType = BedType(
                    typeName: _typeName,
                    price: _price,
                    customLabel: _customLabel,
                    premiumFixedAmount: _premiumFixedAmount,
                    premiumPercentage: _premiumPercentage,
                  );
                  if (bedType == null) {
                    appState.addBedType(newBedType);
                  } else {
                    appState.updateBedType(newBedType);
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
