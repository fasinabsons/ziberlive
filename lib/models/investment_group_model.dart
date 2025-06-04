class InvestmentGroup {
  final String id;
  final String name;
  final List<String> memberIds;
  final double totalContribution;
  final double monthlyReturn;
  final List<String> chatMessages;
  final DateTime lastModified; // New field

  InvestmentGroup({
    required this.id,
    required this.name,
    required this.memberIds,
    this.totalContribution = 0,
    this.monthlyReturn = 0,
    this.chatMessages = const [],
    DateTime? lastModified, // Optional in constructor
  }) : lastModified = lastModified ?? DateTime.now(); // Default to now

  factory InvestmentGroup.fromJson(Map<String, dynamic> json) => InvestmentGroup(
    id: json['id'],
    name: json['name'],
    memberIds: List<String>.from(json['memberIds'] ?? []),
    totalContribution: (json['totalContribution'] as num?)?.toDouble() ?? 0,
    monthlyReturn: (json['monthlyReturn'] as num?)?.toDouble() ?? 0,
    chatMessages: List<String>.from(json['chatMessages'] ?? []),
    lastModified: json['lastModified'] != null ? DateTime.parse(json['lastModified']) : DateTime.now(), // Parse from JSON
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'memberIds': memberIds,
    'totalContribution': totalContribution,
    'monthlyReturn': monthlyReturn,
    'chatMessages': chatMessages,
    'lastModified': lastModified.toIso8601String(), // Add to JSON
  };
}
