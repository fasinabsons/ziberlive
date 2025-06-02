class User {
  final String id;
  String name;
  UserRole role;
  List<Subscription> subscriptions;
  int credits;

  User({
    required this.id,
    required this.name,
    this.role = UserRole.user,
    this.subscriptions = const [],
    this.credits = 0,
  });

  // Create user from JSON map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == json['role'],
        orElse: () => UserRole.user,
      ),
      subscriptions: (json['subscriptions'] as List?)
          ?.map((sub) => Subscription.fromJson(sub))
          .toList() ?? [],
      credits: json['credits'] ?? 0,
    );
  }

  // Convert user to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role.toString(),
      'subscriptions': subscriptions.map((sub) => sub.toJson()).toList(),
      'credits': credits,
    };
  }

  // Check if user has specific subscription
  bool hasSubscription(SubscriptionType type) {
    return subscriptions.any((sub) => sub.type == type && sub.isActive);
  }

  // Add credits
  void addCredits(int amount) {
    credits += amount;
  }

  // Is admin
  bool get isAdmin => role == UserRole.roommateAdmin || role == UserRole.ownerAdmin;

  // Is owner admin
  bool get isOwnerAdmin => role == UserRole.ownerAdmin;
}

enum UserRole {
  user,
  roommateAdmin,
  ownerAdmin,
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
      type: SubscriptionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => SubscriptionType.rent,
      ),
      isActive: json['isActive'] ?? true,
    );
  }

  // Convert subscription to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'isActive': isActive,
    };
  }
}

enum SubscriptionType {
  communityMeals,
  drinkingWater,
  rent,
  utilities,
}