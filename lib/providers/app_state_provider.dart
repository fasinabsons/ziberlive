import 'package:flutter/material.dart';
// Specific imports from app_models.dart that are still used directly
import 'package:ziberlive/models/app_models.dart' show Apartment, Room, Bed, Task, Vote, SubscriptionType;
// Removed PaymentStatus from here as it's in bill_model.dart now, if bill_model.dart's version is canonical.
// If app_models.dart#PaymentStatus is still needed for other models, it should be kept.
// For now, assuming bill_model.dart#PaymentStatus will be used with the new Bill.

import 'package:ziberlive/models/user_model.dart'; // For AppUser
import 'package:ziberlive/models/bill_model.dart'; // For the new Bill model and its PaymentStatus
import 'package:ziberlive/models/bed_type_model.dart'; // For BedType
import 'package:ziberlive/services/data_service_mock.dart' hide NetworkSSID, DiscoveredUser;
import 'package:ziberlive/config.dart';
import 'package:ziberlive/models/network_models.dart';
import 'package:ziberlive/models/schedule_models.dart';
import 'package:list_rooster/services/bill_calculation_service.dart'; // Import the new service


class AppStateProvider extends ChangeNotifier {
  final DataService _dataService = DataService();
  final BillCalculationService _billCalculationService = BillCalculationService(); // Add instance of the service
  AppUser? _currentUser; // Changed from User
  List<AppUser> _users = []; // Changed from List<User>
  List<Bill> _bills = []; // Will use Bill from bill_model.dart
  List<Task> _tasks = []; // Still from app_models.dart
  List<Vote> _votes = []; // Still from app_models.dart
  List<Schedule> _schedules = []; // Still from schedule_models.dart

  // New state variables for consolidated models
  List<Apartment> _apartments = []; // From app_models.dart (updated)
  List<Room> _rooms = []; // From app_models.dart (updated)
  List<Bed> _beds = []; // From app_models.dart (updated)
  List<BedType> _bedTypes = []; // From bed_type_model.dart

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
    _currentUser = await _dataService.getCurrentUser(); // Expects AppUser now
    _users = await _dataService.getUsers(); // Expects List<AppUser> now
    _bills = await _dataService.getBills(); // Expects List<Bill from bill_model.dart> now
    _tasks = await _dataService.getTasks();
    _votes = await _dataService.getVotes();
    _schedules = await _dataService.getSchedules();
    _treeLevel = await _dataService.getTreeLevel();

    // Load new model data
    _apartments = await _dataService.getApartments();
    _bedTypes = await _dataService.getBedTypes();
    // Assuming rooms and beds are fetched if not deeply nested within apartments
    _rooms = await _dataService.getRooms();
    _beds = await _dataService.getBeds();

    // Initialize new properties
    _ssids = await _dataService.getNetworkSSIDs();
    _discoveredUsers = await _dataService.getDiscoveredUsers();
    _isPremium =
        (_currentUser?.coins ?? 0) > 1000; // Updated to AppUser.coins
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

      // Updated role check for AppUser (example roles, adjust as per your AppUser.role values)
      if (_currentUser?.role == 'Roommate-Admin' || _currentUser?.role == 'Owner-Admin') {
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
  AppUser? get currentUser => _currentUser; // Type updated
  List<AppUser> get users => _users; // Type updated
  List<Bill> get bills => _bills; // Type updated (uses Bill from bill_model.dart)
  List<Task> get tasks => _tasks;
  List<Vote> get votes => _votes;
  List<Schedule> get schedules => _schedules;

  // Getters for new models
  List<Apartment> get apartments => _apartments;
  List<Room> get rooms => _rooms;
  List<Bed> get beds => _beds;
  List<BedType> get bedTypes => _bedTypes;

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
      // PaymentStatus.unpaid should now refer to the enum from bill_model.dart
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
      PaymentStatus.paid, // PaymentStatus.paid from bill_model.dart
    );

    // Add credits for paying bill - AppUser.coins is int. DataService needs to handle String id.
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
  Future<void> addUser(AppUser user) async { // Changed to AppUser
    await _dataService.saveUser(user); // DataService needs to expect AppUser
    await refreshData();
  }

  // Update user
  Future<void> updateUser(AppUser updatedUser) async { // Changed to AppUser
    await _dataService.saveUser(updatedUser); // DataService needs to expect AppUser

    // Update current user if needed
    if (_currentUser?.id == updatedUser.id) {
      await _dataService.saveCurrentUser(updatedUser); // DataService needs to expect AppUser
    }

    await refreshData();
  }

  // Toggle user in bill splitting - Commented out due to removal of exemptUsers from Bill model
  // and change from title to name. This method is incompatible.
  // Future<void> toggleUserInBillSplitting(
  //     String billId, String userId, bool isExempt) async {
  //   final billIndex = _bills.indexWhere((bill) => bill.id == billId);
  //   if (billIndex == -1) return;

  //   final bill = _bills[billIndex];
  //   // final exemptUsers = Map<String, bool>.from(bill.exemptUsers); // exemptUsers removed
  //   // exemptUsers[userId] = isExempt;

  //   // final updatedBill = Bill( // Bill from bill_model.dart
  //   //   id: bill.id,
  //   //   name: bill.name, // Was bill.title
  //   //   description: bill.description,
  //   //   amount: bill.amount,
  //   //   dueDate: bill.dueDate,
  //   //   userIds: bill.userIds,
  //   //   paymentStatus: bill.paymentStatus,
  //   //   type: bill.type,
  //   //   // exemptUsers: exemptUsers, // This field is removed
  //   //   incomePoolRewardOffset: bill.incomePoolRewardOffset, // Added field
  //   // );

  //   // await _dataService.saveBill(updatedBill);
  //   await refreshData();
  // }

  // Update community tree
  Future<void> growTree(double amount) async {
    await _dataService.incrementTreeLevel(amount);
    await refreshData();
  }

  // New method to get calculated bill portion
  Future<RentPortionDetails> getCalculatedBillPortionForUser(Bill bill, String userId) async {
    AppUser? user = _users.firstWhere((u) => u.id == userId, orElse: () => null);
    if (user == null) {
      if (_currentUser?.id == userId) {
        user = _currentUser;
      } else {
        debugPrint("User with ID $userId not found in AppStateProvider._users or as _currentUser.");
        // Return a default RentPortionDetails indicating an error or zero amount
        return RentPortionDetails(totalAmountDue: 0, baseRentPortion: 0, vacancyShortfallShare: 0);
      }
    }

    if (bill.type == BillType.rent) {
      if (bill.apartmentId == null) {
        debugPrint("Rent bill ${bill.id} does not have an apartmentId.");
        return RentPortionDetails(totalAmountDue: 0, baseRentPortion: 0, vacancyShortfallShare: 0);
      }
      Apartment? apartment = _apartments.firstWhere((apt) => apt.id == bill.apartmentId, orElse: () => null);
      if (apartment == null) {
        debugPrint("Apartment with ID ${bill.apartmentId} not found for bill ${bill.id}.");
        return RentPortionDetails(totalAmountDue: 0, baseRentPortion: 0, vacancyShortfallShare: 0);
      }

      List<AppUser> allApartmentUsers = _users.where((appUser) {
        if (appUser.assignedBedId == null) return false;
        for (var room_item in apartment.rooms) { // Renamed to avoid conflict
          for (var bedInRoom in room_item.beds) {
            if (bedInRoom.id == appUser.assignedBedId) {
              return true;
            }
          }
        }
        return false;
      }).toList();

      if (user.assignedBedId == null) {
         debugPrint("User ${user.id} is not assigned to a bed, cannot calculate rent portion.");
         return RentPortionDetails(totalAmountDue: 0, baseRentPortion: 0, vacancyShortfallShare: 0);
      }

      // This now correctly returns RentPortionDetails
      return _billCalculationService.calculateRentPortion(
        user: user,
        rentBill: bill,
        apartment: apartment,
        bedTypes: _bedTypes,
        allApartmentUsers: allApartmentUsers,
      );
    } else {
      // For other bill types, wrap the double in RentPortionDetails
      List<AppUser> billUsers = _users.where((u) => bill.userIds.contains(u.id)).toList();
      if (billUsers.isEmpty && bill.userIds.contains(user.id)) {
        billUsers.add(user);
      }

      double otherBillPortion = _billCalculationService.calculateOtherBillPortion(
        otherBill: bill,
        billUsers: billUsers,
      );
      return RentPortionDetails(
        totalAmountDue: otherBillPortion,
        baseRentPortion: otherBillPortion, // For non-rent, base and total are the same
        vacancyShortfallShare: 0, // No vacancy concept for non-rent
      );
    }
  }

  // BedType Management Methods
  Future<void> addBedType(BedType bedType) async {
    // Basic check for uniqueness, though DataService might enforce this more strictly
    if (_bedTypes.any((bt) => bt.typeName == bedType.typeName)) {
      // Optionally throw an error or return a status
      debugPrint("BedType with typeName ${bedType.typeName} already exists.");
      return;
    }
    _bedTypes.add(bedType);
    await _dataService.saveBedType(bedType); // Assuming DataService handles actual persistence
    notifyListeners();
  }

  Future<void> updateBedType(BedType bedType) async {
    final index = _bedTypes.indexWhere((bt) => bt.typeName == bedType.typeName);
    if (index != -1) {
      _bedTypes[index] = bedType;
      await _dataService.saveBedType(bedType); // DataService saves the updated bedType
      notifyListeners();
    } else {
      // Optionally throw an error or handle case where bedType to update is not found
      debugPrint("BedType with typeName ${bedType.typeName} not found for update.");
    }
  }

  Future<void> deleteBedType(String typeName) async {
    final lengthBefore = _bedTypes.length;
    _bedTypes.removeWhere((bt) => bt.typeName == typeName);
    if (_bedTypes.length < lengthBefore) {
      await _dataService.deleteBedType(typeName); // DataService handles actual deletion
      notifyListeners();
    } else {
      // Optionally throw an error or handle case where bedType to delete is not found
      debugPrint("BedType with typeName $typeName not found for deletion.");
    }
  }

  // Apartment Management Methods
  Future<void> addApartment(Apartment apartment) async {
    if (_apartments.any((apt) => apt.id == apartment.id)) {
      debugPrint("Apartment with ID ${apartment.id} already exists.");
      // Consider updating if it exists or throwing an error, for now, just return.
      return;
    }
    _apartments.add(apartment);
    await _dataService.saveApartment(apartment);
    notifyListeners();
  }

  Future<void> updateApartment(Apartment apartment) async {
    final index = _apartments.indexWhere((apt) => apt.id == apartment.id);
    if (index != -1) {
      _apartments[index] = apartment;
      await _dataService.saveApartment(apartment);
      notifyListeners();
    } else {
      debugPrint("Apartment with ID ${apartment.id} not found for update.");
    }
  }

  Future<void> deleteApartment(String apartmentId) async {
    final lengthBefore = _apartments.length;
    _apartments.removeWhere((apt) => apt.id == apartmentId);
    if (_apartments.length < lengthBefore) {
      // Also remove associated rooms and beds from local state
      List<String> roomIdsToRemove = _rooms.where((room) => room.apartmentId == apartmentId).map((room) => room.id).toList();
      for (String roomId in roomIdsToRemove) {
        _beds.removeWhere((bed) => bed.roomId == roomId);
      }
      _rooms.removeWhere((room) => room.apartmentId == apartmentId);

      await _dataService.deleteApartment(apartmentId); // DataService should handle cascade delete in backend/storage
      notifyListeners();
    } else {
      debugPrint("Apartment with ID $apartmentId not found for deletion.");
    }
  }

  // Room Management Methods
  Future<void> addRoom(Room room) async {
    if (_rooms.any((r) => r.id == room.id)) {
      debugPrint("Room with ID ${room.id} already exists.");
      return;
    }
    _rooms.add(room);
    await _dataService.saveRoom(room);
    notifyListeners();
  }

  Future<void> updateRoom(Room room) async {
    final index = _rooms.indexWhere((r) => r.id == room.id);
    if (index != -1) {
      _rooms[index] = room;
      await _dataService.saveRoom(room);
      notifyListeners();
    } else {
      debugPrint("Room with ID ${room.id} not found for update.");
    }
  }

  Future<void> deleteRoom(String roomId) async {
    final lengthBefore = _rooms.length;
    _rooms.removeWhere((r) => r.id == roomId);
    if (_rooms.length < lengthBefore) {
      // Also remove associated beds from local state
      _beds.removeWhere((bed) => bed.roomId == roomId);

      await _dataService.deleteRoom(roomId); // DataService should handle cascade delete of beds in backend/storage
      notifyListeners();
    } else {
      debugPrint("Room with ID $roomId not found for deletion.");
    }
  }

  // Bed Management Methods
  Future<void> _updateUserAssignment(String? userId, String? newBedId) async {
    if (userId == null) return;

    final userIndex = _users.indexWhere((u) => u.id == userId);
    if (userIndex != -1) {
      AppUser userToUpdate = _users[userIndex];
      // Unassign from old bed if any, and it's different from newBedId
      if (userToUpdate.assignedBedId != null && userToUpdate.assignedBedId != newBedId) {
          final oldBedIndex = _beds.indexWhere((b) => b.id == userToUpdate.assignedBedId);
          if (oldBedIndex != -1) {
              // No direct user field on Bed, AppUser.assignedBedId is the link
          }
      }
      // Assign to new bed
      _users[userIndex] = userToUpdate.copyWith(assignedBedId: newBedId);
      await _dataService.saveUser(_users[userIndex]); // Persist AppUser change
                                                      // THIS IS WHERE DataServiceMock needs to handle AppUser
    }
  }

  Future<void> addBed(Bed bed, {String? assignedUserId}) async {
    if (_beds.any((b) => b.id == bed.id)) {
      debugPrint("Bed with ID ${bed.id} already exists.");
      return;
    }
    _beds.add(bed); // Add bed first
    await _dataService.saveBed(bed);

    if (assignedUserId != null) {
      // If this user was previously assigned to another bed, unassign them from it.
      final currentlyAssignedUserIndex = _users.indexWhere((u) => u.id == assignedUserId);
      if (currentlyAssignedUserIndex != -1) {
          AppUser user = _users[currentlyAssignedUserIndex];
          if(user.assignedBedId != null && user.assignedBedId != bed.id) {
              // User is already assigned to a different bed. Clear that assignment.
              await _updateUserAssignment(user.id, null); // Unassign from old bed.
          }
      }
      // Assign the new user to this bed
      await _updateUserAssignment(assignedUserId, bed.id);
    }
    notifyListeners();
  }

  Future<void> updateBed(Bed bed, {String? newAssignedUserId}) async {
    final index = _beds.indexWhere((b) => b.id == bed.id);
    if (index != -1) {
      Bed oldBedState = _beds[index]; // Get the state of the bed before update.

      // Determine the user currently assigned to this bed (if any) before the update.
      String? oldUserIdAssignedToThisBed;
      try {
        oldUserIdAssignedToThisBed = _users.firstWhere((u) => u.assignedBedId == oldBedState.id).id;
      } catch (e) { /* no user assigned */ }


      _beds[index] = bed; // Update bed details
      await _dataService.saveBed(bed);

      // Now handle user assignment changes.
      if (oldUserIdAssignedToThisBed != newAssignedUserId) {
        // Case 1: A user was assigned, and now no one is, or a different user is.
        if (oldUserIdAssignedToThisBed != null) {
          await _updateUserAssignment(oldUserIdAssignedToThisBed, null); // Unassign old user
        }
        // Case 2: A new user is being assigned (or re-assigned if they were the old one, handled by _updateUserAssignment).
        if (newAssignedUserId != null) {
           // If this newAssignedUser was previously assigned to another bed, unassign them from it.
          final currentlyAssignedUserIndex = _users.indexWhere((u) => u.id == newAssignedUserId);
          if (currentlyAssignedUserIndex != -1) {
              AppUser user = _users[currentlyAssignedUserIndex];
              if(user.assignedBedId != null && user.assignedBedId != bed.id) {
                  await _updateUserAssignment(user.id, null); // Unassign from old bed.
              }
          }
          await _updateUserAssignment(newAssignedUserId, bed.id); // Assign new user
        }
      }
      notifyListeners();
    } else {
      debugPrint("Bed with ID ${bed.id} not found for update.");
    }
  }

  Future<void> deleteBed(String bedId) async {
    final lengthBefore = _beds.length;
    String? userIdToUnassign;
    try {
      userIdToUnassign = _users.firstWhere((u) => u.assignedBedId == bedId).id;
    } catch (e) { /* no user assigned */ }

    _beds.removeWhere((b) => b.id == bedId);

    if (_beds.length < lengthBefore) {
      if (userIdToUnassign != null) {
        await _updateUserAssignment(userIdToUnassign, null); // Unassign user
      }
      await _dataService.deleteBed(bedId);
      notifyListeners();
    } else {
      debugPrint("Bed with ID $bedId not found for deletion.");
    }
  }

  Future<void> markUserBillPayment(String billId, String targetUserId, PaymentStatus newStatus) async {
    final billIndex = _bills.indexWhere((b) => b.id == billId);
    if (billIndex == -1) {
      debugPrint("Bill with ID $billId not found for updating payment status.");
      return;
    }

    Bill billToUpdate = _bills[billIndex];

    // Create a new map for paymentStatus to ensure change detection
    Map<String, PaymentStatus> updatedPaymentStatus = Map.from(billToUpdate.paymentStatus);
    updatedPaymentStatus[targetUserId] = newStatus;

    // Create a new Bill object with the updated paymentStatus
    // Assuming Bill has a copyWith method or we manually reconstruct it
    // If Bill does not have copyWith, manual reconstruction is needed:
    Bill updatedBill = Bill(
        id: billToUpdate.id,
        name: billToUpdate.name,
        description: billToUpdate.description,
        amount: billToUpdate.amount,
        dueDate: billToUpdate.dueDate,
        userIds: billToUpdate.userIds,
        paymentStatus: updatedPaymentStatus, // Use the new map
        type: billToUpdate.type,
        apartmentId: billToUpdate.apartmentId,
        incomePoolRewardOffset: billToUpdate.incomePoolRewardOffset,
        // lastUpdated: DateTime.now(), // If Bill model had this from app_models.dart
    );

    _bills[billIndex] = updatedBill;

    // TODO: Defer Trust Score logic to Step 11
    // if (newStatus == PaymentStatus.paid) {
    //   // Potentially increase trust score for targetUserId
    // } else {
    //   // Potentially decrease trust score if it was marked unpaid from paid
    // }

    await _dataService.saveBill(updatedBill);
    notifyListeners();
  }
}
