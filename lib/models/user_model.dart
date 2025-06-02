class AppUser {
  final int? id; // Nullable for creation, non-null when fetched from DB
  final String name;
  final String? bed;
  final String role; // e.g., 'Roommate-Admin', 'Roommate'
  final int trustScore;
  final int coins;

  AppUser({
    this.id,
    required this.name,
    this.bed,
    required this.role,
    this.trustScore = 0,
    this.coins = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bed': bed,
      'role': role,
      'trust_score': trustScore,
      'coins': coins,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int?,
      name: map['name'] as String,
      bed: map['bed'] as String?,
      role: map['role'] as String,
      trustScore: map['trust_score'] as int? ?? 0,
      coins: map['coins'] as int? ?? 0,
    );
  }

  AppUser copyWith({
    int? id,
    String? name,
    String? bed,
    String? role,
    int? trustScore,
    int? coins,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      bed: bed ?? this.bed,
      role: role ?? this.role,
      trustScore: trustScore ?? this.trustScore,
      coins: coins ?? this.coins,
    );
  }
}
