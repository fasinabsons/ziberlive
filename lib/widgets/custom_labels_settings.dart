import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';

class CustomLabelsSettings extends StatelessWidget {
  const CustomLabelsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    return ListView(
      children: [
        ListTile(
          title: const Text('Rename "Electricity" Bill'),
          trailing: SizedBox(
            width: 150,
            child: TextField(
              controller:
                  TextEditingController(text: appState.electricityLabel),
              onChanged: (val) => appState.setElectricityLabel(val),
            ),
          ),
        ),
        ListTile(
          title: const Text('Rename "Community Cooking"'),
          trailing: SizedBox(
            width: 150,
            child: TextField(
              controller: TextEditingController(text: appState.cookingLabel),
              onChanged: (val) => appState.setCookingLabel(val),
            ),
          ),
        ),
        // Add more customizable labels as needed
      ],
    );
  }
}
