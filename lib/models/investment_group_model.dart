class InvestmentGroup {
  final String id;
  final String name;
  final List<String> memberIds;
  final double totalContribution;
  final double monthlyReturn;
  final List<String> chatMessages;

  InvestmentGroup({
    required this.id,
    required this.name,
    required this.memberIds,
    this.totalContribution = 0,
    this.monthlyReturn = 0,
    this.chatMessages = const [],
  });

  factory InvestmentGroup.fromJson(Map<String, dynamic> json) => InvestmentGroup(
    id: json['id'],
    name: json['name'],
    memberIds: List<String>.from(json['memberIds'] ?? []),
    totalContribution: (json['totalContribution'] as num?)?.toDouble() ?? 0,
    monthlyReturn: (json['monthlyReturn'] as num?)?.toDouble() ?? 0,
    chatMessages: List<String>.from(json['chatMessages'] ?? []),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'memberIds': memberIds,
    'totalContribution': totalContribution,
    'monthlyReturn': monthlyReturn,
    'chatMessages': chatMessages,
  };
}
