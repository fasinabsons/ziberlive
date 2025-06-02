import 'dart:typed_data';

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

class GroceryReceipt {
  final String id;
  final String teamId;
  final String buyerId;
  final DateTime date;
  final List<GroceryItem> items;
  final double total;
  final Uint8List? receiptImage;

  GroceryReceipt({
    required this.id,
    required this.teamId,
    required this.buyerId,
    required this.date,
    required this.items,
    required this.total,
    this.receiptImage,
  });

  factory GroceryReceipt.fromJson(Map<String, dynamic> json) => GroceryReceipt(
        id: json['id'],
        teamId: json['teamId'],
        buyerId: json['buyerId'],
        date: DateTime.parse(json['date']),
        items: (json['items'] as List<dynamic>).map((e) => GroceryItem.fromJson(e)).toList(),
        total: (json['total'] as num).toDouble(),
        receiptImage: json['receiptImage'] != null ? Uint8List.fromList(List<int>.from(json['receiptImage'])) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'teamId': teamId,
        'buyerId': buyerId,
        'date': date.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'total': total,
        'receiptImage': receiptImage != receiptImage!.toList(),
      };
}

class GroceryItem {
  final String name;
  final double price;
  final int quantity;
  final double? amount; // For backward compatibility with GroceryTeamScreen

  GroceryItem({
    required this.name,
    required this.price,
    required this.quantity,
    this.amount,
  });

  factory GroceryItem.fromJson(Map<String, dynamic> json) => GroceryItem(
        name: json['name'],
        price: (json['price'] ?? json['amount'] ?? 0.0) as double,
        quantity: json['quantity'] ?? 1,
        amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'quantity': quantity,
        'amount': amount?.toDouble(),
      };
}
