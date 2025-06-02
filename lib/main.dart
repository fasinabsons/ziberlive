import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart';
import 'package:ziberlive/theme.dart';
import 'package:ziberlive/providers/app_state_provider.dart';
import 'package:ziberlive/screens/home_screen.dart';
import 'package:ziberlive/screens/bill_screen.dart';
import 'package:ziberlive/screens/community_screen.dart';
import 'package:ziberlive/screens/task_screen.dart';
import 'package:ziberlive/screens/profile_screen.dart';
import 'package:ziberlive/screens/schedule_screen.dart';
import 'package:ziberlive/config.dart' hide kDebugMode;
import 'package:ziberlive/services/web_sqlite_init.dart';

// Conditionally import dart:io

// Firebase imports
import 'package:ziberlive/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize web SQLite stubs if running on web
  if (kIsWeb) {
    WebSqliteInit.initialize();
  }

  // Initialize Firebase if needed
  if (kUseFirebase) {
    try {
      await FirebaseService.initializeApp();
      if (kDebugMode) {
        // Using debug flag from config to control logging
        debugPrint('Firebase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing Firebase: $e');
      }
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppStateProvider(),
      child: MaterialApp(
        title: kAppName,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: kShowDebugBanner,
        home: const MainScreen(),
        // Define named routes for navigation
        routes: {
          '/tasks': (context) => const TaskScreen(),
          '/bills': (context) => const BillScreen(),
          '/community': (context) => const CommunityScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/schedule': (context) => const ScheduleScreen(),
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // List of screens
  final List<Widget> _screens = [
    const HomeScreen(),
    const BillScreen(),
    const CommunityScreen(),
    const TaskScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    // Show loading screen while initializing
    if (appState.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator()
                  .animate()
                  .scaleXY(
                      duration: kAnimationDuration,
                      curve: Curves.easeOut,
                      begin: 0.6,
                      end: 1.0)
                  .fadeIn(duration: kAnimationDuration),
              const SizedBox(height: 20),
              Text(
                'Loading $kAppName...',
                style: Theme.of(context).textTheme.titleLarge,
              ).animate().fadeIn(
                  delay: const Duration(milliseconds: 300),
                  duration: kAnimationDuration),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.outline,
        // Show tabs based on user role
        items: _getNavigationItems(appState),
      ).animate().slideY(
            begin: 1.0,
            end: 0.0,
            duration: kAnimationDuration,
            curve: Curves.easeOutQuad,
          ),
    );
  }

  // Get navigation items based on user role
  List<BottomNavigationBarItem> _getNavigationItems(AppStateProvider appState) {
    // Base navigation items all users can see
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
    ];

    // Add Bill tab if user has bill access
    items.add(const BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long_rounded),
      label: 'Bills',
    ));

    // Add Community tab
    items.add(const BottomNavigationBarItem(
      icon: Icon(Icons.nature_people_rounded),
      label: 'Community',
    ));

    // Add Task tab if user has tasks
    items.add(const BottomNavigationBarItem(
      icon: Icon(Icons.check_circle_outline_rounded),
      label: 'Tasks',
    ));

    // Add Profile tab
    items.add(const BottomNavigationBarItem(
      icon: Icon(Icons.person_rounded),
      label: 'Profile',
    ));

    return items;
  }
}
