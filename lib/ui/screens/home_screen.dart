import 'package:flutter/material.dart';
import 'package:roommate_app/services/user_service.dart'; // Adjust path
import 'package:roommate_app/models/user_model.dart'; // Adjust path

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService();
  AppUser? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    // Ensure a user exists and is loaded. This might be called at app startup in main.dart ideally.
    await _userService.ensureLocalUserExists(defaultName: "Home User", defaultRole: "Roommate");
    _currentUser = _userService.currentUser;
    setState(() => _isLoading = false);
  }

  Future<void> _simulateScoreUpdate() async {
    if (_currentUser?.id != null) {
      await _userService.updateUserScoreAndCoins(_currentUser!.id!, trustScoreDelta: 5, coinsDelta: 2);
      // Reload data to reflect changes
      await _loadUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Welcome, ${_currentUser?.name ?? "User"}!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Trust Score: ${_currentUser?.trustScore ?? 0}/100',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Coins: ${_currentUser?.coins ?? 0}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _simulateScoreUpdate,
                      child: const Text('Simulate Task (+5 Score, +2 Coins)'),
                    ),
                    const SizedBox(height: 20),
                    // Add a button to refresh data manually if needed
                    ElevatedButton(
                      onPressed: _loadUserData,
                      child: const Text('Refresh User Data'),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
