import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:ziberlive/models/app_models.dart';
import 'package:ziberlive/services/data_service_mock.dart' hide NetworkSSID, DiscoveredUser;
import 'package:flutter/material.dart';
import 'package:ziberlive/models/app_models.dart';
import 'package:ziberlive/services/data_service_mock.dart' hide NetworkSSID, DiscoveredUser;
import 'package:ziberlive/config.dart';
import 'package:ziberlive/models/network_models.dart';
import 'package:ziberlive/models/schedule_models.dart';
import 'package:ziberlive/services/ads_service.dart'; // Import AdsService
import 'package:shared_preferences/shared_preferences.dart'; // For daily ad cap

class AppStateProvider extends ChangeNotifier {
  final DataService _dataService = DataService();
  final AdsService _adsService = AdsService(); // Instantiate AdsService
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
  int _totalCommunityTreePoints = 0; // New global community tree points

  // Custom labels
  String _electricityLabel = 'Electricity';
  String _cookingLabel = 'Community Cooking';

  // Settings Ads Daily Cap
  int _settingsAdsWatchedToday = 0;
  String _lastSettingsAdWatchDate = "";
  static const String _prefsSettingsAdsCountKey = 'settingsAdsWatchedToday';
  static const String _prefsSettingsAdsDateKey = 'lastSettingsAdWatchDate';


  AppStateProvider() {
    _initializeApp();
    _adsService.setAppStateProvider(this); // Provide AppStateProvider to AdsService
  }

  // Initialize app state
  Future<void> _initializeApp() async {
    _isLoading = true;
    notifyListeners();

    await _loadSettingsAdCapData();
    await _loadWeeklyContributionData();
    await _loadPersistedIncomePoolTotal();
    await _dataService.init();
    await _adsService.initialize();
    await _loadData(); // Loads users, which updates liveTotalRoomIncomePoolPoints implicitly

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

  Future<void> _loadWeeklyContributionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserWeeklyIncomePoolContribution = prefs.getInt(_prefsWeeklyContributionKey) ?? 0;
      _lastIncomePoolContributionResetDate = prefs.getString(_prefsLastContributionResetDateKey) ?? "";
      _resetWeeklyContributionIfNeeded(); // Check if reset is needed on load
    } catch (e) {
      print("Error loading weekly contribution data: $e");
    }
  }

  String _getYearAndWeek(DateTime date) {
    // Simple way to get YYYY-WW format. Week number calculation can be complex.
    // This basic version might have edge cases around year changes.
    // A more robust solution would use a date utility package.
    int weekOfYear = ((date.difference(DateTime(date.year, 1, 1)).inDays) / 7).ceil();
    // Ensure week is at least 1, and handle edge case for day 365 falling into week 1 of next year.
    if (weekOfYear == 0 && date.month == 1) weekOfYear = 1;
    else if (weekOfYear == 53 && date.month == 12 && date.weekday < 4) weekOfYear = 52; // if Dec 31 is Mon,Tue,Wed it's week 52/53 of current year
    else if (weekOfYear == 53) weekOfYear = 52; // most years only have 52 weeks for this simple logic
    if (weekOfYear == 0) weekOfYear = 1; // if somehow still 0, default to 1

    return "${date.year}-${weekOfYear.toString().padLeft(2, '0')}";
  }

  void _resetWeeklyContributionIfNeeded() {
    final currentYearWeek = _getYearAndWeek(DateTime.now());
    if (_lastIncomePoolContributionResetDate != currentYearWeek) {
      _currentUserWeeklyIncomePoolContribution = 0;
      _lastIncomePoolContributionResetDate = currentYearWeek;
      // Persist this reset immediately
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
    final todayDate = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    if (_lastSettingsAdWatchDate != todayDate) {
      _settingsAdsWatchedToday = 0;
      _lastSettingsAdWatchDate = todayDate; // Update to today for future checks
      // Persist this reset immediately (or on next ad watch)
      // For simplicity, we can let recordSettingsAdWatched handle persistence of the reset date.
    }
  }

  bool canWatchSettingsAd() {
    _resetSettingsAdCountIfNeeded(); // Ensure data is fresh before checking
    return _settingsAdsWatchedToday < kSettingsAdsDailyCap;
  }

  Future<void> recordSettingsAdWatched() async {
    _resetSettingsAdCountIfNeeded(); // Ensure we are operating on the correct day's count
    if (_settingsAdsWatchedToday < kSettingsAdsDailyCap) {
      _settingsAdsWatchedToday++;
      _lastSettingsAdWatchDate = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_prefsSettingsAdsCountKey, _settingsAdsWatchedToday);
        await prefs.setString(_prefsSettingsAdsDateKey, _lastSettingsAdWatchDate);
      } catch (e) {
        print("Error saving settings ad cap data: $e");
      }
      notifyListeners(); // Notify listeners about the change in count (e.g. to update UI)
    }
  }

  int get settingsAdsLeftToday => kSettingsAdsDailyCap - _settingsAdsWatchedToday;

  // Income Pool
  int _persistedTotalRoomIncomePoolPoints = 0; // This is the actual pool value used for redemption
  static const String _prefsIncomePoolTotalKey = 'persistedTotalRoomIncomePoolPoints';

  // Weekly contribution tracking for Income Pool (for current user)
  int _currentUserWeeklyIncomePoolContribution = 0;
  String _lastIncomePoolContributionResetDate = ""; // Stores YYYY-WW (Year-WeekOfYear) format
  static const String _prefsWeeklyContributionKey = 'currentUserWeeklyIncomePoolContribution';
  static const String _prefsLastContributionResetDateKey = 'lastIncomePoolContributionResetDateKey'; // Corrected Key Name


  // Calculated total from all users' current incomePoolPoints (for display if needed, but not for redemption)
  int get liveTotalRoomIncomePoolPoints {
    return _users.fold(0, (sum, user) => sum + user.incomePoolPoints);
  }

  // Getter for the persisted global pool points, which is used for redemption
  int get totalRoomIncomePoolPoints => _persistedTotalRoomIncomePoolPoints;


  // Load all data
  Future<void> _loadData() async {
    _currentUser = await _dataService.getCurrentUser();
    // Ensure _currentUser from _dataService has the new point fields populated
    // This implies _dataService.getCurrentUser() correctly maps from AppUser (DB) to User (app_model)
    _users = await _dataService.getUsers();
    _bills = await _dataService.getBills();
    _tasks = await _dataService.getTasks();
    _votes = await _dataService.getVotes();
    _schedules = await _dataService.getSchedules();
    _treeLevel = await _dataService.getTreeLevel(); // This might be a growth factor
    _totalCommunityTreePoints = await _dataService.getTotalCommunityTreePoints(); // Assuming method in DataService

    // Initialize new properties
    _ssids = await _dataService.getNetworkSSIDs();
    _discoveredUsers = await _dataService.getDiscoveredUsers();
    // currentUser.credits is already loaded by _dataService.getCurrentUser()
    // The new points in currentUser (trustScore, communityTreePoints etc.) also need to be loaded by getCurrentUser()
    _isPremium =
        (_currentUser?.credits ?? 0) > kCreditsPremiumThreshold;
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
    _isTransferring = true; // Assuming ads are part of the "transfer" visual
    notifyListeners();

    // Show first rewarded ad
    print("AppStateProvider: Attempting to show first rewarded ad for sync.");
    _adsService.showRewardedAd();
    // In a real scenario, you'd await a Future from showRewardedAd that completes upon ad dismissal/reward.
    // For simplicity here, we'll just call it. The UI will be blocked by the ad.
    // A small delay to simulate ad watching, or rely on ad SDK's own modal behavior.
    await Future.delayed(const Duration(seconds: 1)); // Small delay before attempting next ad

    // Show second rewarded ad
    print("AppStateProvider: Attempting to show second rewarded ad for sync.");
    _adsService.showRewardedAd();
    await Future.delayed(const Duration(seconds: 1)); // Small delay


    // Proceed with actual P2P sync logic after ads attempt
    try {
      print("AppStateProvider: Proceeding with P2P data sync after ads.");
      // Simulate transfer progress updates for actual data sync
      for (int i = 0; i <= 100; i += 20) {
        _transferProgress = i.toDouble();
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 300)); // Simulate data transfer part
      }

      if (_currentUser?.isAdmin ?? false) {
        await _dataService.startAdvertising();
      } else {
        await _dataService.startDiscovery();
      }
      print("AppStateProvider: P2P sync process initiated.");
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error starting P2P sync: $e');
      }
    }

    // Simulate time for P2P connection and data exchange
    await Future.delayed(const Duration(seconds: 5));

    _isSyncing = false;
    _isTransferring = false;
    _transferProgress = null;
    notifyListeners();
    print("AppStateProvider: Sync process complete.");
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
  int get totalCommunityTreePoints => _totalCommunityTreePoints;

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
    // This method seems to update the growth factor (_treeLevel)
    await _dataService.incrementTreeLevel(amount);
    // We might need a separate method in DataService to update totalCommunityTreePoints directly,
    // or this incrementTreeLevel also updates the absolute points in the backend.
    // For now, assume this is for the visual representation factor.
    await refreshData(); // This will reload _treeLevel and _totalCommunityTreePoints
  }

  // --- AD REWARD METHODS ---
  Future<void> grantAdRewardPoints({
    int trustScorePoints = 0,
    int communityTreePoints = 0,
    int incomePoolPoints = 0,
    int amazonCouponPoints = 0,
    int payPalPoints = 0,
    int coins = 0, // Added coins parameter
  }) async {
    if (_currentUser == null) return;

    bool changed = false;

    User updatedUser = _currentUser!;
    if (trustScorePoints > 0) {
      updatedUser = updatedUser.copyWith(trustScore: updatedUser.trustScore + trustScorePoints);
      changed = true;
    }
    if (communityTreePoints > 0) {
      // User's contribution to community tree
      updatedUser = updatedUser.copyWith(communityTreePoints: updatedUser.communityTreePoints + communityTreePoints);
      // Global community tree points
      _totalCommunityTreePoints += communityTreePoints;
      // Persist global community tree points (assuming a method in DataService)
      await _dataService.updateTotalCommunityTreePoints(_totalCommunityTreePoints);
      changed = true;
    }
    if (incomePoolPoints > 0) {
      updatedUser = updatedUser.copyWith(incomePoolPoints: updatedUser.incomePoolPoints + incomePoolPoints);
      changed = true;
    }
    if (amazonCouponPoints > 0) {
      updatedUser = updatedUser.copyWith(amazonCouponPoints: updatedUser.amazonCouponPoints + amazonCouponPoints);
      changed = true;
    }
    if (payPalPoints > 0) {
      updatedUser = updatedUser.copyWith(payPalPoints: updatedUser.payPalPoints + payPalPoints);
      changed = true;
    }
    if (coins > 0) {
      updatedUser = updatedUser.copyWith(credits: updatedUser.credits + coins); // Assuming 'credits' field is used for 'coins'
      changed = true;
    }

    if (changed) {
      _currentUser = updatedUser;
      await _dataService.saveUser(_currentUser!); // Persist updated user (DataService needs to handle AppUser vs User)
      // saveUser should internally call saveCurrentUser if IDs match, or we can do it explicitly
      // await _dataService.saveCurrentUser(_currentUser!); // This might be redundant if saveUser handles current user
      notifyListeners();
    }
  }

  // Specific method to show a settings ad and grant rewards
  Future<bool> showSettingsRewardedAd() async {
    if (!canWatchSettingsAd()) {
      print("AppStateProvider: Settings ad daily cap reached.");
      // Optionally, show a message to the user via a status update or event
      return false; // Indicate ad was not shown
    }

    // For now, we assume AdsService.showRewardedAd() internally handles the ad display
    // and triggers the reward callback in AdsService, which then calls grantAdRewardPoints.
    // The crucial part is that AdsService needs to know WHICH set of rewards to grant.
    // This design can be improved by showRewardedAd taking a context or reward type.
    // For now, we'll make AdsService grant specific "Settings Ad" rewards upon completion.
    // This requires a modification in AdsService to distinguish this call or context.
    // Alternatively, AppStateProvider can listen to AdsService._onRewardEarnedController
    // and grant specific rewards based on a flag set before calling showRewardedAd.

    // Simpler approach for now: Modify AdsService to accept a reward context,
    // or have a dedicated method in AdsService for settings ads.
    // For this iteration, I'll assume a generic ad view, and AdsService's reward callback
    // needs to be enhanced or a flag set.
    // Let's assume AdsService's existing onUserEarnedReward will call grantAdRewardPoints
    // with the *correct* settings ad rewards. This implies AdsService needs to know.
    // This is a bit of a design challenge with current structure.

    // A temporary way to signal to AdsService (not ideal, but works for now):
    // AdsService could check a flag in AppStateProvider, or AppStateProvider could pass a reward type.
    // Let's assume AdsService is modified to grant specific "Settings Ad" rewards
    // when called from this context. The current AdsService `showRewardedAd` grants
    // "Sync Ad" rewards. This needs refinement.

    // For now, let's call the generic showRewardedAd.
    // The reward granting for "Settings Ad" will be handled by modifying AdsService later
    // to accept a context or by adding a new method in AdsService.
    // For this step, the focus is on the daily cap and initiating the ad.

    _adsService.showRewardedAd(rewardContext: "SettingsAd"); // PASSING HYPOTHETICAL CONTEXT

    // The actual reward granting and count recording should happen upon successful ad completion.
    // So, recordSettingsAdWatched() and grantAdRewardPoints() should be called from AdsService's
    // ad completion callback, conditioned on this "SettingsAd" context.

    // If showRewardedAd() were a Future<bool> indicating success:
    // bool adShownAndRewarded = await _adsService.showRewardedAd(rewardContext: "SettingsAd");
    // if (adShownAndRewarded) {
    //   await recordSettingsAdWatched(); // This would be called by AdsService internally on reward
    //   return true;
    // }
    // return false;

    // For now, we assume the call to showRewardedAd will eventually lead to rewards if successful.
    // The daily cap is checked here. The recording of the watch will be part of AdsService.
    return true; // Indicate ad showing process was initiated.
  }

  // --- Income Pool Methods ---
  Future<bool> contributeToIncomePool(int points) async {
    if (_currentUser == null || points <= 0) {
      print("AppStateProvider: Invalid contribution attempt.");
      return false;
    }
    if (_currentUser!.incomePoolPoints < points) {
      print("AppStateProvider: Not enough income pool points to contribute. Has: ${_currentUser!.incomePoolPoints}, wants: $points");
      return false;
    }

    _resetWeeklyContributionIfNeeded(); // Ensure weekly counter is current before adding

    // Deduct from user
    _currentUser = _currentUser!.copyWith(
      incomePoolPoints: _currentUser!.incomePoolPoints - points
    );

    // Add to persisted global pool
    _persistedTotalRoomIncomePoolPoints += points;
    await _savePersistedIncomePoolTotal();

    // Update and check weekly contribution
    _currentUserWeeklyIncomePoolContribution += points;
    bool trustBonusGranted = false;
    if (_currentUserWeeklyIncomePoolContribution >= 50) {
      print("AppStateProvider: User contributed >= 50 to income pool this week. Granting Trust Score bonus (+5).");
      // Grant +5 Trust Score
      // Assuming grantAdRewardPoints handles saving the user after updating points
      await grantAdRewardPoints(trustScorePoints: 5);
      _currentUserWeeklyIncomePoolContribution = 0; // Reset after bonus
      trustBonusGranted = true;
    }
    await _saveWeeklyContributionData(); // Save potentially updated weekly contribution (or reset date)

    // Persist user changes (only if not already saved by trust bonus logic in grantAdRewardPoints)
    if (!trustBonusGranted) {
      await _dataService.saveUser(_currentUser!);
    } else {
      // If bonus was granted, grantAdRewardPoints already saved the user.
      // We still need to ensure _currentUser in provider is the latest instance.
      // This depends on whether grantAdRewardPoints updates _currentUser in provider.
      // Assuming it does, or a subsequent refresh will handle it.
      // For safety, if grantAdRewardPoints doesn't refresh _currentUser:
      // _currentUser = await _dataService.getCurrentUser(); // or similar to get the updated user
    }

    print("AppStateProvider: User ${_currentUser!.name} contributed $points to income pool. New personal total: ${_currentUser!.incomePoolPoints}. New global pool total: $_persistedTotalRoomIncomePoolPoints");
    notifyListeners();
    return true;
  }

  Future<bool> redeemIncomePoolGoal(IncomePoolGoal goal) async {
    if (!(_currentUser?.isAdmin ?? false)) { // Assuming only admins can redeem for now
      print("AppStateProvider: Only admins can redeem income pool goals.");
      return false;
    }
    if (_persistedTotalRoomIncomePoolPoints < goal.pointsRequired) {
      print("AppStateProvider: Not enough total income pool points (${_persistedTotalRoomIncomePoolPoints}) to redeem ${goal.description} (needs ${goal.pointsRequired}).");
      return false;
    }

    _persistedTotalRoomIncomePoolPoints -= goal.pointsRequired;
    await _savePersistedIncomePoolTotal();

    // Actual reward distribution is out of scope. Log it.
    print("AppStateProvider: Income Pool Goal Redeemed: ${goal.description}! Deducted ${goal.pointsRequired} points. New pool total: $_persistedTotalRoomIncomePoolPoints");
    print("Log: Distribute ${goal.rewardType} of value ${goal.rewardValue}.");
    // Example: If goal.rewardType == IncomePoolRewardType.payPal, log "Initiate $${goal.rewardValue} PayPal Payout to house fund."
    // Example: If goal.rewardType == IncomePoolRewardType.amazonCoupon, log "Generate $${goal.rewardValue} Amazon Coupon for household."

    notifyListeners();
    return true;
  }


  // --- Amazon Coupon Redemption ---
  Future<bool> redeemAmazonCoupon(AmazonCouponTier tier) async {
    if (_currentUser == null) {
      print("AppStateProvider: No current user to redeem coupon for.");
      return false;
    }
    if (_currentUser!.amazonCouponPoints < tier.pointsRequired) {
      print("AppStateProvider: Not enough Amazon Coupon points to redeem ${tier.description}.");
      return false;
    }

    // Deduct points
    _currentUser = _currentUser!.copyWith(
      amazonCouponPoints: _currentUser!.amazonCouponPoints - tier.pointsRequired
    );

    // Persist changes
    await _dataService.saveUser(_currentUser!);
    // If saveUser doesn't also update _currentUser instance in the provider from its return value,
    // ensure _currentUser is the same instance or re-fetch if necessary.
    // For now, assuming _dataService.saveUser updates the source user object that _currentUser references,
    // or that a subsequent refreshData() call would update it. Best practice is for saveUser to return the updated user.

    print("AppStateProvider: Redeemed ${tier.description} for ${tier.pointsRequired} points.");
    notifyListeners();
    return true;
  }

  // --- PayPal Cash Redemption ---
  Future<bool> redeemPayPalCash(PayPalCashTier tier) async {
    if (_currentUser == null) {
      print("AppStateProvider: No current user to redeem PayPal cash for.");
      return false;
    }
    if (_currentUser!.payPalPoints < tier.pointsRequired) {
      print("AppStateProvider: Not enough PayPal points to redeem ${tier.description}.");
      return false;
    }

    // Deduct points
    _currentUser = _currentUser!.copyWith(
      payPalPoints: _currentUser!.payPalPoints - tier.pointsRequired
    );

    // Persist changes
    await _dataService.saveUser(_currentUser!);

    print("AppStateProvider: Redeemed ${tier.description} for ${tier.pointsRequired} points.");
    notifyListeners();
    return true;
  }

  // --- Microtransaction Purchase ---
  Future<bool> purchaseProduct(MicrotransactionProduct product) async {
    if (_currentUser == null) {
      print("AppStateProvider: No current user to purchase product for.");
      return false;
    }

    print("AppStateProvider: Simulating purchase for ${product.name} (\$${product.priceUSD})...");
    // ---- REAL PAYMENT GATEWAY INTEGRATION WOULD GO HERE ----
    // For example, using in_app_purchase package:
    // 1. Query product details from store (Play Store/App Store).
    // 2. Initiate purchase flow.
    // 3. Verify purchase on backend.
    // 4. If verified, then grant item.
    // For this subtask, we simulate success immediately.
    print("LOG: Real payment gateway would be invoked for product ID: ${product.id}");

    User updatedUser = _currentUser!;
    bool changed = false;

    if (product.type == ProductType.coins && product.coinAmount != null) {
      updatedUser = updatedUser.copyWith(credits: updatedUser.credits + product.coinAmount!);
      print("AppStateProvider: Added ${product.coinAmount} credits to user.");
      changed = true;
    } else if (product.type == ProductType.treeSkin && product.cosmeticId != null) {
      if (!updatedUser.ownedTreeSkins.contains(product.cosmeticId!)) {
        List<String> newSkins = List.from(updatedUser.ownedTreeSkins)..add(product.cosmeticId!);
        updatedUser = updatedUser.copyWith(ownedTreeSkins: newSkins);
        print("AppStateProvider: Added tree skin '${product.cosmeticId}' to user.");
        changed = true;
      } else {
        print("AppStateProvider: User already owns tree skin '${product.cosmeticId}'.");
        // Optionally, still return true if purchase is considered "successful" even if item is owned
      }
    } else if (product.type == ProductType.featureUnlock) {
      // Example: Set a flag for a feature. This would need a corresponding field in User model.
      // e.g., updatedUser = updatedUser.copyWith(hasAdvancedStats: true);
      print("AppStateProvider: Feature '${product.name}' unlocked (simulated).");
      changed = true; // Assume some change happens
    }

    if (changed) {
      _currentUser = updatedUser;
      await _dataService.saveUser(_currentUser!);
      notifyListeners();
    }

    // Simulate purchase success for UI feedback
    return true;
  }

  // --- Subscription Management ---
  Future<void> checkSubscriptionStatus() async {
    bool wasPremium = _isPremium;
    bool currentPremiumStatus = false;
    DateTime now = DateTime.now();

    if (_currentUser != null) {
      if (_currentUser!.isFreeTrialActive && _currentUser!.freeTrialExpiryDate != null && _currentUser!.freeTrialExpiryDate!.isAfter(now)) {
        currentPremiumStatus = true;
        print("AppStateProvider: User is on active Free Trial until ${_currentUser!.freeTrialExpiryDate}.");
      } else if (_currentUser!.activeSubscriptionId != null && _currentUser!.subscriptionExpiryDate != null && _currentUser!.subscriptionExpiryDate!.isAfter(now)) {
        currentPremiumStatus = true;
        print("AppStateProvider: User has active subscription (${_currentUser!.activeSubscriptionId}) until ${_currentUser!.subscriptionExpiryDate}.");
      } else {
        // Check if trial just expired or subscription just expired to clear them
        if (_currentUser!.isFreeTrialActive && _currentUser!.freeTrialExpiryDate != null && !_currentUser!.freeTrialExpiryDate!.isAfter(now)) {
          _currentUser = _currentUser!.copyWith(isFreeTrialActive: false); // Clear trial
          print("AppStateProvider: Free trial expired on ${_currentUser!.freeTrialExpiryDate}.");
          await _dataService.saveUser(_currentUser!);
        }
        if (_currentUser!.activeSubscriptionId != null && _currentUser!.subscriptionExpiryDate != null && !_currentUser!.subscriptionExpiryDate!.isAfter(now)) {
          _currentUser = _currentUser!.copyWith(activeSubscriptionId: null, subscriptionExpiryDate: null); // Clear subscription
           print("AppStateProvider: Subscription expired on ${_currentUser!.subscriptionExpiryDate}.");
          await _dataService.saveUser(_currentUser!);
        }
        currentPremiumStatus = false;
        print("AppStateProvider: No active subscription or free trial.");
      }
    }

    if (_isPremium != currentPremiumStatus) {
      _isPremium = currentPremiumStatus;
      // If AdsService.isPremium is dynamically read from here, this notifyListeners should suffice.
      // Otherwise, if AdsService needs an explicit call:
      // _adsService.setPremiumStatus(_isPremium);
      print("AppStateProvider: Premium status changed to $_isPremium.");
      notifyListeners(); // Notify for UI changes based on premium status
    } else if (wasPremium != currentPremiumStatus){
        notifyListeners(); // Notify if the internal state of premium changed even if the overall _isPremium bool didn't flip (e.g. trial ended but sub started)
    }
  }

  Future<void> startFreeTrial() async {
    if (_currentUser == null || _currentUser!.isFreeTrialActive || _currentUser!.activeSubscriptionId != null) {
      print("AppStateProvider: User not eligible for free trial (already had one, has active sub, or no user).");
      return; // Or throw error / return status
    }

    DateTime now = DateTime.now();
    DateTime expiryDate = now.add(kFreeTrialDuration);
    _currentUser = _currentUser!.copyWith(
      isFreeTrialActive: true,
      freeTrialExpiryDate: expiryDate,
    );
    await _dataService.saveUser(_currentUser!);
    await checkSubscriptionStatus(); // This will update _isPremium and notify
    print("AppStateProvider: Free trial started. Expires on $expiryDate.");
  }

  Future<void> subscribeToPlan(SubscriptionPlan plan) async {
    if (_currentUser == null) return;

    print("AppStateProvider: Simulating subscription to ${plan.name} for \$${plan.priceUSD}...");
    // ---- REAL PAYMENT GATEWAY INTEGRATION WOULD GO HERE FOR SUBSCRIPTIONS ----
    // e.g., using in_app_purchase or RevenueCat
    // 1. Initiate purchase with the store.
    // 2. Verify purchase on backend.
    // 3. If verified, update subscription details.
    print("LOG: Real subscription purchase flow would be invoked for plan ID: ${plan.id}");

    DateTime now = DateTime.now();
    DateTime expiryDate = now.add(plan.duration);

    _currentUser = _currentUser!.copyWith(
      activeSubscriptionId: plan.id,
      subscriptionExpiryDate: expiryDate,
      isFreeTrialActive: false, // End free trial if one was active
      freeTrialExpiryDate: null, // Clear trial expiry
    );
    await _dataService.saveUser(_currentUser!);
    await checkSubscriptionStatus(); // This will update _isPremium and notify
    print("AppStateProvider: Subscribed to ${plan.name}. Expires on $expiryDate.");
  }

  Future<void> cancelSubscription() async {
    if (_currentUser == null || _currentUser!.activeSubscriptionId == null) {
       print("AppStateProvider: No active subscription to cancel.");
      return;
    }

    print("AppStateProvider: Simulating cancellation for subscription ID: ${_currentUser!.activeSubscriptionId}...");
    // ---- REAL SUBSCRIPTION CANCELLATION LOGIC WITH STORE WOULD GO HERE ----
    // e.g., for some gateways, this means setting a flag to not renew.
    // For this simulation, we'll clear it immediately.
    print("LOG: Real subscription cancellation flow would be invoked.");

    _currentUser = _currentUser!.copyWith(
      activeSubscriptionId: null,
      subscriptionExpiryDate: null,
      // Free trial is not reinstated upon cancellation of a paid sub
    );
    await _dataService.saveUser(_currentUser!);
    await checkSubscriptionStatus(); // This will update _isPremium and notify
    print("AppStateProvider: Subscription cancelled.");
  }
}
