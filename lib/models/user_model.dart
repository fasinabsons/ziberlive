import 'package:list_rooster/models/app_models.dart';

class AppUser {
  final String id;
  final String name;
  final String? email;
  final String? profileImageUrl;
  final String? deviceId;
  final String? assignedBedId; // Nullable
  final String role; // e.g., 'Roommate-Admin', 'Roommate'
  final int trustScore;
  final int coins;
  final List<Subscription> subscriptions;

  AppUser({
    required this.id,
    required this.name,
    this.email,
    this.profileImageUrl,
    this.deviceId,
    this.assignedBedId,
    required this.role,
    this.trustScore = 0,
    this.coins = 0,
    this.subscriptions = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'deviceId': deviceId,
      'assignedBedId': assignedBedId,
      'role': role,
      'trust_score': trustScore,
      'coins': coins,
      'subscriptions': subscriptions.map((sub) => sub.toJson()).toList(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
      deviceId: map['deviceId'] as String?,
      assignedBedId: map['assignedBedId'] as String?,
      role: map['role'] as String,
      trustScore: map['trust_score'] as int? ?? 0,
      coins: map['coins'] as int? ?? 0,
      subscriptions: map['subscriptions'] != null
          ? (map['subscriptions'] as List)
              .map((e) => Subscription.fromJson(e))
              .toList()
          : [],
    );
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    String? deviceId,
    String? assignedBedId,
    String? role,
    int? trustScore,
    int? coins,
    List<Subscription>? subscriptions,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      deviceId: deviceId ?? this.deviceId,
      assignedBedId: assignedBedId ?? this.assignedBedId,
      role: role ?? this.role,
      trustScore: trustScore ?? this.trustScore,
      coins: coins ?? this.coins,
      subscriptions: subscriptions ?? this.subscriptions,
    );
  }
}
