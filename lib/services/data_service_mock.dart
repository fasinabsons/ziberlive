import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/app_models.dart';
import '../models/network_models.dart';
import 'local_storage_service.dart';
import 'package:flutter/foundation.dart';

// Mock implementation to avoid nearby_connections package issues
class DataService {
  // Singleton pattern
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  // Storage service
  final LocalStorageService _storage = LocalStorageService();

  // Initialize data service
  Future<void> init() async {
    await _storage.init();
    await _initSampleData();
  }

  // Initialize with sample data if database is empty
  Future<void> _initSampleData() async {
    // Check if we already have data
    final users = await getUsers();
    if (users.isNotEmpty) return;

    try {
      // Create sample users
      final uuid = Uuid();

      // Create sample admin user
      final adminUser = User(
        id: uuid.v4(),
        name: 'Admin User',
        role: UserRole.roommateAdmin,
        credits: 100,
        subscriptions: [
          Subscription(
            id: uuid.v4(),
            name: 'Rent',
            type: SubscriptionType.rent,
          ),
          Subscription(
            id: uuid.v4(),
            name: 'Utilities',
            type: SubscriptionType.utilities,
          ),
          Subscription(
            id: uuid.v4(),
            name: 'Community Meals',
            type: SubscriptionType.communityMeals,
          ),
          Subscription(
            id: uuid.v4(),
            name: 'Drinking Water',
            type: SubscriptionType.drinkingWater,
          ),
        ],
      );

      // Create sample regular users
      final List<User> regularUsers = [];
      for (int i = 1; i <= 3; i++) {
        regularUsers.add(User(
          id: uuid.v4(),
          name: 'User $i',
          role: UserRole.user,
          credits: 20 * i,
          subscriptions: [
            Subscription(
              id: uuid.v4(),
              name: 'Rent',
              type: SubscriptionType.rent,
            ),
            Subscription(
              id: uuid.v4(),
              name: 'Utilities',
              type: SubscriptionType.utilities,
            ),
            Subscription(
              id: uuid.v4(),
              name: 'Community Meals',
              type: SubscriptionType.communityMeals,
              isActive: i % 2 == 0,
            ),
            Subscription(
              id: uuid.v4(),
              name: 'Drinking Water',
              type: SubscriptionType.drinkingWater,
              isActive: i % 3 == 0,
            ),
          ],
        ));
      }

      // Save all users
      final allUsers = [adminUser, ...regularUsers];
      for (var user in allUsers) {
        await saveUser(user);
      }

      // Save the admin as current user
      await saveCurrentUser(adminUser);

      // Create sample bills
      final currentDate = DateTime.now();
      final List<Bill> bills = [
        Bill(
          id: uuid.v4(),
          title: 'Rent - ${currentDate.month}/${currentDate.year}',
          description: 'Monthly rent payment',
          amount: 3000.0,
          dueDate: DateTime(currentDate.year, currentDate.month, 5),
          type: BillType.rent,
          userIds: allUsers.map((u) => u.id).toList(),
          paymentStatus: {
            adminUser.id: PaymentStatus.paid,
            regularUsers[0].id: PaymentStatus.unpaid,
            regularUsers[1].id: PaymentStatus.pending,
            regularUsers[2].id: PaymentStatus.unpaid,
          },
        ),
        Bill(
          id: uuid.v4(),
          title: 'Electricity - ${currentDate.month}/${currentDate.year}',
          description: 'Monthly electricity bill',
          amount: 120.0,
          dueDate: DateTime(currentDate.year, currentDate.month, 15),
          type: BillType.utility,
          userIds: allUsers.map((u) => u.id).toList(),
          paymentStatus: {
            adminUser.id: PaymentStatus.paid,
            regularUsers[0].id: PaymentStatus.paid,
            regularUsers[1].id: PaymentStatus.unpaid,
            regularUsers[2].id: PaymentStatus.unpaid,
          },
        ),
        Bill(
          id: uuid.v4(),
          title: 'Community Meals - ${currentDate.month}/${currentDate.year}',
          description: 'Monthly community meal expenses',
          amount: 500.0,
          dueDate: DateTime(currentDate.year, currentDate.month, 10),
          type: BillType.communityMeals,
          userIds: allUsers
              .where((u) => u.hasSubscription(SubscriptionType.communityMeals))
              .map((u) => u.id)
              .toList(),
          paymentStatus: {
            adminUser.id: PaymentStatus.paid,
            regularUsers[1].id: PaymentStatus.paid,
          },
        ),
        Bill(
          id: uuid.v4(),
          title: 'Drinking Water - ${currentDate.month}/${currentDate.year}',
          description: 'Monthly drinking water expenses',
          amount: 100.0,
          dueDate: DateTime(currentDate.year, currentDate.month, 7),
          type: BillType.drinkingWater,
          userIds: allUsers
              .where((u) => u.hasSubscription(SubscriptionType.drinkingWater))
              .map((u) => u.id)
              .toList(),
          paymentStatus: {
            adminUser.id: PaymentStatus.paid,
            regularUsers[2].id: PaymentStatus.unpaid,
          },
        ),
      ];

      // Save all bills
      for (var bill in bills) {
        await saveBill(bill);
      }

      // Create sample tasks
      final List<Task> tasks = [
        Task(
          id: uuid.v4(),
          title: 'Clean kitchen',
          description: 'Clean all kitchen surfaces and take out trash',
          dueDate: DateTime.now().add(Duration(days: 1)),
          assignedUserId: regularUsers[0].id,
          creditReward: 15,
        ),
        Task(
          id: uuid.v4(),
          title: 'Mop hallway',
          description: 'Mop the common hallway area',
          dueDate: DateTime.now().add(Duration(days: 2)),
          assignedUserId: regularUsers[1].id,
          creditReward: 10,
        ),
        Task(
          id: uuid.v4(),
          title: 'Cook community dinner',
          description: 'Prepare vegetarian dinner for 4 people',
          dueDate: DateTime.now().add(Duration(hours: 6)),
          assignedUserId: adminUser.id,
          creditReward: 20,
          isCompleted: true,
        ),
      ];

      // Save all tasks
      for (var task in tasks) {
        await saveTask(task);
      }

      // Create sample votes
      final List<Vote> votes = [
        Vote(
          id: uuid.v4(),
          title: 'Weekend dinner menu',
          description:
              'What should we cook for this weekend\'s community dinner?',
          options: [
            VoteOption(id: uuid.v4(), text: 'Pizza', count: 2),
            VoteOption(id: uuid.v4(), text: 'Pasta', count: 1),
            VoteOption(id: uuid.v4(), text: 'Tacos', count: 0),
          ],
          deadline: DateTime.now().add(Duration(days: 1)),
          userVotes: {
            adminUser.id: '0', // First option
            regularUsers[0].id: '0', // First option
            regularUsers[1].id: '1', // Second option
          },
          isAnonymous: false,
        ),
        Vote(
          id: uuid.v4(),
          title: 'New furniture',
          description: 'Should we buy a new couch for the common area?',
          options: [
            VoteOption(id: uuid.v4(), text: 'Yes', count: 2),
            VoteOption(id: uuid.v4(), text: 'No', count: 1),
            VoteOption(id: uuid.v4(), text: 'Maybe later', count: 1),
          ],
          deadline: DateTime.now().add(Duration(days: 2)),
          userVotes: {
            adminUser.id: '0', // First option
            regularUsers[0].id: '0', // First option
            regularUsers[1].id: '1', // Second option
            regularUsers[2].id: '2', // Third option
          },
          isAnonymous: false,
        ),
      ];

      // Save all votes
      for (var vote in votes) {
        await saveVote(vote);
      }

      // Save initial tree level
      await saveTreeLevel(1.0);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing sample data: $e');
      }
    }
  }

  // Save current user
  Future<void> saveCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', user.id);
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('current_user_id');
    if (userId == null) return null;
    return getUser(userId);
  }

  // Save a user
  Future<void> saveUser(User user) async {
    await _storage.saveData('users', user.id, user.toJson());
  }

  // Get a user by ID
  Future<User?> getUser(String id) async {
    final data = await _storage.getData('users', id);
    if (data == null) return null;
    return User.fromJson(data);
  }

  // Get all users
  Future<List<User>> getUsers() async {
    try {
      final dataList = await _storage.getAllData('users');
      return dataList.map((data) => User.fromJson(data)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting users: $e');
      }
      return [];
    }
  }

  // Save a bill
  Future<void> saveBill(Bill bill) async {
    await _storage.saveData('bills', bill.id, bill.toJson());
  }

  // Get all bills
  Future<List<Bill>> getBills() async {
    try {
      final dataList = await _storage.getAllData('bills');
      return dataList.map((data) => Bill.fromJson(data)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting bills: $e');
      }
      return [];
    }
  }

  // Get current user's bills
  Future<List<Bill>> getCurrentUserBills() async {
    final user = await getCurrentUser();
    if (user == null) return [];

    final bills = await getBills();
    return bills.where((bill) => bill.userIds.contains(user.id)).toList();
  }

  // Update bill payment status
  Future<void> updateBillPaymentStatus(
      String billId, String userId, PaymentStatus status) async {
    final data = await _storage.getData('bills', billId);
    if (data == null) return;

    final bill = Bill.fromJson(data);
    bill.paymentStatus[userId] = status;
    bill.lastUpdated = DateTime.now();

    await saveBill(bill);
  }

  // Save a task
  Future<void> saveTask(Task task) async {
    await _storage.saveData('tasks', task.id, task.toJson());
  }

  // Get all tasks
  Future<List<Task>> getTasks() async {
    try {
      final dataList = await _storage.getAllData('tasks');
      return dataList.map((data) => Task.fromJson(data)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting tasks: $e');
      }
      return [];
    }
  }

  // Get tasks for a user
  Future<List<Task>> getUserTasks(String userId) async {
    final tasks = await getTasks();
    return tasks.where((task) => task.assignedUserId == userId).toList();
  }

  // Complete a task
  Future<void> completeTask(String taskId) async {
    final data = await _storage.getData('tasks', taskId);
    if (data == null) return;

    final task = Task.fromJson(data);
    task.isCompleted = true;
    task.lastUpdated = DateTime.now();

    await saveTask(task);

    // Award credits to the user
    final user = await getUser(task.assignedUserId);
    if (user != null) {
      user.addCredits(task.creditReward);
      await saveUser(user);
    }
  }

  // Save a vote
  Future<void> saveVote(Vote vote) async {
    await _storage.saveData('votes', vote.id, vote.toJson());
  }

  // Get all votes
  Future<List<Vote>> getVotes() async {
    try {
      final dataList = await _storage.getAllData('votes');
      return dataList.map((data) => Vote.fromJson(data)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting votes: $e');
      }
      return [];
    }
  }

  // Cast a vote
  Future<void> castVote(String voteId, String userId, String optionId) async {
    final data = await _storage.getData('votes', voteId);
    if (data == null) return;

    final vote = Vote.fromJson(data);
    vote.addVote(userId, optionId);

    await saveVote(vote);

    // Award credits for voting
    final user = await getUser(userId);
    if (user != null) {
      user.addCredits(5); // 5 credits for voting
      await saveUser(user);
    }
  }

  // Add credits to user
  Future<void> addCreditsToUser(String userId, int amount) async {
    final user = await getUser(userId);
    if (user == null) return;

    user.addCredits(amount);
    await saveUser(user);
  }

  // Save tree level
  Future<void> saveTreeLevel(double level) async {
    await _storage.saveSetting('tree_level', level.toString());
  }

  // Get tree level
  Future<double> getTreeLevel() async {
    final levelStr = await _storage.getSetting('tree_level');
    return double.tryParse(levelStr ?? '1.0') ?? 1.0;
  }

  // Increment tree level
  Future<void> incrementTreeLevel(double increment) async {
    final currentLevel = await getTreeLevel();
    await saveTreeLevel(currentLevel + increment);
  }

  // Export data as JSON
  Future<String> exportData() async {
    final users = await getUsers();
    final bills = await getBills();
    final tasks = await getTasks();
    final votes = await getVotes();
    final treeLevel = await getTreeLevel();

    final data = {
      'users': users.map((u) => u.toJson()).toList(),
      'bills': bills.map((b) => b.toJson()).toList(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'votes': votes.map((v) => v.toJson()).toList(),
      'treeLevel': treeLevel,
    };

    return jsonEncode(data);
  }

  // Import data from JSON
  Future<void> importData(String jsonData) async {
    final data = jsonDecode(jsonData);

    // Clear existing data
    await _storage.deleteAllData('users');
    await _storage.deleteAllData('bills');
    await _storage.deleteAllData('tasks');
    await _storage.deleteAllData('votes');

    // Import users
    for (var userJson in data['users']) {
      final user = User.fromJson(userJson);
      await saveUser(user);
    }

    // Import bills
    for (var billJson in data['bills']) {
      final bill = Bill.fromJson(billJson);
      await saveBill(bill);
    }

    // Import tasks
    for (var taskJson in data['tasks']) {
      final task = Task.fromJson(taskJson);
      await saveTask(task);
    }

    // Import votes
    for (var voteJson in data['votes']) {
      final vote = Vote.fromJson(voteJson);
      await saveVote(vote);
    }

    // Import tree level
    if (data['treeLevel'] != null) {
      await saveTreeLevel(data['treeLevel']);
    }
  }

  // P2P connection methods - simplified stubs
  Future<void> startAdvertising() async {
    if (kDebugMode) {
      debugPrint('Mock P2P: Started advertising');
    }
  }

  Future<void> startDiscovery() async {
    if (kDebugMode) {
      debugPrint('Mock P2P: Started discovery');
    }
  }

  // Get discovered users (mock)
  Future<List<DiscoveredUser>> getDiscoveredUsers() async {
    return [
      DiscoveredUserModel(
        id: const Uuid().v4(),
        name: 'Device 1',
        deviceId: const Uuid().v4(),
        isAddedToSystem: false,
      ),
      DiscoveredUserModel(
        id: const Uuid().v4(),
        name: 'Device 2',
        deviceId: const Uuid().v4(),
        isAddedToSystem: false,
      ),
    ];
  }
  
  // Get network SSIDs (mock)
  Future<List<NetworkSSID>> getNetworkSSIDs() async {
    return [
      NetworkSSIDModel(
        id: const Uuid().v4(),
        name: 'Home Wi-Fi',
        password: '********',
      ),
      NetworkSSIDModel(
        id: const Uuid().v4(),
        name: 'Guest Wi-Fi',
        password: '',
      ),
    ];
  }
}
