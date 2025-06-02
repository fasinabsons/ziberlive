import 'package:flutter/material.dart';
import 'package:roommate_app/ui/screens/home_screen.dart';
import 'package:roommate_app/ui/screens/bills_screen.dart';
import 'package:roommate_app/ui/screens/schedules_screen.dart';
import 'package:roommate_app/ui/screens/settings_screen.dart';
// Adjust import paths if your project structure is different or if 'roommate_app' is not the project name.

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    BillsScreen(),
    SchedulesScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Bills',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedules',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800], // Example color
        unselectedItemColor: Colors.grey, // Example color
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // To ensure all labels are visible
      ),
    );
  }
}
