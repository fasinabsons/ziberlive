// Subscription Type enum
enum SubscriptionType {
  rent,
  utilities,
  communityMeals,
  drinkingWater,
  other,
}

// Subscription model
class Subscription {
  final String id;
  final String name;
  final SubscriptionType type;
  final bool isActive;

  const Subscription({
    required this.id,
    required this.name,
    required this.type,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'isActive': isActive,
    };
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      name: json['name'],
      type: _parseSubscriptionType(json['type']),
      isActive: json['isActive'] ?? true,
    );
  }

  static SubscriptionType _parseSubscriptionType(String type) {
    if (type.contains('rent')) return SubscriptionType.rent;
    if (type.contains('utilities')) return SubscriptionType.utilities;
    if (type.contains('communityMeals')) return SubscriptionType.communityMeals;
    if (type.contains('drinkingWater')) return SubscriptionType.drinkingWater;
    return SubscriptionType.other;
  }
}

// Bill Type enum
enum BillType {
  rent,
  utility,
  groceries,
  other,
  communityMeals,
  drinkingWater,
}

// Bill model
class Bill {
  final String id;
  final String title;
  final String description;
  final double amount;
  final DateTime dueDate;
  final List<String> userIds;
  final Map<String, PaymentStatus> paymentStatus;
  final BillType type;
  final Map<String, bool> exemptUsers; // For guests who don't need to pay
  DateTime lastUpdated;

  Bill({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.userIds,
    required this.paymentStatus,
    this.type = BillType.other,
    this.exemptUsers = const {},
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // Helper methods for bill functionality
  String getFormattedDueDate() {
    return '${dueDate.month}/${dueDate.day}/${dueDate.year}';
  }

  bool isOverdue() {
    return DateTime.now().isAfter(dueDate);
  }

  double getAmountPerUser() {
    final nonExemptUsers = userIds.where((userId) => !(exemptUsers[userId] ?? false)).length;
    return nonExemptUsers > 0 ? amount / nonExemptUsers : amount;
  }

  double getPaymentProgress() {
    if (userIds.isEmpty) return 0.0;
    return getPaidCount() / userIds.length;
  }

  int getPaidCount() {
    return paymentStatus.values.where((status) => status == PaymentStatus.paid).length;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'userIds': userIds,
      'paymentStatus': paymentStatus.map((key, value) => MapEntry(key, value.toString())),
      'type': type.toString(),
      'exemptUsers': exemptUsers,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      amount: json['amount'],
      dueDate: DateTime.parse(json['dueDate']),
      userIds: List<String>.from(json['userIds']),
      paymentStatus: (json['paymentStatus'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, _parsePaymentStatus(value)),
      ),
      type: _parseBillType(json['type'] ?? ''),
      exemptUsers: json['exemptUsers'] != null 
        ? Map<String, bool>.from(json['exemptUsers']) 
        : {},
      lastUpdated: json['lastUpdated'] != null ? DateTime.parse(json['lastUpdated']) : null,
    );
  }
  
  static BillType _parseBillType(String type) {
    if (type.contains('rent')) return BillType.rent;
    if (type.contains('utility')) return BillType.utility;
    if (type.contains('groceries')) return BillType.groceries;
    if (type.contains('communityMeals')) return BillType.communityMeals;
    if (type.contains('drinkingWater')) return BillType.drinkingWater;
    return BillType.other;
  }

  static PaymentStatus _parsePaymentStatus(String status) {
    if (status.contains('paid')) return PaymentStatus.paid;
    if (status.contains('pending')) return PaymentStatus.pending;
    return PaymentStatus.unpaid;
  }
}

// Payment status enum
enum PaymentStatus {
  paid,
  unpaid,
  pending,
}

// Task model
class Task {
  final String id;
  final String title;
  final String description;
  final String assignedUserId;
  final DateTime dueDate;
  bool isCompleted;
  final int creditReward;
  DateTime lastUpdated;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedUserId,
    required this.dueDate,
    this.isCompleted = false,
    this.creditReward = 10,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  String getFormattedDueDate() {
    return '${dueDate.month}/${dueDate.day}/${dueDate.year}';
  }
  
  bool isOverdue() {
    return DateTime.now().isAfter(dueDate);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assignedUserId': assignedUserId,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'creditReward': creditReward,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      assignedUserId: json['assignedUserId'],
      dueDate: DateTime.parse(json['dueDate']),
      isCompleted: json['isCompleted'] ?? false,
      creditReward: json['creditReward'] ?? 10,
      lastUpdated: json['lastUpdated'] != null ? DateTime.parse(json['lastUpdated']) : null,
    );
  }
}

// Vote model
class Vote {
  final String id;
  final String title;
  final String description;
  final List<VoteOption> options;
  final DateTime deadline;
  Map<String, String> userVotes; // userId -> optionId
  final bool isAnonymous;

  Vote({
    required this.id,
    required this.title,
    required this.description,
    required this.options,
    required this.deadline,
    required this.userVotes,
    required this.isAnonymous,
  });

  bool isVotingOpen() => DateTime.now().isBefore(deadline);

  void addVote(String userId, String optionId) {
    userVotes[userId] = optionId;
  }

  Map<String, int> get results {
    final results = <String, int>{};
    for (final option in options) {
      results[option.id] = 0;
    }
    for (final optionId in userVotes.values) {
      results[optionId] = (results[optionId] ?? 0) + 1;
    }
    return results;
  }
  
  String getFormattedEndDate() {
    return '${deadline.month}/${deadline.day}/${deadline.year}';
  }
  
  int getTotalVotes() {
    return userVotes.length;
  }
  
  VoteOption? getWinningOption() {
    if (userVotes.isEmpty) return null;
    
    final voteResults = results;
    String? winningOptionId;
    int maxVotes = 0;
    
    for (final entry in voteResults.entries) {
      if (entry.value > maxVotes) {
        maxVotes = entry.value;
        winningOptionId = entry.key;
      }
    }
    
    if (winningOptionId == null) return null;
    
    return options.firstWhere(
      (option) => option.id == winningOptionId,
      orElse: () => options.first,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'options': options.map((e) => e.toJson()).toList(),
      'deadline': deadline.toIso8601String(),
      'userVotes': userVotes,
      'isAnonymous': isAnonymous,
    };
  }

  factory Vote.fromJson(Map<String, dynamic> json) {
    return Vote(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      options: (json['options'] as List)
          .map((e) => VoteOption.fromJson(e))
          .toList(),
      deadline: DateTime.parse(json['deadline']),
      userVotes: Map<String, String>.from(json['userVotes']),
      isAnonymous: json['isAnonymous'],
    );
  }
}

// Vote option model
class VoteOption {
  final String id;
  final String text;
  final int count;

  const VoteOption({
    required this.id,
    required this.text,
    this.count = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'count': count,
    };
  }

  factory VoteOption.fromJson(Map<String, dynamic> json) {
    return VoteOption(
      id: json['id'],
      text: json['text'],
      count: json['count'] ?? 0,
    );
  }
}

// Vacancy models
class Apartment {
  final String id;
  final String name;
  final List<Room> rooms;

  const Apartment({
    required this.id,
    required this.name,
    required this.rooms,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rooms': rooms.map((room) => room.toJson()).toList(),
    };
  }

  factory Apartment.fromJson(Map<String, dynamic> json) {
    return Apartment(
      id: json['id'],
      name: json['name'],
      rooms: (json['rooms'] as List)
          .map((e) => Room.fromJson(e))
          .toList(),
    );
  }
}

class Room {
  final String id;
  final String name;
  final String apartmentId;
  final List<Bed> beds;

  Room({
    required this.id,
    required this.name,
    required this.apartmentId,
    required this.beds,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'apartmentId': apartmentId,
      'beds': beds.map((bed) => bed.toJson()).toList(),
    };
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      name: json['name'],
      apartmentId: json['apartmentId'],
      beds: json['beds'] != null
          ? (json['beds'] as List).map((e) => Bed.fromJson(e)).toList()
          : [],
    );
  }
}

class Bed {
  final String id;
  final String name;
  final String roomId;
  final String bedTypeName; // Links to BedType model's typeName
  bool isVacant; // May be derived later from AppUser.assignedBedId

  Bed({
    required this.id,
    required this.name,
    required this.roomId,
    required this.bedTypeName,
    this.isVacant = true,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'roomId': roomId,
      'bedTypeName': bedTypeName,
      'isVacant': isVacant,
    };
  }

  factory Bed.fromJson(Map<String, dynamic> json) {
    return Bed(
      id: json['id'],
      name: json['name'],
      roomId: json['roomId'],
      bedTypeName: json['bedTypeName'],
      isVacant: json['isVacant'] ?? true,
    );
  }
}
