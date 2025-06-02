import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/grocery_models.dart';

import 'package:ziberlive/services/data_service.dart';
import 'package:ziberlive/services/ocr_receipt_service.dart';
import '../widgets/audit_trail_widget.dart';

class GroceryReceiptScreen extends StatefulWidget {
  final String teamId;
  final String buyerId;
  final Function(GroceryReceipt) onSave;
  const GroceryReceiptScreen(
      {required this.teamId,
      required this.buyerId,
      required this.onSave,
      super.key});
  @override
  State<GroceryReceiptScreen> createState() => _GroceryReceiptScreenState();
}

class _GroceryReceiptScreenState extends State<GroceryReceiptScreen> {
  Uint8List? _receiptImage;
  List<GroceryItem> _items = [];
  double _total = 0.0;
  bool _loading = false;
  final List<String> _auditTrail = [];
  List<String> _teamMembers = [];

  final OCRReceiptService _ocrService = OCRReceiptService();

  @override
  void initState() {
    super.initState();
    _loadTeamMembers();
  }

  Future<void> _loadTeamMembers() async {
    final dataService = DataService();
    final teams = await dataService.getGroceryTeams();
    final team = teams.firstWhere((t) => t.id == widget.teamId,
        orElse: () => GroceryTeam(id: widget.teamId, name: '', memberIds: []));
    setState(() {
      _teamMembers = List<String>.from(team.memberIds);
    });
  }

  bool _isEligibleTeamMember(String userId) {
    return _teamMembers.contains(userId);
  }

  void _pickImage() async {
    try {
      // Mock image picker - creates a simple colored rectangle as placeholder
      // In a real app, this would use image_picker package
      final int width = 300;
      final int height = 400;
      final int bytesPerPixel = 4; // RGBA

      final Uint8List bytes = Uint8List(width * height * bytesPerPixel);

      // Fill with a random color
      final int r = math.Random().nextInt(255);
      final int g = math.Random().nextInt(255);
      final int b = math.Random().nextInt(255);

      for (int i = 0; i < bytes.length; i += bytesPerPixel) {
        bytes[i] = r; // R
        bytes[i + 1] = g; // G
        bytes[i + 2] = b; // B
        bytes[i + 3] = 255; // A (fully opaque)
      }

      setState(() {
        _receiptImage = bytes;
        _auditTrail.add('Mock image created');
      });
    } catch (e) {
      _auditTrail.add('Error creating mock image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating mock image: $e')),
      );
      setState(() {});
    }
  }

  void _scanReceipt() async {
    if (_receiptImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a receipt image first.')),
      );
      _auditTrail.add('Scan failed: No image selected');
      setState(() {});
      return;
    }
    setState(() => _loading = true);
    final items = await _ocrService.extractItemsFromImage(_receiptImage!);
    setState(() {
      _items = List<GroceryItem>.from(items);
      _total = items.fold(0.0, (sum, item) => sum + item.price * item.quantity);
      _auditTrail.add('Receipt scanned: ${items.length} items detected');
      _loading = false;
    });
  }

void _saveReceipt() async {
  // Example: Only allow save if at least one item and total > 0
  if (_items.isEmpty || _total <= 0.0) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add at least one item and ensure total is positive.'),
      ),
    );
    _auditTrail.add('Save failed: No items or total <= 0');
    setState(() {});
    return;
  }

  // Eligibility check (example: buyer must be in team)
  if (!_isEligibleTeamMember(widget.buyerId)) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Buyer is not eligible for this team.')),
    );
    _auditTrail.add('Save failed: Buyer not eligible');
    setState(() {});
    return;
  }

  final receipt = GroceryReceipt(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    teamId: widget.teamId,
    buyerId: widget.buyerId,
    date: DateTime.now(),
    items: _items,
    total: _total,
    receiptImage: _receiptImage,
  );

  final dataService = DataService();
  await dataService.saveGroceryReceipt(receipt);
  widget.onSave(receipt);

  _auditTrail.add('Receipt saved for team ${widget.teamId} by ${widget.buyerId}');

  // ✅ Check mounted before using context after await
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Receipt saved successfully')),
  );

  // ✅ Check again before navigation
  if (!mounted) return;
  Navigator.pop(context);
}
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Grocery Receipt')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_auditTrail.isNotEmpty)
              SizedBox(
                height: 120,
                child: AuditTrailWidget(logs: _auditTrail),
              ),
            if (_receiptImage != null)
              Image.memory(_receiptImage!, height: 180),
            if (_loading) const CircularProgressIndicator(),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Pick Image'),
                  onPressed: _pickImage,
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.document_scanner),
                  label: const Text('Scan'),
                  onPressed: _scanReceipt,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, idx) {
                  final item = _items[idx];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text('x${item.quantity}'),
                    trailing: SizedBox(
                      width: 100,
                      child: TextFormField(
                        initialValue: item.price.toStringAsFixed(2),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Price'),
                        onChanged: (v) {
                          setState(() {
                            _items[idx] = GroceryItem(
                              name: item.name,
                              price: double.tryParse(v) ?? item.price,
                              quantity: item.quantity,
                            );
                            _total = _items.fold(
                                0.0, (sum, it) => sum + it.price * it.quantity);
                          });
                        },
                      ),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _items.removeAt(idx);
                          _total = _items.fold(
                              0.0, (sum, it) => sum + it.price * it.quantity);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            Text('Total: ${_total.toStringAsFixed(2)}',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _items.isNotEmpty ? _saveReceipt : null,
              child: const Text('Save Receipt'),
            )
          ],
        ),
      ),
    );
  }
}
