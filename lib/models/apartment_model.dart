import 'package:intl/intl.dart';


// User Model
enum UserRole {
  user,
  roommateAdmin,
  ownerAdmin,
}

class User {
  final String id;
  String name;
  UserRole role;
  List<Subscription> subscriptions;
  int credits;
  DateTime lastUpdated;

  User({
    required this.id,
    required this.name,
    this.role = UserRole.user,
    this.subscriptions = const [],
    this.credits = 0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // Create user from JSON map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      role: UserRole.values.byName(json['role'] ?? 'user'),
      subscriptions: (json['subscriptions'] as List<dynamic>? ?? [])
          .map((sub) => Subscription.fromJson(sub))
          .toList(),
      credits: json['credits'] ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  // Convert user to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role.name,
      'subscriptions': subscriptions.map((sub) => sub.toJson()).toList(),
      'credits': credits,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Check if user has specific subscription
  bool hasSubscription(SubscriptionType type) {
    return subscriptions.any((sub) => sub.type == type && sub.isActive);
  }

  // Add credits
  void addCredits(int amount) {
    credits += amount;
    lastUpdated = DateTime.now();
  }

  // Is admin
  bool get isAdmin => role == UserRole.roommateAdmin || role == UserRole.ownerAdmin;

  // Is owner admin
  bool get isOwnerAdmin => role == UserRole.ownerAdmin;
}

// Subscription Model
enum SubscriptionType {
  communityMeals,
  drinkingWater,
  rent,
  utilities,
}

class Subscription {
  final String id;
  final String name;
  final SubscriptionType type;
  bool isActive;

  Subscription({
    required this.id,
    required this.name,
    required this.type,
    this.isActive = true,
  });

  // Create subscription from JSON map
  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      name: json['name'],
      type: SubscriptionType.values.byName(json['type']),
      isActive: json['isActive'] ?? true,
    );
  }

  // Convert subscription to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'isActive': isActive,
    };
  }
}

// Bill Model
enum BillType {
  rent,
  utility,
  communityMeals,
  drinkingWater,
  other,
}

enum PaymentStatus {
  paid,
  unpaid,
  pending,
}

class Bill {
  final String id;
  String name;
  double amount;
  DateTime dueDate;
  BillType type;
  List<String> userIds; // IDs of users who need to pay the bill
  Map<String, PaymentStatus> paymentStatus; // User ID to payment status
  String? apartmentId; // For apartment-specific bills
  DateTime lastUpdated;

  Bill({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.type,
    required this.userIds,
    this.paymentStatus = const {},
    this.apartmentId,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // Create a bill from JSON map
  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'],
      name: json['name'],
      amount: json['amount'].toDouble(),
      dueDate: DateTime.parse(json['dueDate']),
      type: BillType.values.byName(json['type']),
      userIds: List<String>.from(json['userIds']),
      paymentStatus: (json['paymentStatus'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, PaymentStatus.values.byName(value)),
      ),
      apartmentId: json['apartmentId'],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  // Convert bill to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'type': type.name,
      'userIds': userIds,
      'paymentStatus': paymentStatus.map(
        (key, value) => MapEntry(key, value.name),
      ),
      'apartmentId': apartmentId,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Calculate amount per user
  double getAmountPerUser() {
    if (userIds.isEmpty) return amount;
    return amount / userIds.length;
  }

  // Format the due date
  String getFormattedDueDate() {
    return DateFormat.yMMMd().format(dueDate);
  }

  // Check if the bill is overdue
  bool isOverdue() {
    return dueDate.isBefore(DateTime.now());
  }

  // Check if bill is relevant for a specific subscription type
  bool isRelevantForSubscription(SubscriptionType subscriptionType) {
    switch (type) {
      case BillType.rent:
        return subscriptionType == SubscriptionType.rent;
      case BillType.utility:
        return subscriptionType == SubscriptionType.utilities;
      case BillType.communityMeals:
        return subscriptionType == SubscriptionType.communityMeals;
      case BillType.drinkingWater:
        return subscriptionType == SubscriptionType.drinkingWater;
      case BillType.other:
        return true;
    }
  }

  // Set payment status for a user
  void markAsPaid(String userId) {
    paymentStatus[userId] = PaymentStatus.paid;
    lastUpdated = DateTime.now();
  }

  // Get payment count
  int getPaidCount() {
    return paymentStatus.values
        .where((status) => status == PaymentStatus.paid)
        .length;
  }

  // Get payment progress percentage
  double getPaymentProgress() {
    if (userIds.isEmpty) return 0.0;
    return getPaidCount() / userIds.length;
  }
}

// Task Model
class Task {
  final String id;
  String title;
  String description;
  DateTime dueDate;
  String assignedUserId;
  bool isCompleted;
  int creditReward;
  String? apartmentId;
  DateTime lastUpdated;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.assignedUserId,
    this.isCompleted = false,
    this.creditReward = 10,
    this.apartmentId,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // Create a task from JSON map
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['dueDate']),
      assignedUserId: json['assignedUserId'],
      isCompleted: json['isCompleted'] ?? false,
      creditReward: json['creditReward'] ?? 10,
      apartmentId: json['apartmentId'],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  // Convert task to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'assignedUserId': assignedUserId,
      'isCompleted': isCompleted,
      'creditReward': creditReward,
      'apartmentId': apartmentId,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Format the due date
  String getFormattedDueDate() {
    return DateFormat.yMMMd().format(dueDate);
  }

  // Check if the task is overdue
  bool isOverdue() {
    return !isCompleted && dueDate.isBefore(DateTime.now());
  }

  // Mark task as completed
  void complete() {
    isCompleted = true;
    lastUpdated = DateTime.now();
  }
}

// Vote Model
class VoteOption {
  final String id;
  final String text;
  int count;

  VoteOption({
    required this.id,
    required this.text,
    this.count = 0,
  });

  factory VoteOption.fromJson(Map<String, dynamic> json) {
    return VoteOption(
      id: json['id'],
      text: json['text'],
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'count': count,
    };
  }
}

class Vote {
  final String id;
  String title;
  String description;
  List<VoteOption> options;
  DateTime endDate;
  Map<String, String> userVotes; // userId to optionId
  bool isAnonymous;
  String? apartmentId;
  DateTime lastUpdated;

  Vote({
    required this.id,
    required this.title,
    required this.description,
    required this.options,
    required this.endDate,
    this.userVotes = const {},
    this.isAnonymous = false,
    this.apartmentId,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // Create a vote from JSON map
  factory Vote.fromJson(Map<String, dynamic> json) {
    return Vote(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      options: (json['options'] as List<dynamic>)
          .map((opt) => VoteOption.fromJson(opt))
          .toList(),
      endDate: DateTime.parse(json['endDate']),
      userVotes: Map<String, String>.from(json['userVotes'] ?? {}),
      isAnonymous: json['isAnonymous'] ?? false,
      apartmentId: json['apartmentId'],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  // Convert vote to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'options': options.map((opt) => opt.toJson()).toList(),
      'endDate': endDate.toIso8601String(),
      'userVotes': userVotes,
      'isAnonymous': isAnonymous,
      'apartmentId': apartmentId,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Add a vote from a user
  void addVote(String userId, String optionId) {
    // Remove previous vote if exists
    String? previousVote = userVotes[userId];
    if (previousVote != null) {
      VoteOption? prevOption = options.firstWhere(
        (opt) => opt.id == previousVote,
        orElse: () => options.first,
      );
      if (prevOption.count > 0) {
        prevOption.count--;
      }
    }

    // Add new vote
    userVotes[userId] = optionId;
    VoteOption option = options.firstWhere(
      (opt) => opt.id == optionId,
      orElse: () => options.first,
    );
    option.count++;
    lastUpdated = DateTime.now();
  }

  // Check if voting is still open
  bool isVotingOpen() {
    return endDate.isAfter(DateTime.now());
  }

  // Get winning option
  VoteOption? getWinningOption() {
    if (options.isEmpty) return null;
    
    VoteOption winner = options.first;
    for (var option in options) {
      if (option.count > winner.count) {
        winner = option;
      }
    }
    return winner;
  }

  // Get total votes cast
  int getTotalVotes() {
    return userVotes.length;
  }

  // Format the end date
  String getFormattedEndDate() {
    return DateFormat.yMMMd().add_jm().format(endDate);
  }
}