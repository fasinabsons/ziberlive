class AppUser {
  final int? id; // Nullable for creation, non-null when fetched from DB
  final String name;
  final String? bed;
  final String role; // e.g., 'Roommate-Admin', 'Roommate'
  final int trustScore;
  final int coins; // General purpose coins/points
  // New reward points
  final int communityTreePoints;
  final int incomePoolPoints;
  final int amazonCouponPoints;
  final int payPalPoints;
  final List<String> ownedTreeSkins;

  // Subscription fields
  final String? activeSubscriptionId;
  final DateTime? subscriptionExpiryDate;
  final bool isFreeTrialActive;
  final DateTime? freeTrialExpiryDate;

  AppUser({
    this.id,
    required this.name,
    this.bed,
    required this.role,
    this.trustScore = 0,
    this.coins = 0,
    this.communityTreePoints = 0,
    this.incomePoolPoints = 0,
    this.amazonCouponPoints = 0,
    this.payPalPoints = 0,
    this.ownedTreeSkins = const [],
    // Initialize subscription fields
    this.activeSubscriptionId,
    this.subscriptionExpiryDate,
    this.isFreeTrialActive = false,
    this.freeTrialExpiryDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bed': bed,
      'role': role,
      'trust_score': trustScore,
      'coins': coins,
      'community_tree_points': communityTreePoints,
      'income_pool_points': incomePoolPoints,
      'amazon_coupon_points': amazonCouponPoints,
      'paypal_points': payPalPoints,
      'owned_tree_skins': ownedTreeSkins.join(','),
      // Add subscription fields to map
      'active_subscription_id': activeSubscriptionId,
      'subscription_expiry_date': subscriptionExpiryDate?.toIso8601String(),
      'is_free_trial_active': isFreeTrialActive ? 1 : 0, // Store bool as int
      'free_trial_expiry_date': freeTrialExpiryDate?.toIso8601String(),
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
      communityTreePoints: map['community_tree_points'] as int? ?? 0,
      incomePoolPoints: map['income_pool_points'] as int? ?? 0,
      amazonCouponPoints: map['amazon_coupon_points'] as int? ?? 0,
      payPalPoints: map['paypal_points'] as int? ?? 0,
      ownedTreeSkins: (map['owned_tree_skins'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      // Parse subscription fields from map
      activeSubscriptionId: map['active_subscription_id'] as String?,
      subscriptionExpiryDate: map['subscription_expiry_date'] != null ? DateTime.tryParse(map['subscription_expiry_date']) : null,
      isFreeTrialActive: (map['is_free_trial_active'] as int? ?? 0) == 1, // Parse int to bool
      freeTrialExpiryDate: map['free_trial_expiry_date'] != null ? DateTime.tryParse(map['free_trial_expiry_date']) : null,
    );
  }

  AppUser copyWith({
    int? id,
    String? name,
    String? bed,
    String? role,
    int? trustScore,
    int? coins,
    int? communityTreePoints,
    int? incomePoolPoints,
    int? amazonCouponPoints,
    int? payPalPoints,
    List<String>? ownedTreeSkins,
    String? activeSubscriptionId,
    DateTime? subscriptionExpiryDate,
    bool? isFreeTrialActive,
    DateTime? freeTrialExpiryDate,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      bed: bed ?? this.bed,
      role: role ?? this.role,
      trustScore: trustScore ?? this.trustScore,
      coins: coins ?? this.coins,
      communityTreePoints: communityTreePoints ?? this.communityTreePoints,
      incomePoolPoints: incomePoolPoints ?? this.incomePoolPoints,
      amazonCouponPoints: amazonCouponPoints ?? this.amazonCouponPoints,
      payPalPoints: payPalPoints ?? this.payPalPoints,
      ownedTreeSkins: ownedTreeSkins ?? this.ownedTreeSkins,
      activeSubscriptionId: activeSubscriptionId ?? this.activeSubscriptionId,
      subscriptionExpiryDate: subscriptionExpiryDate ?? this.subscriptionExpiryDate,
      isFreeTrialActive: isFreeTrialActive ?? this.isFreeTrialActive,
      freeTrialExpiryDate: freeTrialExpiryDate ?? this.freeTrialExpiryDate,
    );
  }
}
