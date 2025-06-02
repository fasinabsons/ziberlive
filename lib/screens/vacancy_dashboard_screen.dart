import 'package:flutter/material.dart';
import '../models/app_models.dart';

class VacancyDashboardScreen extends StatelessWidget {
  final List<Apartment> apartments;
  final Function(String, String, String) onToggleBedVacancy;

  const VacancyDashboardScreen({super.key, required this.apartments, required this.onToggleBedVacancy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Vacancy Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: apartments.map((apt) => Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text(apt.name, style: theme.textTheme.titleMedium),
            children: apt.rooms.map((room) => Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ExpansionTile(
                title: Text(room.name, style: theme.textTheme.titleSmall),
                children: room.beds.map((bed) => ListTile(
                  leading: Icon(
                    bed.isVacant ? Icons.bed_outlined : Icons.bed,
                    color: bed.isVacant ? Colors.green : Colors.red,
                  ),
                  title: Text('Bed: ${bed.name}'),
                  subtitle: bed.user != null
                      ? Text('Occupied by: ${bed.user!.name}')
                      : const Text('Vacant'),
                  trailing: IconButton(
                    icon: Icon(
                      bed.isVacant ? Icons.person_add_alt_1 : Icons.exit_to_app,
                      color: bed.isVacant ? Colors.blue : Colors.orange,
                    ),
                    onPressed: () => onToggleBedVacancy(apt.id, room.id, bed.id),
                  ),
                )).toList(),
              ),
            )).toList(),
          ),
        )).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('IoT Integration'),
              content: const Text('Smart bed sensor integration coming soon.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.sensors),
        label: const Text('IoT Integrate'),
      ),
    );
  }
}
