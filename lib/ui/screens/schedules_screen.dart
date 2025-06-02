import 'package:flutter/material.dart';

class SchedulesScreen extends StatelessWidget {
  const SchedulesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedules'),
      ),
      body: const Center(
        child: Text('Schedules Screen - Placeholder'),
      ),
    );
  }
}
