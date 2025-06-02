import 'package:flutter/material.dart';
import 'package:ziberlive/models/app_models.dart';
import 'package:ziberlive/services/data_service_mock.dart' hide NetworkSSID, DiscoveredUser;
import 'package:ziberlive/config.dart';
import 'package:ziberlive/models/network_models.dart';
import 'package:ziberlive/models/schedule_models.dart';

class AppStateProvider extends ChangeNotifier {
  final DataService _dataService = DataService();
  User? _currentUser;
  List<User> _users = [];
  List<Bill> _bills = [];
  List<Task> _tasks = [];
  List<Vote> _votes = [];
  List<Schedule> _schedules = [];
  double _treeLevel = 1.0;
  bool _isLoading = true;
  bool _isSyncing = false;
  double? _transferProgress;
  List<NetworkSSID> _ssids = [];
  List<DiscoveredUser> _discoveredUsers = [];
  bool _isPremium = false;
  bool _multiLoginEnabled = false;
  String? _networkSSID;
  bool _isTransferring = false;

  // Custom labels
  String _electricityLabel = 'Electricity';
  String _cookingLabel = 'Community Cooking';

  AppStateProvider() {
    _initializeApp();
  }

  // Initialize app state
  Future<void> _initializeApp() async {
    _isLoading = true;
    notifyListeners();

    await _dataService.init();
    await _loadData();

    _isLoading = false;
    notifyListeners();
  }

  // Load all data
  Future<void> _loadData() async {
    _currentUser = await _dataService.getCurrentUser();
    _users = await _dataService.getUsers();
    _bills = await _dataService.getBills();
    _tasks = await _dataService.getTasks();
    _votes = await _dataService.getVotes();
    _schedules = await _dataService.getSchedules();
    _treeLevel = await _dataService.getTreeLevel();

    // Initialize new properties
    _ssids = await _dataService.getNetworkSSIDs();
    _discoveredUsers = await _dataService.getDiscoveredUsers();
    _isPremium =
        (_currentUser?.credits ?? 0) > 1000; // Example premium threshold
    _multiLoginEnabled = false; // Default to false
    _networkSSID = _ssids.isNotEmpty ? _ssids.first.name : null;
    _isTransferring = false;
    _transferProgress = null;
  }

  // Refresh data
  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    await _loadData();

    _isLoading = false;
    notifyListeners();
  }

  // Start P2P sync
  Future<void> startSync() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _isTransferring = true;
    notifyListeners();

    try {
      // Simulate transfer progress updates
      for (int i = 0; i <= 100; i += 10) {
        _transferProgress = i.toDouble();
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      if (_currentUser?.isAdmin ?? false) {
        await _dataService.startAdvertising();
      } else {
        await _dataService.startDiscovery();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error starting sync: $e');
      }
    }

    await Future.delayed(const Duration(seconds: 5)); // Simulate sync time
    _isSyncing = false;
    notifyListeners();
  }

  // Export data
  Future<String> exportData() async {
    return await _dataService.exportData();
  }

  // Import data
  Future<void> importData(String jsonData) async {
    await _dataService.importData(jsonData);
    await refreshData();
  }

  // Getters
  User? get currentUser => _currentUser;
  List<User> get users => _users;
  List<Bill> get bills => _bills;
  List<Task> get tasks => _tasks;
  List<Vote> get votes => _votes;
  List<Schedule> get schedules => _schedules;
  double get treeLevel => _treeLevel;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  double? get transferProgress => _transferProgress;
  List<NetworkSSID> get ssids => _ssids;
  List<DiscoveredUser> get discoveredUsers => _discoveredUsers;
  bool get isPremium => _isPremium;
  bool get multiLoginEnabled => _multiLoginEnabled;
  String? get networkSSID => _networkSSID;
  bool get isTransferring => _isTransferring;

  // Custom labels
  String get electricityLabel => _electricityLabel;
  String get cookingLabel => _cookingLabel;

  // Setters for settings
  void setNetworkSSID(String ssid) {
    _networkSSID = ssid;
    notifyListeners();
  }

  void setPremium(bool value) {
    _isPremium = value;
    notifyListeners();
  }

  void setMultiLoginEnabled(bool value) {
    _multiLoginEnabled = value;
    notifyListeners();
  }

  void setElectricityLabel(String label) {
    _electricityLabel = label;
    notifyListeners();
  }

  void setCookingLabel(String label) {
    _cookingLabel = label;
    notifyListeners();
  }

  // Get current user bills
  List<Bill> get currentUserBills {
    if (_currentUser == null) return [];
    return _bills
        .where((bill) => bill.userIds.contains(_currentUser!.id))
        .toList();
  }

  // Get unpaid bills
  List<Bill> get unpaidBills {
    if (_currentUser == null) return [];
    return currentUserBills.where((bill) {
      final status = bill.paymentStatus[_currentUser!.id];
      return status == null || status == PaymentStatus.unpaid;
    }).toList();
  }

  // Get user tasks
  List<Task> get userTasks {
    if (_currentUser == null) return [];
    return _tasks
        .where((task) => task.assignedUserId == _currentUser!.id)
        .toList();
  }

  // Get open votes
  List<Vote> get openVotes {
    return _votes.where((vote) => vote.isVotingOpen()).toList();
  }

  // Get user schedules
  List<Schedule> get userSchedules {
    if (_currentUser == null) return [];
    return _schedules
        .where((schedule) => schedule.userId == _currentUser!.id)
        .toList();
  }

  // Add a schedule
  Future<void> addSchedule(Schedule schedule) async {
    await _dataService.saveSchedule(schedule);
    await refreshData();
  }

  // Update a schedule
  Future<void> updateSchedule(Schedule updatedSchedule) async {
    await _dataService.saveSchedule(updatedSchedule);
    await refreshData();
  }

  // Delete a schedule
  Future<void> deleteSchedule(String scheduleId) async {
    await _dataService.deleteSchedule(scheduleId);
    await refreshData();
  }

  // Check for schedule conflicts
  bool hasScheduleConflict(Schedule schedule, [String? excludeId]) {
    return _schedules.any((s) =>
        s.id != (excludeId ?? schedule.id) &&
        s.startTime.isBefore(schedule.endTime) &&
        s.endTime.isAfter(schedule.startTime) &&
        s.type == schedule.type);
  }

  // Pay a bill
  Future<void> payBill(String billId) async {
    if (_currentUser == null) return;

    await _dataService.updateBillPaymentStatus(
      billId,
      _currentUser!.id,
      PaymentStatus.paid,
    );

    // Add credits for paying bill
    await _dataService.addCreditsToUser(_currentUser!.id, 10);

    // Grow the tree for bill payment
    await _dataService.incrementTreeLevel(0.05);

    await refreshData();
  }

  // Create a new bill
  Future<void> createBill(Bill bill) async {
    await _dataService.saveBill(bill);
    await refreshData();
  }

  // Complete a task
  Future<void> completeTask(String taskId) async {
    await _dataService.completeTask(taskId);

    // Grow the tree for task completion
    await _dataService.incrementTreeLevel(0.1);

    await refreshData();
  }

  // Create a new task
  Future<void> createTask(Task task) async {
    await _dataService.saveTask(task);
    await refreshData();
  }

  // Cast a vote
  Future<void> castVote(String voteId, String optionId) async {
    if (_currentUser == null) return;

    await _dataService.castVote(voteId, _currentUser!.id, optionId);

    // Grow the tree for voting
    await _dataService.incrementTreeLevel(0.02);

    await refreshData();
  }

  // Create a new vote
  Future<void> createVote(Vote vote) async {
    await _dataService.saveVote(vote);
    await refreshData();
  }

  // Add credits to user
  Future<void> addCredits(String userId, int amount) async {
    await _dataService.addCreditsToUser(userId, amount);
    await refreshData();
  }

  // Add user
  Future<void> addUser(User user) async {
    await _dataService.saveUser(user);
    await refreshData();
  }

  // Update user
  Future<void> updateUser(User updatedUser) async {
    await _dataService.saveUser(updatedUser);

    // Update current user if needed
    if (_currentUser?.id == updatedUser.id) {
      await _dataService.saveCurrentUser(updatedUser);
    }

    await refreshData();
  }

  // Toggle user in bill splitting
  Future<void> toggleUserInBillSplitting(
      String billId, String userId, bool isExempt) async {
    final billIndex = _bills.indexWhere((bill) => bill.id == billId);
    if (billIndex == -1) return;

    final bill = _bills[billIndex];
    final exemptUsers = Map<String, bool>.from(bill.exemptUsers);
    exemptUsers[userId] = isExempt;

    final updatedBill = Bill(
      id: bill.id,
      title: bill.title,
      description: bill.description,
      amount: bill.amount,
      dueDate: bill.dueDate,
      userIds: bill.userIds,
      paymentStatus: bill.paymentStatus,
      type: bill.type,
      exemptUsers: exemptUsers,
    );

    await _dataService.saveBill(updatedBill);
    await refreshData();
  }

  // Update community tree
  Future<void> growTree(double amount) async {
    await _dataService.incrementTreeLevel(amount);
    await refreshData();
  }
}
