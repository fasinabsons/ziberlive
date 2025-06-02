class GroceryTeam {
  final String id;
  final String name;
  final List<String> memberIds;
  final List<GroceryItem> items;

  GroceryTeam({
    required this.id,
    required this.name,
    required this.memberIds,
    this.items = const [],
  });

  factory GroceryTeam.fromJson(Map<String, dynamic> json) => GroceryTeam(
    id: json['id'],
    name: json['name'],
    memberIds: List<String>.from(json['memberIds'] ?? []),
    items: (json['items'] as List<dynamic>? ?? []).map((e) => GroceryItem.fromJson(e)).toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'memberIds': memberIds,
    'items': items.map((e) => e.toJson()).toList(),
  };
}

class GroceryItem {
  final String name;
  final double amount;

  GroceryItem({required this.name, required this.amount});

  factory GroceryItem.fromJson(Map<String, dynamic> json) => GroceryItem(
    name: json['name'],
    amount: (json['amount'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount,
  };
}
