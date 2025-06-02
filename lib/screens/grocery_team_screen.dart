import 'package:flutter/material.dart';

import 'package:ziberlive/services/data_service.dart';
import '../models/grocery_models.dart';

class GroceryTeamScreen extends StatefulWidget {
  final GroceryTeam team;
  final Function(GroceryItem) onAddItem;

  const GroceryTeamScreen(
      {super.key, required this.team, required this.onAddItem});

  @override
  State<GroceryTeamScreen> createState() => _GroceryTeamScreenState();
}

class _GroceryTeamScreenState extends State<GroceryTeamScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  Future<void> _addItem() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (name.isNotEmpty && amount > 0) {
      final item =
          GroceryItem(name: name, price: amount, quantity: 1, amount: amount);
      widget.onAddItem(item);
      final dataService = DataService();
      final updatedTeam = GroceryTeam(
        id: widget.team.id,
        name: widget.team.name,
        memberIds: widget.team.memberIds,
        items: [...widget.team.items, item],
      );
      await dataService.saveGroceryTeam(updatedTeam);
      _nameController.clear();
      _amountController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Grocery Team')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Item Name'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    decoration: InputDecoration(labelText: 'Amount'),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addItem,
                )
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.team.items.length,
              itemBuilder: (context, idx) {
                final item = widget.team.items[idx];
                return Card(
                  child: ListTile(
                    title: Text(item.name),
                    trailing: Text('\$${item.price.toStringAsFixed(2)}'),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
