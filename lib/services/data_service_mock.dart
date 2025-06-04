import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// Hide conflicting models from app_models.dart
import '../models/app_models.dart' hide User, UserRole, Bill, BillType, PaymentStatus;

import '../models/user_model.dart'; // Import AppUser
import '../models/bed_type_model.dart';
import '../models/network_models.dart'; // Assuming this is for DiscoveredUser, NetworkSSIDModel
import '../models/schedule_models.dart'; // Assuming this is for Schedule

// Import the target Bill model and its enums
import '../models/bill_model.dart' as TargetBillModel;

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
    final users = await getUsers();
    final bedTypes = await getBedTypes();
    final bills = await getBills(); // Check for existing target bills

    if (users.isNotEmpty && bedTypes.isNotEmpty && bills.isNotEmpty) return;

    final uuid = Uuid();

    try {
      if (users.isEmpty) {
        final adminUser = AppUser(
          id: uuid.v4(), name: 'Admin User', role: 'Roommate-Admin', coins: 100,
          email: 'admin@example.com', trustScore: 100,
          subscriptions: [
            Subscription(id: uuid.v4(), name: 'Rent', type: SubscriptionType.rent),
            Subscription(id: uuid.v4(), name: 'Utilities', type: SubscriptionType.utilities),
          ],
        );
        final List<AppUser> regularUsers = [];
        for (int i = 1; i <= 3; i++) {
          regularUsers.add(AppUser(
            id: uuid.v4(), name: 'User $i', role: 'User', coins: 20 * i,
            email: 'user$i@example.com', trustScore: 70 + (i * 10),
            subscriptions: [
              Subscription(id: uuid.v4(), name: 'Rent', type: SubscriptionType.rent),
              Subscription(id: uuid.v4(), name: 'Utilities', type: SubscriptionType.utilities, isActive: i % 2 == 0),
            ],
          ));
        }
        final List<AppUser> allUsers = [adminUser, ...regularUsers];
        for (var user in allUsers) await saveUser(user);
        await saveCurrentUser(adminUser);
      }

      final allUsers = await getUsers(); // Fetch again in case they were just added

      if (bedTypes.isEmpty) {
        final sampleBedTypes = [
          BedType(typeName: 'Single', price: 300.0, customLabel: 'Standard Single Bed'),
          BedType(typeName: 'Double', price: 500.0, customLabel: 'Standard Double Bed'),
        ];
        for (var bt in sampleBedTypes) await saveBedType(bt);
      }

      if (bills.isEmpty && allUsers.isNotEmpty) { // Create bills only if users exist
        final currentDate = DateTime.now();
        final List<TargetBillModel.Bill> sampleBills = [
          TargetBillModel.Bill(
            id: uuid.v4(), name: 'Rent - ${currentDate.month}/${currentDate.year}',
            description: 'Monthly rent payment', amount: 3000.0,
            dueDate: DateTime(currentDate.year, currentDate.month, 5),
            type: TargetBillModel.BillType.rent, // Use TargetBillModel.BillType
            userIds: allUsers.map((u) => u.id).toList(),
            paymentStatus: { for (var u in allUsers) u.id : (u.id == allUsers.first.id ? TargetBillModel.PaymentStatus.paid : TargetBillModel.PaymentStatus.unpaid) },
            apartmentId: "apt1", // Example apartmentId
            incomePoolRewardOffset: 0.0,
          ),
          TargetBillModel.Bill(
            id: uuid.v4(), name: 'Electricity - ${currentDate.month}/${currentDate.year}',
            description: 'Monthly electricity bill', amount: 120.0,
            dueDate: DateTime(currentDate.year, currentDate.month, 15),
            type: TargetBillModel.BillType.utility,
            userIds: allUsers.map((u) => u.id).toList(),
            paymentStatus: { for (var u in allUsers) u.id : TargetBillModel.PaymentStatus.unpaid },
            apartmentId: "apt1",
          ),
        ];
        for (var bill in sampleBills) {
          await saveBill(bill);
        }
      }

      // Sample tasks (still using app_models.Task for now as it's not part of this refactor)
      if (allUsers.isNotEmpty && (await getTasks()).isEmpty) {
        final List<Task> tasks = [
          Task(id: uuid.v4(), title: 'Clean kitchen', description: 'Clean all kitchen surfaces', dueDate: DateTime.now().add(Duration(days: 1)), assignedUserId: allUsers[1].id, creditReward: 15),
        ];
        for (var task in tasks) await saveTask(task);
      }

      if((await getTreeLevel()) == 1.0 && users.isEmpty) { // only save tree level if it was truly first init
          await saveTreeLevel(1.0);
      }

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing sample data: $e');
      }
    }
  }

  Future<void> saveCurrentUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', user.id);
  }

  Future<AppUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('current_user_id');
    if (userId == null) return null;
    return getUser(userId);
  }

  Future<void> saveUser(AppUser user) async {
    await _storage.saveData('users', user.id, user.toMap());
  }

  Future<AppUser?> getUser(String id) async {
    final data = await _storage.getData('users', id);
    if (data == null) return null;
    return AppUser.fromMap(data);
  }

  Future<List<AppUser>> getUsers() async {
    try {
      final dataList = await _storage.getAllData('users');
      return dataList.map((data) => AppUser.fromMap(data)).toList();
    } catch (e) { if (kDebugMode) debugPrint('Error getting users: $e'); return []; }
  }

  // Bill methods now use TargetBillModel.Bill
  Future<void> saveBill(TargetBillModel.Bill bill) async {
    await _storage.saveData('bills', bill.id, bill.toJson());
  }

  Future<List<TargetBillModel.Bill>> getBills() async {
    try {
      final dataList = await _storage.getAllData('bills');
      return dataList.map((data) => TargetBillModel.Bill.fromJson(data)).toList();
    } catch (e) { if (kDebugMode) debugPrint('Error getting bills: $e'); return []; }
  }

  Future<List<TargetBillModel.Bill>> getCurrentUserBills() async {
    final user = await getCurrentUser();
    if (user == null) return [];
    final bills = await getBills();
    return bills.where((bill) => bill.userIds.contains(user.id)).toList();
  }

  Future<void> updateBillPaymentStatus(
      String billId, String userId, TargetBillModel.PaymentStatus status) async { // Use TargetBillModel.PaymentStatus
    final data = await _storage.getData('bills', billId);
    if (data == null) return;
    final bill = TargetBillModel.Bill.fromJson(data); // Use TargetBillModel.Bill
    bill.paymentStatus[userId] = status;
    // bill.lastUpdated = DateTime.now(); // TargetBillModel.Bill doesn't have lastUpdated
    await saveBill(bill);
  }

  // Task methods (still app_models.Task)
  Future<void> saveTask(Task task) async {
    await _storage.saveData('tasks', task.id, task.toJson());
  }
  Future<List<Task>> getTasks() async {
    try {
      final dataList = await _storage.getAllData('tasks');
      return dataList.map((data) => Task.fromJson(data)).toList();
    } catch (e) { if (kDebugMode) debugPrint('Error getting tasks: $e'); return []; }
  }
  Future<List<Task>> getUserTasks(String userId) async {
    final tasks = await getTasks();
    return tasks.where((task) => task.assignedUserId == userId).toList();
  }
  Future<void> completeTask(String taskId) async {
    final data = await _storage.getData('tasks', taskId);
    if (data == null) return;
    final task = Task.fromJson(data);
    task.isCompleted = true;
    // task.lastUpdated = DateTime.now(); // app_models.Task may not have this
    await saveTask(task);
    final user = await getUser(task.assignedUserId);
    if (user != null) {
      final updatedUser = user.copyWith(coins: user.coins + task.creditReward);
      await saveUser(updatedUser);
    }
  }

  // Vote methods (still app_models.Vote)
  Future<void> saveVote(Vote vote) async {
    await _storage.saveData('votes', vote.id, vote.toJson());
  }
  Future<List<Vote>> getVotes() async {
    try {
      final dataList = await _storage.getAllData('votes');
      return dataList.map((data) => Vote.fromJson(data)).toList();
    } catch (e) { if (kDebugMode) debugPrint('Error getting votes: $e'); return []; }
  }
  Future<void> castVote(String voteId, String userId, String optionId) async {
    final data = await _storage.getData('votes', voteId);
    if (data == null) return;
    final vote = Vote.fromJson(data);
    // vote.addVote(userId, optionId); // app_models.Vote might not have this
    await saveVote(vote);
    final user = await getUser(userId);
    if (user != null) {
      final updatedUser = user.copyWith(coins: user.coins + 5);
      await saveUser(updatedUser);
    }
  }

  Future<void> addCreditsToUser(String userId, int amount) async {
    final user = await getUser(userId);
    if (user == null) return;
    final updatedUser = user.copyWith(coins: user.coins + amount);
    await saveUser(updatedUser);
  }

  Future<void> saveTreeLevel(double level) async {
    await _storage.saveSetting('tree_level', level.toString());
  }
  Future<double> getTreeLevel() async {
    final levelStr = await _storage.getSetting('tree_level');
    return double.tryParse(levelStr ?? '1.0') ?? 1.0;
  }
  Future<void> incrementTreeLevel(double increment) async {
    final currentLevel = await getTreeLevel();
    await saveTreeLevel(currentLevel + increment);
  }

  Future<String> exportData() async {
    final users = await getUsers();
    final bills = await getBills(); // Now List<TargetBillModel.Bill>
    final tasks = await getTasks();
    final votes = await getVotes();
    final treeLevel = await getTreeLevel();
    final bedTypes = await getBedTypes();
    final apartments = await getApartments();
    final rooms = await getRooms();
    final beds = await getBeds();
    final data = {
      'users': users.map((u) => u.toMap()).toList(),
      'bills': bills.map((b) => b.toJson()).toList(), // TargetBillModel.Bill.toJson
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'votes': votes.map((v) => v.toJson()).toList(), // Assuming app_models.Vote.toJson
      'treeLevel': treeLevel,
      'bedTypes': bedTypes.map((bt) => bt.toJson()).toList(),
      'apartments': apartments.map((apt) => apt.toJson()).toList(),
      'rooms': rooms.map((r) => r.toJson()).toList(),
      'beds': beds.map((b) => b.toJson()).toList(),
    };
    return jsonEncode(data);
  }

  Future<void> importData(String jsonData) async {
    final data = jsonDecode(jsonData);
    await _storage.deleteAllData('users');
    await _storage.deleteAllData('bills');
    await _storage.deleteAllData('tasks');
    await _storage.deleteAllData('votes');
    await _storage.deleteAllData('bed_types');
    await _storage.deleteAllData('apartments');
    await _storage.deleteAllData('rooms');
    await _storage.deleteAllData('beds');

    for (var userJson in data['users']) await saveUser(AppUser.fromMap(userJson));
    for (var billJson in data['bills']) await saveBill(TargetBillModel.Bill.fromJson(billJson)); // TargetBillModel.Bill.fromJson
    if (data['tasks'] != null) for (var taskJson in data['tasks']) await saveTask(Task.fromJson(taskJson));
    if (data['votes'] != null) for (var voteJson in data['votes']) await saveVote(Vote.fromJson(voteJson)); // Assuming app_models.Vote.fromJson
    if (data['treeLevel'] != null) await saveTreeLevel(data['treeLevel']);
    if (data['bedTypes'] != null) for (var btJson in data['bedTypes']) await saveBedType(BedType.fromJson(btJson));
    if (data['apartments'] != null) for (var aptJson in data['apartments']) await saveApartment(Apartment.fromJson(aptJson));
    if (data['rooms'] != null) for (var roomJson in data['rooms']) await saveRoom(Room.fromJson(roomJson));
    if (data['beds'] != null) for (var bedJson in data['beds']) await saveBed(Bed.fromJson(bedJson));
  }

  Future<void> startAdvertising() async { if (kDebugMode) debugPrint('Mock P2P: Started advertising'); }
  Future<void> startDiscovery() async { if (kDebugMode) debugPrint('Mock P2P: Started discovery'); }
  Future<List<DiscoveredUser>> getDiscoveredUsers() async { return []; }
  Future<List<NetworkSSID>> getNetworkSSIDs() async { return []; }

  Future<List<BedType>> getBedTypes() async {
    try {
      final dataList = await _storage.getAllData('bed_types');
      return dataList.map((data) => BedType.fromJson(data)).toList();
    } catch (e) { if (kDebugMode) debugPrint('Error getting bed types: $e'); return []; }
  }
  Future<void> saveBedType(BedType bedType) async {
    await _storage.saveData('bed_types', bedType.typeName, bedType.toJson());
  }
  Future<void> deleteBedType(String typeName) async {
    await _storage.deleteData('bed_types', typeName);
  }

  Future<List<Apartment>> getApartments() async {
    try {
      final dataList = await _storage.getAllData('apartments');
      return dataList.map((data) => Apartment.fromJson(data)).toList();
    } catch (e) { if (kDebugMode) debugPrint('Error getting apartments: $e'); return []; }
  }
  Future<void> saveApartment(Apartment apartment) async {
    await _storage.saveData('apartments', apartment.id, apartment.toJson());
  }
  Future<void> deleteApartment(String apartmentId) async {
    await _storage.deleteData('apartments', apartmentId);
  }

  Future<List<Room>> getRooms() async {
    try {
      final dataList = await _storage.getAllData('rooms');
      return dataList.map((data) => Room.fromJson(data)).toList();
    } catch (e) { if (kDebugMode) debugPrint('Error getting rooms: $e'); return []; }
  }
  Future<void> saveRoom(Room room) async {
    await _storage.saveData('rooms', room.id, room.toJson());
  }
  Future<void> deleteRoom(String roomId) async {
    await _storage.deleteData('rooms', roomId);
  }

  Future<List<Bed>> getBeds() async {
    try {
      final dataList = await _storage.getAllData('beds');
      return dataList.map((data) => Bed.fromJson(data)).toList();
    } catch (e) { if (kDebugMode) debugPrint('Error getting beds: $e'); return []; }
  }
  Future<void> saveBed(Bed bed) async {
    await _storage.saveData('beds', bed.id, bed.toJson());
  }
  Future<void> deleteBed(String bedId) async {
    await _storage.deleteData('beds', bedId);
  }
}
