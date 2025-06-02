import 'package:flutter/material.dart';
import '../models/investment_group_model.dart';

class InvestmentGroupScreen extends StatefulWidget {
  final List<InvestmentGroup> groups;
  final Function(InvestmentGroup) onAddGroup;
  final Function(String, String) onSendMessage;

  const InvestmentGroupScreen({super.key, required this.groups, required this.onAddGroup, required this.onSendMessage});

  @override
  State<InvestmentGroupScreen> createState() => _InvestmentGroupScreenState();
}

class _InvestmentGroupScreenState extends State<InvestmentGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String? selectedGroupId;

  void _addGroup() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final group = InvestmentGroup(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        memberIds: [],
      );
      widget.onAddGroup(group);
      _nameController.clear();
    }
  }

  void _sendMessage() {
    if (selectedGroupId != null && _messageController.text.trim().isNotEmpty) {
      widget.onSendMessage(selectedGroupId!, _messageController.text.trim());
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Investment Groups')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Group Name'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addGroup,
                )
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.groups.length,
              itemBuilder: (context, idx) {
                final group = widget.groups[idx];
                return Card(
                  child: ListTile(
                    title: Text(group.name),
                    subtitle: Text('Total: ${group.totalContribution.toStringAsFixed(2)} | Return: ${group.monthlyReturn.toStringAsFixed(2)}'),
                    onTap: () => setState(() => selectedGroupId = group.id),
                    selected: selectedGroupId == group.id,
                  ),
                );
              },
            ),
          ),
          if (selectedGroupId != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(labelText: 'Message'),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _sendMessage,
                  )
                ],
              ),
            )
        ],
      ),
    );
  }
}
