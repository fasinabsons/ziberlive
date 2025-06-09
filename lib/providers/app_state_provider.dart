import 'package:flutter/material.dart';
import 'package:ziberlive/models/app_models.dart';
import 'package:ziberlive/services/data_service_mock.dart' hide NetworkSSID, DiscoveredUser;
import 'package:ziberlive/config.dart';
import 'package:ziberlive/models/network_models.dart';
import 'package:ziberlive/models/schedule_models.dart';
import 'package:ziberlive/services/ads_service.dart'; // Import AdsService
import 'package:shared_preferences/shared_preferences.dart'; // For daily ad cap

// Helper Models (defined at the end of the file or import if they get complex)
class CustomScheduleTemplate {
  String id;
  String name;
  ScheduleType type;
  Map<String, dynamic> details; // e.g., default duration, description template

  CustomScheduleTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.details,
  });

  // Basic toJson and fromJson for persistence
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.toString(),
    'details': details,
  };

  factory CustomScheduleTemplate.fromJson(Map<String, dynamic> json) => CustomScheduleTemplate(
    id: json['id'],
    name: json['name'],
    type: Schedule.parseScheduleType(json['type']), // Assuming Schedule has a static parser
    details: Map<String, dynamic>.from(json['details']),
  );
}

class CustomLaundryTemplate {
  String id;
  String name;
  Duration duration;
  // Potentially other settings like specific machine if multiple exist

  CustomLaundryTemplate({
    required this.id,
    required this.name,
    required this.duration,
  });

   Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'duration': duration.inMinutes, // Store as minutes
  };

  factory CustomLaundryTemplate.fromJson(Map<String, dynamic> json) => CustomLaundryTemplate(
    id: json['id'],
    name: json['name'],
    duration: Duration(minutes: json['duration']),
  );
}

class RotationRule {
  String id;
  ScheduleType type; // e.g., task, communityMeal
  String description; // e.g., "Weekly kitchen cleaning rotation"
  List<String> userOrder; // List of user IDs in order of rotation
  int currentTurnIndex; // Index in userOrder for whose turn it is

  RotationRule({
    required this.id,
    required this.type,
    required this.description,
    this.userOrder = const [],
    this.currentTurnIndex = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'description': description,
    'userOrder': userOrder,
    'currentTurnIndex': currentTurnIndex,
  };

  factory RotationRule.fromJson(Map<String, dynamic> json) => RotationRule(
    id: json['id'],
    type: Schedule.parseScheduleType(json['type']),
    description: json['description'],
    userOrder: List<String>.from(json['userOrder']),
    currentTurnIndex: json['currentTurnIndex'],
  );
}


class AppStateProvider extends ChangeNotifier {
  final DataService _dataService = DataService();
  final AdsService _adsService = AdsService(); // Instantiate AdsService
  User? _currentUser;
  List<User> _users = [];
  List<Bill> _bills = [];
  List<Task> _tasks = []; // This might be for a different Task model, distinct from managed Schedule tasks
  List<Vote> _votes = [];
  List<Schedule> _schedules = []; // General schedules, could include tasks/meals if not separated

  // New state properties for managed tasks, meals, laundry
  List<Schedule> _tasks_managed = [];
  List<Schedule> _communityMeals_managed = [];
  List<TimeSlot> _laundrySlots = [];
  Map<String, List<DateTime>> _taskCompletionTimestamps = {}; // userId -> list of timestamps
  Map<String, List<DateTime>> _laundryUsageTimestamps = {}; // userId -> list of timestamps
  List<CustomScheduleTemplate> _customTaskTemplates = [];
  List<CustomScheduleTemplate> _customMealTemplates = [];
  List<CustomLaundryTemplate> _customLaundryTemplates = [];
  List<RotationRule> _rotationRules = [];
  Duration _laundrySlotDuration = Duration(hours: 1); // Default

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
  int _totalCommunityTreePoints = 0;

  // Custom labels
  String _electricityLabel = 'Electricity';
  String _cookingLabel = 'Community Cooking';

  // Settings Ads Daily Cap
  int _settingsAdsWatchedToday = 0;
  String _lastSettingsAdWatchDate = "";
  static const String _prefsSettingsAdsCountKey = 'settingsAdsWatchedToday';
  static const String _prefsSettingsAdsDateKey = 'lastSettingsAdWatchDate';

  // Income Pool
  int _persistedTotalRoomIncomePoolPoints = 0;
  static const String _prefsIncomePoolTotalKey = 'persistedTotalRoomIncomePoolPoints';
  int _currentUserWeeklyIncomePoolContribution = 0;
  String _lastIncomePoolContributionResetDate = "";
  static const String _prefsWeeklyContributionKey = 'currentUserWeeklyIncomePoolContribution';
  static const String _prefsLastContributionResetDateKey = 'lastIncomePoolContributionResetDateKey';

  // Sync Status
  DateTime? _lastSuccessfulSyncTime;
  static const String _prefsLastSyncTimeKey = 'lastSuccessfulSyncTime';


  AppStateProvider() {
    _initializeApp();
    _adsService.setAppStateProvider(this);
  }

  Future<void> _initializeApp() async {
    _isLoading = true;
    notifyListeners();

    await _loadSettingsAdCapData();
    await _loadWeeklyContributionData();
    await _loadPersistedIncomePoolTotal();
    await _dataService.init();
    await _adsService.initialize();
    await _loadData();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadPersistedIncomePoolTotal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _persistedTotalRoomIncomePoolPoints = prefs.getInt(_prefsIncomePoolTotalKey) ?? 0;
    } catch (e) {
      print("Error loading persisted income pool total: $e");
    }
  }

  Future<void> _savePersistedIncomePoolTotal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsIncomePoolTotalKey, _persistedTotalRoomIncomePoolPoints);
    } catch (e) {
      print("Error saving persisted income pool total: $e");
    }
  }
  
  Future<void> _loadSettingsAdCapData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _settingsAdsWatchedToday = prefs.getInt(_prefsSettingsAdsCountKey) ?? 0;
      _lastSettingsAdWatchDate = prefs.getString(_prefsSettingsAdsDateKey) ?? "";
      _resetSettingsAdCountIfNeeded(); // Check if reset is needed on load
    } catch (e) {
      print("Error loading settings ad cap data: $e");
    }
  }


  Future<void> _loadWeeklyContributionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserWeeklyIncomePoolContribution = prefs.getInt(_prefsWeeklyContributionKey) ?? 0;
      _lastIncomePoolContributionResetDate = prefs.getString(_prefsLastContributionResetDateKey) ?? "";
      _resetWeeklyContributionIfNeeded();
    } catch (e) {
      print("Error loading weekly contribution data: $e");
    }
  }

  String _getYearAndWeek(DateTime date) {
    int weekOfYear = ((date.difference(DateTime(date.year, 1, 1)).inDays) / 7).ceil();
    if (weekOfYear == 0 && date.month == 1) weekOfYear = 1;
    else if (weekOfYear == 53 && date.month == 12 && date.weekday < 4) weekOfYear = 52;
    else if (weekOfYear == 53) weekOfYear = 52;
    if (weekOfYear == 0) weekOfYear = 1;
    return "${date.year}-${weekOfYear.toString().padLeft(2, '0')}";
  }

  void _resetWeeklyContributionIfNeeded() {
    final currentYearWeek = _getYearAndWeek(DateTime.now());
    if (_lastIncomePoolContributionResetDate != currentYearWeek) {
      _currentUserWeeklyIncomePoolContribution = 0;
      _lastIncomePoolContributionResetDate = currentYearWeek;
      _saveWeeklyContributionData();
    }
  }

  Future<void> _saveWeeklyContributionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsWeeklyContributionKey, _currentUserWeeklyIncomePoolContribution);
      await prefs.setString(_prefsLastContributionResetDateKey, _lastIncomePoolContributionResetDate);
    } catch (e) {
      print("Error saving weekly contribution data: $e");
    }
  }

  void _resetSettingsAdCountIfNeeded() {
    final todayDate = DateTime.now().toIso8601String().substring(0, 10);
    if (_lastSettingsAdWatchDate != todayDate) {
      _settingsAdsWatchedToday = 0;
      _lastSettingsAdWatchDate = todayDate;
    }
  }

  bool canWatchSettingsAd() {
    _resetSettingsAdCountIfNeeded();
    return _settingsAdsWatchedToday < kSettingsAdsDailyCap;
  }

  Future<void> recordSettingsAdWatched() async {
    _resetSettingsAdCountIfNeeded();
    if (_settingsAdsWatchedToday < kSettingsAdsDailyCap) {
      _settingsAdsWatchedToday++;
      _lastSettingsAdWatchDate = DateTime.now().toIso8601String().substring(0, 10);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_prefsSettingsAdsCountKey, _settingsAdsWatchedToday);
        await prefs.setString(_prefsSettingsAdsDateKey, _lastSettingsAdWatchDate);
      } catch (e) {
        print("Error saving settings ad cap data: $e");
      }
      notifyListeners();
    }
  }

  int get settingsAdsLeftToday => kSettingsAdsDailyCap - _settingsAdsWatchedToday;

  int get liveTotalRoomIncomePoolPoints {
    return _users.fold(0, (sum, user) => sum + user.incomePoolPoints);
  }

  int get totalRoomIncomePoolPoints => _persistedTotalRoomIncomePoolPoints;

  Future<void> _loadData() async {
    _currentUser = await _dataService.getCurrentUser();
    _users = await _dataService.getUsers();
    _bills = await _dataService.getBills();
    _tasks = await _dataService.getTasks(); // Legacy tasks if any
    _votes = await _dataService.getVotes();
    _schedules = await _dataService.getSchedules(); // General schedules
    _treeLevel = await _dataService.getTreeLevel();
    _totalCommunityTreePoints = await _dataService.getTotalCommunityTreePoints();

    // Load new managed entities
    _tasks_managed = await _dataService.getManagedTasks(); // Placeholder
    _communityMeals_managed = await _dataService.getManagedCommunityMeals(); // Placeholder
    _laundrySlots = await _dataService.getLaundrySlots(); // Placeholder
    _customTaskTemplates = await _dataService.getCustomTaskTemplates(); // Placeholder
    _customMealTemplates = await _dataService.getCustomMealTemplates(); // Placeholder
    _customLaundryTemplates = await _dataService.getCustomLaundryTemplates(); // Placeholder
    _rotationRules = await _dataService.getRotationRules(); // Placeholder
    try {
        _laundrySlotDuration = await _dataService.getLaundrySlotDuration(); // Placeholder
    } catch (e) {
        print("Error loading laundry slot duration, using default: $e");
        _laundrySlotDuration = Duration(hours:1); // fallback to default
    }


    // Load trust score related timestamps (example: from SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    _taskCompletionTimestamps = _loadTimestampsMap(prefs, 'taskCompletionTimestamps');
    _laundryUsageTimestamps = _loadTimestampsMap(prefs, 'laundryUsageTimestamps');

    _ssids = await _dataService.getNetworkSSIDs();
    _discoveredUsers = await _dataService.getDiscoveredUsers();
    _isPremium = (_currentUser?.credits ?? 0) > kCreditsPremiumThreshold;
    _multiLoginEnabled = false;
    _networkSSID = _ssids.isNotEmpty ? _ssids.first.name : null;
    _isTransferring = false;
    _transferProgress = null;
    
    await checkSubscriptionStatus(); // Ensure premium status is up-to-date
  }

  Map<String, List<DateTime>> _loadTimestampsMap(SharedPreferences prefs, String key) {
    final Map<String, List<DateTime>> map = {};
    final List<String>? userIds = prefs.getStringList('$key_userIds');
    if (userIds != null) {
      for (String userId in userIds) {
        final List<String>? timestampsStr = prefs.getStringList('$key_timestamps_$userId');
        if (timestampsStr != null) {
          map[userId] = timestampsStr.map((s) => DateTime.parse(s)).toList();
        }
      }
    }
    return map;
  }

  Future<void> _saveTimestampsMap(SharedPreferences prefs, String key, Map<String, List<DateTime>> map) async {
    await prefs.setStringList('$key_userIds', map.keys.toList());
    for (String userId in map.keys) {
      final List<String> timestampsStr = map[userId]!.map((dt) => dt.toIso8601String()).toList();
      await prefs.setStringList('$key_timestamps_$userId', timestampsStr);
    }
  }

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();
    await _loadData();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> startSync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _isTransferring = true;
    notifyListeners();
    _adsService.showRewardedAd(rewardContext: "SyncAd");
    await Future.delayed(const Duration(seconds: 1));
    _adsService.showRewardedAd(rewardContext: "SyncAd");
    await Future.delayed(const Duration(seconds: 1));
    try {
      for (int i = 0; i <= 100; i += 20) {
        _transferProgress = i.toDouble();
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 300));
      }
      if (_currentUser?.isAdmin ?? false) {
        await _dataService.startAdvertising();
      } else {
        await _dataService.startDiscovery();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error starting P2P sync: $e');
      }
    }
    await Future.delayed(const Duration(seconds: 5));
    _isSyncing = false;
    _isTransferring = false;
    _transferProgress = null;
    notifyListeners();
  }

  Future<String> exportData() async => await _dataService.exportData();
  Future<void> importData(String jsonData) async {
    await _dataService.importData(jsonData);
    await refreshData();
  }

  // Getters
  User? get currentUser => _currentUser;
  List<User> get users => _users;
  List<Bill> get bills => _bills;
  List<Task> get tasks => _tasks; // Legacy tasks
  List<Vote> get votes => _votes;
  List<Schedule> get schedules => _schedules; // General schedules

  // New Getters
  List<Schedule> get managedTasks => _tasks_managed;
  List<Schedule> get communityMeals => _communityMeals_managed;
  List<TimeSlot> get laundrySlots => _laundrySlots;
  List<CustomScheduleTemplate> get customTaskTemplates => _customTaskTemplates;
  List<CustomScheduleTemplate> get customMealTemplates => _customMealTemplates;
  List<CustomLaundryTemplate> get customLaundryTemplates => _customLaundryTemplates;
  List<RotationRule> get rotationRules => _rotationRules;
  Duration get laundrySlotDuration => _laundrySlotDuration;

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
  int get totalCommunityTreePoints => _totalCommunityTreePoints;
  String get electricityLabel => _electricityLabel;
  String get cookingLabel => _cookingLabel;

  void setNetworkSSID(String ssid) { _networkSSID = ssid; notifyListeners(); }
  void setPremium(bool value) { _isPremium = value; notifyListeners(); }
  void setMultiLoginEnabled(bool value) { _multiLoginEnabled = value; notifyListeners(); }
  void setElectricityLabel(String label) { _electricityLabel = label; notifyListeners(); }
  void setCookingLabel(String label) { _cookingLabel = label; notifyListeners(); }

  List<Bill> get currentUserBills => _currentUser == null ? [] : _bills.where((bill) => bill.userIds.contains(_currentUser!.id)).toList();
  List<Bill> get unpaidBills => _currentUser == null ? [] : currentUserBills.where((bill) => (bill.paymentStatus[_currentUser!.id] ?? PaymentStatus.unpaid) == PaymentStatus.unpaid).toList();
  List<Task> get userTasks => _currentUser == null ? [] : _tasks.where((task) => task.assignedUserId == _currentUser!.id).toList(); // Legacy
  List<Vote> get openVotes => _votes.where((vote) => vote.isVotingOpen()).toList();
  List<Schedule> get userSchedules => _currentUser == null ? [] : _schedules.where((schedule) => schedule.userId == _currentUser!.id).toList(); // General

  Future<void> addSchedule(Schedule schedule) async { await _dataService.saveSchedule(schedule); await refreshData(); }
  Future<void> updateSchedule(Schedule updatedSchedule) async { await _dataService.saveSchedule(updatedSchedule); await refreshData(); }
  Future<void> deleteSchedule(String scheduleId) async { await _dataService.deleteSchedule(scheduleId); await refreshData(); }
  bool hasScheduleConflict(Schedule schedule, [String? excludeId]) => _schedules.any((s) => s.id != (excludeId ?? schedule.id) && s.startTime.isBefore(schedule.endTime) && s.endTime.isAfter(schedule.startTime) && s.type == schedule.type);

  Future<void> payBill(String billId) async { if (_currentUser == null) return; await _dataService.updateBillPaymentStatus(billId, _currentUser!.id, PaymentStatus.paid); await _dataService.addCreditsToUser(_currentUser!.id, 10); await _dataService.incrementTreeLevel(0.05); await refreshData(); }
  Future<void> createBill(Bill bill) async { await _dataService.saveBill(bill); await refreshData(); }
  Future<void> completeTask(String taskId) async { await _dataService.completeTask(taskId); await _dataService.incrementTreeLevel(0.1); await refreshData(); } // Legacy
  Future<void> createTask(Task task) async { await _dataService.saveTask(task); await refreshData(); } // Legacy
  Future<void> castVote(String voteId, String optionId) async { if (_currentUser == null) return; await _dataService.castVote(voteId, _currentUser!.id, optionId); await _dataService.incrementTreeLevel(0.02); await refreshData(); }
  Future<void> createVote(Vote vote) async { await _dataService.saveVote(vote); await refreshData(); }
  Future<void> addCredits(String userId, int amount) async { await _dataService.addCreditsToUser(userId, amount); await refreshData(); }
  Future<void> addUser(User user) async { await _dataService.saveUser(user); await refreshData(); }
  Future<void> updateUser(User updatedUser) async { await _dataService.saveUser(updatedUser); if (_currentUser?.id == updatedUser.id) { await _dataService.saveCurrentUser(updatedUser); } await refreshData(); }
  Future<void> toggleUserInBillSplitting(String billId, String userId, bool isExempt) async { final billIndex = _bills.indexWhere((bill) => bill.id == billId); if (billIndex == -1) return; final bill = _bills[billIndex]; final exemptUsers = Map<String, bool>.from(bill.exemptUsers); exemptUsers[userId] = isExempt; final updatedBill = Bill(id: bill.id, title: bill.title, description: bill.description, amount: bill.amount, dueDate: bill.dueDate, userIds: bill.userIds, paymentStatus: bill.paymentStatus, type: bill.type, exemptUsers: exemptUsers); await _dataService.saveBill(updatedBill); await refreshData(); }
  Future<void> growTree(double amount) async { await _dataService.incrementTreeLevel(amount); await refreshData(); }

  // --- Task Management Methods ---
  Future<void> addTask(Schedule task) async {
    if (task.type != ScheduleType.task) throw ArgumentError('Schedule must be of type Task.');
    await _dataService.saveSchedule(task); // Assumes saveSchedule handles Schedule model correctly
    // _tasks_managed.add(task); // Optimistic update, or rely on refreshData
    await refreshData(); // Or selectively update _tasks_managed and notifyListeners()
  }

  Future<void> updateTask(Schedule task) async {
    if (task.type != ScheduleType.task) throw ArgumentError('Schedule must be of type Task.');
    await _dataService.saveSchedule(task);
    await refreshData();
  }

  Future<void> deleteTask(String taskId) async {
    // First, ensure it's a task if your DataService differentiates or if you want to be sure
    // Schedule? taskToDelete = _tasks_managed.firstWhere((t) => t.id == taskId, orElse: () => null);
    // if (taskToDelete == null || taskToDelete.type != ScheduleType.task) {
    //   print("Task not found or not a task type: $taskId");
    //   return;
    // }
    await _dataService.deleteSchedule(taskId); // Assumes deleteSchedule handles any Schedule type
    await refreshData();
  }

  Future<void> assignTaskToUser(String taskId, String assignUserId) async {
    Schedule? task = _tasks_managed.firstWhere((t) => t.id == taskId, orElse: () => Schedule.empty()); // Use a helper for empty Schedule if needed
    if (task.id.isEmpty) return; // Not found

    // Assuming assignedUserIds is a list. If it's a single string, adapt accordingly.
    final newAssignedUserIds = List<String>.from(task.assignedUserIds)..add(assignUserId);
    // If only one user can be assigned, replace: final newAssignedUserIds = [assignUserId];
    
    // Schedule updatedTask = task.copyWith(assignedUserIds: newAssignedUserIds); // Requires Schedule.copyWith
    // For now, create new instance manually if no copyWith
    Schedule updatedTask = Schedule(
        id: task.id, title: task.title, description: task.description,
        startTime: task.startTime, endTime: task.endTime, type: task.type,
        userId: task.userId, // Original creator/owner
        isRecurring: task.isRecurring, recurrence: task.recurrence, color: task.color,
        assignedUserIds: newAssignedUserIds, // Updated
        optedInUserIds: task.optedInUserIds, isCompleted: task.isCompleted
    );
    await updateTask(updatedTask); // This already calls refreshData
  }

  Future<void> markTaskCompleted(String taskId, String userId) async {
    Schedule? task = _tasks_managed.firstWhere((t) => t.id == taskId, orElse: () => Schedule.empty());
     if (task.id.isEmpty || !task.assignedUserIds.contains(userId)) return;

    // Schedule updatedTask = task.copyWith(isCompleted: true);
     Schedule updatedTask = Schedule(
        id: task.id, title: task.title, description: task.description,
        startTime: task.startTime, endTime: task.endTime, type: task.type,
        userId: task.userId, isRecurring: task.isRecurring, recurrence: task.recurrence, color: task.color,
        assignedUserIds: task.assignedUserIds, optedInUserIds: task.optedInUserIds, 
        isCompleted: true // Updated
    );
    await _dataService.saveSchedule(updatedTask); // Persist
    await _awardTrustPointsForActivity(userId, 'task'); // Award points
    await refreshData(); // Refresh UI
  }

  // --- Community Meal Methods ---
  Future<void> addMeal(Schedule meal) async {
    if (meal.type != ScheduleType.communityMeal) throw ArgumentError('Schedule must be of type CommunityMeal.');
    await _dataService.saveSchedule(meal);
    await refreshData();
  }

  Future<void> updateMeal(Schedule meal) async {
    if (meal.type != ScheduleType.communityMeal) throw ArgumentError('Schedule must be of type CommunityMeal.');
    await _dataService.saveSchedule(meal);
    await refreshData();
  }

  Future<void> deleteMeal(String mealId) async {
    await _dataService.deleteSchedule(mealId);
    await refreshData();
  }

  Future<void> optInToMeal(String mealId, String userId) async {
    Schedule? meal = _communityMeals_managed.firstWhere((m) => m.id == mealId, orElse: () => Schedule.empty());
    if (meal.id.isEmpty) return;
    if (meal.optedInUserIds.contains(userId)) return; // Already opted in

    final newOptedInUserIds = List<String>.from(meal.optedInUserIds)..add(userId);
    // Schedule updatedMeal = meal.copyWith(optedInUserIds: newOptedInUserIds);
    Schedule updatedMeal = Schedule(
        id: meal.id, title: meal.title, description: meal.description,
        startTime: meal.startTime, endTime: meal.endTime, type: meal.type,
        userId: meal.userId, isRecurring: meal.isRecurring, recurrence: meal.recurrence, color: meal.color,
        assignedUserIds: meal.assignedUserIds, 
        optedInUserIds: newOptedInUserIds, // Updated
        isCompleted: meal.isCompleted
    );
    await updateMeal(updatedMeal);
  }

  Future<void> optOutOfMeal(String mealId, String userId) async {
    Schedule? meal = _communityMeals_managed.firstWhere((m) => m.id == mealId, orElse: () => Schedule.empty());
    if (meal.id.isEmpty) return;
    if (!meal.optedInUserIds.contains(userId)) return; // Not opted in

    final newOptedInUserIds = List<String>.from(meal.optedInUserIds)..remove(userId);
    // Schedule updatedMeal = meal.copyWith(optedInUserIds: newOptedInUserIds);
     Schedule updatedMeal = Schedule(
        id: meal.id, title: meal.title, description: meal.description,
        startTime: meal.startTime, endTime: meal.endTime, type: meal.type,
        userId: meal.userId, isRecurring: meal.isRecurring, recurrence: meal.recurrence, color: meal.color,
        assignedUserIds: meal.assignedUserIds, 
        optedInUserIds: newOptedInUserIds, // Updated
        isCompleted: meal.isCompleted
    );
    await updateMeal(updatedMeal);
  }

  // --- Laundry Slot Methods ---
  Future<void> bookLaundrySlot(String slotId, String userId) async {
    if (!_canBookLaundrySlot(userId)) {
      throw Exception("Laundry slot limit reached for the week.");
    }
    TimeSlot? slot = _laundrySlots.firstWhere((s) => s.id == slotId, orElse: () => TimeSlot.empty()); // Requires TimeSlot.empty()
    if (slot.id.isEmpty || !slot.isAvailable) {
      throw Exception("Slot not available or does not exist.");
    }

    // TimeSlot updatedSlot = slot.copyWith(userId: userId, isAvailable: false);
    TimeSlot updatedSlot = TimeSlot(
        id: slot.id, startTime: slot.startTime, endTime: slot.endTime,
        userId: userId, // Updated
        isAvailable: false, // Updated
        adminApproved: slot.adminApproved // Assuming this field exists from previous subtask
    );

    await _dataService.saveLaundrySlot(updatedSlot); // Placeholder in DataService
    await _awardTrustPointsForActivity(userId, 'laundry');
    _laundrySlots = await _dataService.getLaundrySlots(); // Refresh specific list
    notifyListeners();
  }

  Future<void> cancelLaundrySlot(String slotId, String userId) async {
    TimeSlot? slot = _laundrySlots.firstWhere((s) => s.id == slotId, orElse: () => TimeSlot.empty());
    if (slot.id.isEmpty || slot.userId != userId) {
      throw Exception("Slot not found or not booked by this user.");
    }

    // TimeSlot updatedSlot = slot.copyWith(userId: null, isAvailable: true);
    TimeSlot updatedSlot = TimeSlot(
        id: slot.id, startTime: slot.startTime, endTime: slot.endTime,
        userId: null, // Updated
        isAvailable: true, // Updated
        adminApproved: slot.adminApproved
    );
    await _dataService.saveLaundrySlot(updatedSlot);
    _laundrySlots = await _dataService.getLaundrySlots();
    notifyListeners();
  }
  
  Future<void> requestLaundrySlotSwap(String slotIdToGiveUp, String slotIdToTake, String requestingUserId) async {
    // Placeholder: Complex logic, potentially involves admin approval or direct swap if conditions met.
    // For now, this could create a "swap request" entity or be handled by admin.
    print("Laundry slot swap requested from $slotIdToGiveUp to $slotIdToTake by $requestingUserId. (Not implemented yet)");
    // In a full implementation:
    // 1. Find both slots.
    // 2. Check ownership of slotToGiveUp.
    // 3. Check availability of slotToTake.
    // 4. Create a pending swap or execute if allowed.
    // 5. Notify users.
    notifyListeners();
  }

  Future<void> approveLaundrySlotSwap(String originalSlotId, String newSlotId, String targetUserId) async {
    // Placeholder: Admin action to finalize a swap.
    print("Laundry slot swap approved for $targetUserId from $originalSlotId to $newSlotId. (Not implemented yet)");
    // In a full implementation:
    // 1. Find both slots.
    // 2. Update userId and availability for both.
    // 3. Save both slots.
    // 4. Notify users.
    _laundrySlots = await _dataService.getLaundrySlots();
    notifyListeners();
  }


  // --- Trust Score Logic Helper Method ---
  Future<void> _awardTrustPointsForActivity(String userId, String activityType) async {
    if (_currentUser == null || _currentUser!.id != userId) {
        // Or fetch the specific user if this can be called for other users
        User? targetUser = _users.firstWhere((u) => u.id == userId, orElse: () => User.empty());
        if(targetUser.id.isEmpty) {
             print("User not found for awarding trust points: $userId");
             return;
        }
    }

    Map<String, List<DateTime>> relevantTimestampsMap;
    String prefsKeyPrefix;

    if (activityType == 'task') {
      relevantTimestampsMap = _taskCompletionTimestamps;
      prefsKeyPrefix = 'taskCompletionTimestamps';
    } else if (activityType == 'laundry') {
      relevantTimestampsMap = _laundryUsageTimestamps;
      prefsKeyPrefix = 'laundryUsageTimestamps';
    } else {
      return; // Unknown activity type
    }

    List<DateTime> userTimestamps = relevantTimestampsMap[userId] ?? [];
    DateTime now = DateTime.now();
    
    // Filter for current month
    userTimestamps = userTimestamps.where((ts) => ts.year == now.year && ts.month == now.month).toList();

    if (userTimestamps.length < 4) { // Max 4 activities per month for points (20 points / 5 per activity)
      userTimestamps.add(now);
      relevantTimestampsMap[userId] = userTimestamps;
      
      await grantAdRewardPoints(trustScorePoints: 5); // This method handles the current user
      
      // Persist updated timestamps
      final prefs = await SharedPreferences.getInstance();
      await _saveTimestampsMap(prefs, prefsKeyPrefix, relevantTimestampsMap);
      print("Awarded 5 trust points to $userId for $activityType. Month count: ${userTimestamps.length}");

    } else {
      print("Max trust points for $activityType reached for $userId this month.");
    }
    // grantAdRewardPoints calls notifyListeners if currentUser is affected.
    // If other users could be affected, ensure notifyListeners() is called appropriately.
  }

  // --- Laundry Slot Limit Helper Method ---
  bool _canBookLaundrySlot(String userId) {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Assuming Monday is start
    DateTime endOfWeek = startOfWeek.add(Duration(days: 6));

    int count = _laundrySlots.where((slot) =>
      slot.userId == userId &&
      slot.startTime.isAfter(startOfWeek.subtract(Duration(days:1))) && // Ensure correct date comparison
      slot.startTime.isBefore(endOfWeek.add(Duration(days:1)))
    ).length;
    return count < 2; // Max 2 bookings per week
  }

  // --- Customization Methods (Placeholders) ---
  Future<void> saveCustomTaskTemplate(CustomScheduleTemplate template) async {
    await _dataService.saveCustomTaskTemplate(template); // Placeholder
    _customTaskTemplates = await _dataService.getCustomTaskTemplates();
    notifyListeners();
  }
  Future<void> deleteCustomTaskTemplate(String templateId) async {
    await _dataService.deleteCustomTaskTemplate(templateId); // Placeholder
    _customTaskTemplates = await _dataService.getCustomTaskTemplates();
    notifyListeners();
  }
  Future<void> saveCustomMealTemplate(CustomScheduleTemplate template) async {
    await _dataService.saveCustomMealTemplate(template); // Placeholder
    _customMealTemplates = await _dataService.getCustomMealTemplates();
    notifyListeners();
  }
  Future<void> deleteCustomMealTemplate(String templateId) async {
    await _dataService.deleteCustomMealTemplate(templateId); // Placeholder
    _customMealTemplates = await _dataService.getCustomMealTemplates();
    notifyListeners();
  }
  Future<void> saveCustomLaundryTemplate(CustomLaundryTemplate template) async {
    await _dataService.saveCustomLaundryTemplate(template); // Placeholder
    _customLaundryTemplates = await _dataService.getCustomLaundryTemplates();
    notifyListeners();
  }
  Future<void> deleteCustomLaundryTemplate(String templateId) async {
    await _dataService.deleteCustomLaundryTemplate(templateId); // Placeholder
    _customLaundryTemplates = await _dataService.getCustomLaundryTemplates();
    notifyListeners();
  }
  Future<void> saveRotationRule(RotationRule rule) async {
    await _dataService.saveRotationRule(rule); // Placeholder
    _rotationRules = await _dataService.getRotationRules();
    notifyListeners();
  }
  Future<void> deleteRotationRule(String ruleId) async {
    await _dataService.deleteRotationRule(ruleId); // Placeholder
    _rotationRules = await _dataService.getRotationRules();
    notifyListeners();
  }
  Future<void> setLaundrySlotDuration(Duration duration) async {
    _laundrySlotDuration = duration;
    await _dataService.saveLaundrySlotDuration(duration); // Placeholder
    notifyListeners();
  }


  // --- AD REWARD METHODS ---
  Future<void> grantAdRewardPoints({
    String? userId, // Optional: if rewarding a user other than currentUser
    int trustScorePoints = 0,
    int communityTreePoints = 0,
    int incomePoolPoints = 0,
    int amazonCouponPoints = 0,
    int payPalPoints = 0,
    int coins = 0,
  }) async {
    User? userToReward = _currentUser;
    bool isCurrentUser = true;

    if (userId != null && _currentUser?.id != userId) {
      userToReward = _users.firstWhere((u) => u.id == userId, orElse: () => User.empty());
      if(userToReward.id.isEmpty) {
        print("User $userId not found for reward points.");
        return;
      }
      isCurrentUser = false;
    }
    
    if (userToReward == null || userToReward.id.isEmpty) {
       print("No user to grant rewards to.");
       return;
    }

    bool changed = false;
    User updatedUser = userToReward;

    if (trustScorePoints > 0) { updatedUser = updatedUser.copyWith(trustScore: updatedUser.trustScore + trustScorePoints); changed = true; }
    if (communityTreePoints > 0) { updatedUser = updatedUser.copyWith(communityTreePoints: updatedUser.communityTreePoints + communityTreePoints); _totalCommunityTreePoints += communityTreePoints; await _dataService.updateTotalCommunityTreePoints(_totalCommunityTreePoints); changed = true; }
    if (incomePoolPoints > 0) { updatedUser = updatedUser.copyWith(incomePoolPoints: updatedUser.incomePoolPoints + incomePoolPoints); changed = true; }
    if (amazonCouponPoints > 0) { updatedUser = updatedUser.copyWith(amazonCouponPoints: updatedUser.amazonCouponPoints + amazonCouponPoints); changed = true; }
    if (payPalPoints > 0) { updatedUser = updatedUser.copyWith(payPalPoints: updatedUser.payPalPoints + payPalPoints); changed = true; }
    if (coins > 0) { updatedUser = updatedUser.copyWith(credits: updatedUser.credits + coins); changed = true; }

    if (changed) {
      if (isCurrentUser) {
        _currentUser = updatedUser;
      } else {
        // Update the user in the _users list
        final userIndex = _users.indexWhere((u) => u.id == updatedUser.id);
        if (userIndex != -1) {
          _users[userIndex] = updatedUser;
        }
      }
      await _dataService.saveUser(updatedUser);
      notifyListeners();
    }
  }

  Future<bool> showSettingsRewardedAd() async {
    if (!canWatchSettingsAd()) {
      print("AppStateProvider: Settings ad daily cap reached.");
      return false;
    }
    _adsService.showRewardedAd(rewardContext: "SettingsAd", onRewardGranted: () async {
        await recordSettingsAdWatched(); // Important: record only after confirmed reward
        await grantAdRewardPoints(userId: _currentUser?.id, coins: kSettingsAdRewardCoins); // Grant specific reward for settings ad
        print("Settings Ad: Reward granted and watch recorded.");
    });
    return true;
  }

  // --- Income Pool Methods ---
  Future<bool> contributeToIncomePool(int points) async {
    if (_currentUser == null || points <= 0) return false;
    if (_currentUser!.incomePoolPoints < points) return false;
    _resetWeeklyContributionIfNeeded();
    _currentUser = _currentUser!.copyWith(incomePoolPoints: _currentUser!.incomePoolPoints - points);
    _persistedTotalRoomIncomePoolPoints += points;
    await _savePersistedIncomePoolTotal();
    _currentUserWeeklyIncomePoolContribution += points;
    bool trustBonusGranted = false;
    if (_currentUserWeeklyIncomePoolContribution >= 50) {
      await grantAdRewardPoints(userId: _currentUser!.id, trustScorePoints: 5);
      _currentUserWeeklyIncomePoolContribution = 0;
      trustBonusGranted = true;
    }
    await _saveWeeklyContributionData();
    if (!trustBonusGranted) { await _dataService.saveUser(_currentUser!); }
    notifyListeners();
    return true;
  }

  Future<bool> redeemIncomePoolGoal(IncomePoolGoal goal) async {
    if (!(_currentUser?.isAdmin ?? false)) return false;
    if (_persistedTotalRoomIncomePoolPoints < goal.pointsRequired) return false;
    _persistedTotalRoomIncomePoolPoints -= goal.pointsRequired;
    await _savePersistedIncomePoolTotal();
    print("Income Pool Goal Redeemed: ${goal.description}");
    notifyListeners();
    return true;
  }

  Future<bool> redeemAmazonCoupon(AmazonCouponTier tier) async {
    if (_currentUser == null || _currentUser!.amazonCouponPoints < tier.pointsRequired) return false;
    _currentUser = _currentUser!.copyWith(amazonCouponPoints: _currentUser!.amazonCouponPoints - tier.pointsRequired);
    await _dataService.saveUser(_currentUser!);
    notifyListeners();
    return true;
  }

  Future<bool> redeemPayPalCash(PayPalCashTier tier) async {
    if (_currentUser == null || _currentUser!.payPalPoints < tier.pointsRequired) return false;
    _currentUser = _currentUser!.copyWith(payPalPoints: _currentUser!.payPalPoints - tier.pointsRequired);
    await _dataService.saveUser(_currentUser!);
    notifyListeners();
    return true;
  }

  Future<bool> purchaseProduct(MicrotransactionProduct product) async {
    if (_currentUser == null) return false;
    User updatedUser = _currentUser!;
    bool changed = false;
    if (product.type == ProductType.coins && product.coinAmount != null) { updatedUser = updatedUser.copyWith(credits: updatedUser.credits + product.coinAmount!); changed = true; }
    else if (product.type == ProductType.treeSkin && product.cosmeticId != null) { if (!updatedUser.ownedTreeSkins.contains(product.cosmeticId!)) { List<String> newSkins = List.from(updatedUser.ownedTreeSkins)..add(product.cosmeticId!); updatedUser = updatedUser.copyWith(ownedTreeSkins: newSkins); changed = true; } }
    else if (product.type == ProductType.featureUnlock) { changed = true; }
    if (changed) { _currentUser = updatedUser; await _dataService.saveUser(_currentUser!); notifyListeners(); }
    return true;
  }

  Future<void> checkSubscriptionStatus() async {
    bool wasPremium = _isPremium;
    bool currentPremiumStatus = false;
    DateTime now = DateTime.now();
    if (_currentUser != null) {
      if (_currentUser!.isFreeTrialActive && _currentUser!.freeTrialExpiryDate != null && _currentUser!.freeTrialExpiryDate!.isAfter(now)) { currentPremiumStatus = true; }
      else if (_currentUser!.activeSubscriptionId != null && _currentUser!.subscriptionExpiryDate != null && _currentUser!.subscriptionExpiryDate!.isAfter(now)) { currentPremiumStatus = true; }
      else {
        if (_currentUser!.isFreeTrialActive && _currentUser!.freeTrialExpiryDate != null && !_currentUser!.freeTrialExpiryDate!.isAfter(now)) { _currentUser = _currentUser!.copyWith(isFreeTrialActive: false); await _dataService.saveUser(_currentUser!); }
        if (_currentUser!.activeSubscriptionId != null && _currentUser!.subscriptionExpiryDate != null && !_currentUser!.subscriptionExpiryDate!.isAfter(now)) { _currentUser = _currentUser!.copyWith(activeSubscriptionId: null, subscriptionExpiryDate: null); await _dataService.saveUser(_currentUser!); }
        currentPremiumStatus = false;
      }
    }
    if (_isPremium != currentPremiumStatus) { _isPremium = currentPremiumStatus; notifyListeners(); }
    else if (wasPremium != currentPremiumStatus) { notifyListeners(); }
  }

  Future<void> startFreeTrial() async {
    if (_currentUser == null || _currentUser!.isFreeTrialActive || _currentUser!.activeSubscriptionId != null) return;
    DateTime now = DateTime.now(); DateTime expiryDate = now.add(kFreeTrialDuration);
    _currentUser = _currentUser!.copyWith(isFreeTrialActive: true, freeTrialExpiryDate: expiryDate);
    await _dataService.saveUser(_currentUser!); await checkSubscriptionStatus();
  }

  Future<void> subscribeToPlan(SubscriptionPlan plan) async {
    if (_currentUser == null) return;
    DateTime now = DateTime.now(); DateTime expiryDate = now.add(plan.duration);
    _currentUser = _currentUser!.copyWith(activeSubscriptionId: plan.id, subscriptionExpiryDate: expiryDate, isFreeTrialActive: false, freeTrialExpiryDate: null);
    await _dataService.saveUser(_currentUser!); await checkSubscriptionStatus();
  }

  Future<void> cancelSubscription() async {
    if (_currentUser == null || _currentUser!.activeSubscriptionId == null) return;
    _currentUser = _currentUser!.copyWith(activeSubscriptionId: null, subscriptionExpiryDate: null);
    await _dataService.saveUser(_currentUser!); await checkSubscriptionStatus();
  }
}

// Ensure Schedule and TimeSlot have .empty() constructors or similar for robust firstWhereOrElse
// Example for Schedule, assuming it's in schedule_models.dart and you can modify it:
// factory Schedule.empty() => Schedule(id: '', title: '', startTime: DateTime(0), endTime: DateTime(0), type: ScheduleType.other, userId: '', color: Colors.transparent);
// Example for TimeSlot:
// factory TimeSlot.empty() => TimeSlot(id: '', startTime: TimeOfDay(hour:0, minute:0), endTime: TimeOfDay(hour:0, minute:0));
// These are needed for the orElse clauses to avoid null issues if items aren't found.
// Actual implementation of .empty() should match required fields.
// The Schedule.parseScheduleType is assumed to exist for CustomScheduleTemplate.fromJson.
// If Schedule.parseScheduleType is not static or accessible, CustomScheduleTemplate needs adjustment.
// For now, I've added a static method to Schedule in the previous model changes.
// The User.empty() is also assumed to exist.
// The AdsService onRewardGranted callback signature in showRewardedAd is hypothetical for cleaner integration.
// The kSettingsAdRewardCoins constant would need to be defined, e.g., in config.dart.

// Placeholder for DataService methods if they don't exist yet.
// These would be added to DataServiceMock in a subsequent step:
// Future<List<Schedule>> getManagedTasks();
// Future<List<Schedule>> getManagedCommunityMeals();
// Future<List<TimeSlot>> getLaundrySlots();
// Future<void> saveLaundrySlot(TimeSlot slot);
// Future<List<CustomScheduleTemplate>> getCustomTaskTemplates();
// Future<void> saveCustomTaskTemplate(CustomScheduleTemplate template);
// Future<void> deleteCustomTaskTemplate(String templateId);
// ... and so on for other custom templates and rotation rules.
// Future<Duration> getLaundrySlotDuration();
// Future<void> saveLaundrySlotDuration(Duration duration);
// Future<void> updateTotalCommunityTreePoints(int points);

// Note: The Schedule model was updated in a previous step to include assignedUserIds, optedInUserIds, isCompleted.
// The TimeSlot model was updated for adminApproved.
// This code assumes those model changes are in place.
// The User model's copyWith and point fields (trustScore, etc.) are assumed from context.
// The Schedule.empty() and TimeSlot.empty() are assumed to be added to their respective model files.
// If Schedule.copyWith is not available, manual instantiation is used as a fallback.
// The User.empty() is also used and assumed.
// Helper models are defined at the top for now.
// `kSettingsAdRewardCoins` needs to be defined (e.g., in `config.dart`).
// `Schedule.parseScheduleType` is used by `CustomScheduleTemplate.fromJson`.

// Final check on the grantAdRewardPoints method to allow rewarding specific users not just _currentUser.
// Added an optional userId parameter.
// Added a callback to _adsService.showRewardedAd for settings ad reward to ensure atomicity of reward and cap recording.
// Corrected _awardTrustPointsForActivity to handle _currentUser correctly when it's the target.
// Corrected _canBookLaundrySlot date comparisons.
// Added loadSettingsAdCapData to _initializeApp.
// Added helper Schedule.parseScheduleType to CustomScheduleTemplate.fromJson.
// Added fallback for laundrySlotDuration loading.
