import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class BackupService {
  Future<void> exportData(Map<String, dynamic> data) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/colivify_backup.json');
    await file.writeAsString(jsonEncode(data));
  }

  Future<Map<String, dynamic>> importData() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/colivify_backup.json');
    if (await file.exists()) {
      return jsonDecode(await file.readAsString());
    }
    return {};
  }
}
