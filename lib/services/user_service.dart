import 'dart:math'; // For generating a simple unique ID if needed, though DB autoincrement is preferred.
import 'package:roommate_app/models/user_model.dart'; // Adjust path if necessary
import 'package:roommate_app/database/database_helper.dart'; // Adjust path if necessary

class UserService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  Future<void> loadCurrentUser() async {
    // In a real app, you might store the current user's ID in shared_preferences
    // For simplicity, we'll try to load the first user found in the database.
    // This assumes a single-user-per-device model for the local user.
    final users = await _dbHelper.readAllUsers();
    if (users.isNotEmpty) {
      // Assuming the first user in the DB is the local user.
      // In a multi-profile scenario on one device (not the P2P users), this would need refinement.
      _currentUser = AppUser.fromMap(users.first);
      print('Current user loaded: ${_currentUser!.name} (ID: ${_currentUser!.id})');
    } else {
      print('No local user found.');
      // Optionally, trigger user creation if no user exists
      // await createNewUser(name: 'Default User', role: 'Roommate');
    }
  }

  Future<AppUser?> getUserById(int id) async {
    final userMap = await _dbHelper.readUser(id);
    if (userMap != null) {
      return AppUser.fromMap(userMap);
    }
    return null;
  }

  Future<AppUser> createNewUser({required String name, String? bed, required String role, int initialTrustScore = 50, int initialCoins = 0}) async {
    // For a truly unique ID across the P2P network, a UUID/GUID is better.
    // But for local DB, AUTOINCREMENT ID from sqflite is fine.
    // The 'id' in AppUser.toMap() will be null here, and sqflite will assign one.
    final newUser = AppUser(
      name: name,
      bed: bed,
      role: role, // e.g., 'Roommate' or 'Roommate-Admin'
      trustScore: initialTrustScore,
      coins: initialCoins,
    );

    final Map<String, dynamic> userMap = newUser.toMap();
    // Remove id from map if it's null, as sqflite handles auto-increment
    userMap.remove('id');

    final id = await _dbHelper.createUser(userMap);
    _currentUser = newUser.copyWith(id: id); // Update current user with the assigned ID.

    print('New user created: ${_currentUser!.name} (ID: ${_currentUser!.id})');
    return _currentUser!;
  }

  Future<bool> localUserExists() async {
    final users = await _dbHelper.readAllUsers();
    return users.isNotEmpty;
  }

  Future<void> ensureLocalUserExists({String defaultName = "My Device User", String defaultRole = "Roommate"}) async {
    if (!await localUserExists()) {
      print("No local user found. Creating one.");
      await createNewUser(name: defaultName, role: defaultRole);
    } else {
      await loadCurrentUser(); // Load if exists
    }
  }

  // In a real app, you might call ensureLocalUserExists() during app startup.
  // Then, the P2PService can get the user ID from UserService.currentUser.id.toString()

  Future<void> updateUserScoreAndCoins(int userId, {int? trustScoreDelta, int? coinsDelta}) async {
    final userMap = await _dbHelper.readUser(userId);
    if (userMap == null) {
      print("User not found with id $userId");
      return;
    }

    AppUser user = AppUser.fromMap(userMap);
    int newTrustScore = user.trustScore;
    int newCoins = user.coins;

    if (trustScoreDelta != null) {
      newTrustScore = (user.trustScore + trustScoreDelta).clamp(0, 100); // Assuming Trust Score is 0-100
    }
    if (coinsDelta != null) {
      newCoins = (user.coins + coinsDelta).clamp(0, 100000); // Assuming a max coin limit, or remove clamp if not needed
    }

    AppUser updatedUser = user.copyWith(
      trustScore: newTrustScore,
      coins: newCoins,
    );

    await _dbHelper.updateUser(updatedUser.toMap());
    print("User $userId updated: Trust Score = ${updatedUser.trustScore}, Coins = ${updatedUser.coins}");

    if (_currentUser?.id == userId) {
      _currentUser = updatedUser;
    }
  }
}
