import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ziberlive/config.dart' hide kDebugMode;

/// A local storage service that handles both web and mobile/desktop platforms
/// Uses IndexedDB via shared_preferences for web and SQLite for mobile/desktop
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  Database? _database;
  bool _isInitialized = false;

  /// Initialize the storage service
  Future<void> init() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      // No additional initialization needed for web
      if (kDebugMode) {
        debugPrint('Initialized web storage using shared_preferences');
      }
    } else {
      // Initialize SQLite for mobile/desktop
      try {
        await _initDatabase();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error initializing SQLite database: $e');
          debugPrint('Falling back to shared_preferences for storage');
        }
      }
    }

    _isInitialized = true;
  }

  /// Initialize SQLite database for mobile/desktop
  Future<void> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, kDatabaseName);

      _database = await openDatabase(
        path,
        version: kDatabaseVersion,
        onCreate: (db, version) async {
          // Create user table
          await db.execute(
            'CREATE TABLE users(id TEXT PRIMARY KEY, data TEXT)',
          );
          // Create bills table
          await db.execute(
            'CREATE TABLE bills(id TEXT PRIMARY KEY, data TEXT)',
          );
          // Create tasks table
          await db.execute(
            'CREATE TABLE tasks(id TEXT PRIMARY KEY, data TEXT)',
          );
          // Create votes table
          await db.execute(
            'CREATE TABLE votes(id TEXT PRIMARY KEY, data TEXT)',
          );
          // Create settings table
          await db.execute(
            'CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT)',
          );
          // Create grocery teams table
          await db.execute(
            'CREATE TABLE grocery_teams(id TEXT PRIMARY KEY, data TEXT)',
          );
          // Create grocery receipts table
          await db.execute(
            'CREATE TABLE grocery_receipts(id TEXT PRIMARY KEY, data TEXT)',
          );
        },
      );

      if (kDebugMode) {
        debugPrint('Initialized SQLite database at $path');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing database: $e');
      }
      rethrow;
    }
  }

  /// Save data to storage
  Future<void> saveData(String table, String id, Map<String, dynamic> data) async {
    if (!_isInitialized) await init();

    if (kIsWeb || _database == null) {
      // Use shared_preferences for web or if database failed to initialize
      final prefs = await SharedPreferences.getInstance();
      final key = '${table}_$id';
      await prefs.setString(key, jsonEncode(data));
    } else {
      // Use SQLite for mobile/desktop
      await _database?.insert(
        table,
        {
          'id': id,
          'data': jsonEncode(data),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Get data from storage
  Future<Map<String, dynamic>?> getData(String table, String id) async {
    if (!_isInitialized) await init();

    if (kIsWeb || _database == null) {
      // Use shared_preferences for web or if database failed to initialize
      final prefs = await SharedPreferences.getInstance();
      final key = '${table}_$id';
      final jsonData = prefs.getString(key);
      if (jsonData == null) return null;
      return jsonDecode(jsonData) as Map<String, dynamic>;
    } else {
      // Use SQLite for mobile/desktop
      final List<Map<String, dynamic>>? maps = await _database?.query(
        table,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps == null || maps.isEmpty) return null;
      return jsonDecode(maps.first['data']) as Map<String, dynamic>;
    }
  }

  /// Get all data from a table
  Future<List<Map<String, dynamic>>> getAllData(String table) async {
    if (!_isInitialized) await init();

    if (kIsWeb || _database == null) {
      // Use shared_preferences for web or if database failed to initialize
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final tableKeys = allKeys.where((key) => key.startsWith('${table}_'));
      
      final result = <Map<String, dynamic>>[];
      for (final key in tableKeys) {
        final jsonData = prefs.getString(key);
        if (jsonData != null) {
          result.add(jsonDecode(jsonData) as Map<String, dynamic>);
        }
      }
      return result;
    } else {
      // Use SQLite for mobile/desktop
      final List<Map<String, dynamic>> maps = await _database?.query(table) ?? [];
      return maps.map((map) => jsonDecode(map['data'] as String) as Map<String, dynamic>).toList();
    }
  }

  /// Delete data from storage
  Future<void> deleteData(String table, String id) async {
    if (!_isInitialized) await init();

    if (kIsWeb || _database == null) {
      // Use shared_preferences for web or if database failed to initialize
      final prefs = await SharedPreferences.getInstance();
      final key = '${table}_$id';
      await prefs.remove(key);
    } else {
      // Use SQLite for mobile/desktop
      await _database?.delete(
        table,
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  /// Delete all data from a table
  Future<void> deleteAllData(String table) async {
    if (!_isInitialized) await init();

    if (kIsWeb || _database == null) {
      // Use shared_preferences for web or if database failed to initialize
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final tableKeys = allKeys.where((key) => key.startsWith('${table}_'));
      
      for (final key in tableKeys) {
        await prefs.remove(key);
      }
    } else {
      // Use SQLite for mobile/desktop
      await _database?.delete(table);
    }
  }

  /// Save a setting
  Future<void> saveSetting(String key, String value) async {
    if (!_isInitialized) await init();

    if (kIsWeb || _database == null) {
      // Use shared_preferences for web or if database failed to initialize
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('setting_$key', value);
    } else {
      // Use SQLite for mobile/desktop
      await _database?.insert(
        'settings',
        {
          'key': key,
          'value': value,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Get a setting
  Future<String?> getSetting(String key) async {
    if (!_isInitialized) await init();

    if (kIsWeb || _database == null) {
      // Use shared_preferences for web or if database failed to initialize
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('setting_$key');
    } else {
      // Use SQLite for mobile/desktop
      final List<Map<String, dynamic>>? maps = await _database?.query(
        'settings',
        where: 'key = ?',
        whereArgs: [key],
      );

      if (maps == null || maps.isEmpty) return null;
      return maps.first['value'] as String;
    }
  }
} 