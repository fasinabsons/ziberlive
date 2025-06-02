import 'dart:typed_data';
import '../models/grocery_receipt_model.dart';

class OCRReceiptService {
  Future<List<GroceryItem>> extractItemsFromImage(Uint8List imageBytes) async {
    // Mock implementation that returns sample grocery items
    // In a real app, this would use ML Kit or another OCR service

    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 1));

    // Return mock grocery items
    return [
      GroceryItem(name: 'Milk', price: 3.99, quantity: 1),
      GroceryItem(name: 'Bread', price: 2.49, quantity: 2),
      GroceryItem(name: 'Eggs', price: 4.99, quantity: 1),
      GroceryItem(name: 'Cheese', price: 5.99, quantity: 1),
      GroceryItem(name: 'Apples', price: 0.99, quantity: 5),
    ];
  }
}
