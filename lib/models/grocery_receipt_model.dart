import 'dart:typed_data';

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
}

class GroceryItem {
  final String name;
  final double price;
  final int quantity;

  GroceryItem({
    required this.name,
    required this.price,
    required this.quantity,
  });
}
