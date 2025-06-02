import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDBService {
  static final LocalDBService _instance = LocalDBService._internal();
  factory LocalDBService() => _instance;
  LocalDBService._internal();

  Database? _db;

  Future<void> initDB() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(join(dbPath, 'colivify.db'), version: 1, onCreate: (db, version) async {
      await db.execute('''CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT,
        role TEXT,
        credits INTEGER
      )''');
      await db.execute('''CREATE TABLE bills (
        id TEXT PRIMARY KEY,
        name TEXT,
        amount REAL,
        dueDate TEXT,
        paidBy TEXT,
        splitAmong TEXT
      )''');
      await db.execute('''CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        assignedTo TEXT,
        dueDate TEXT,
        completed INTEGER
      )''');
      await db.execute('''CREATE TABLE votes (
        id TEXT PRIMARY KEY,
        title TEXT,
        options TEXT,
        results TEXT,
        endDate TEXT
      )''');
      await db.execute('''CREATE TABLE laundry_schedules (
        id TEXT PRIMARY KEY,
        userId TEXT,
        dayOfWeek TEXT,
        timeSlot TEXT
      )''');
      // Add other tables as needed
    });
  }

  Database? get db => _db;

  // Example CRUD for users
  Future<void> insertUser(Map<String, dynamic> user) async {
    await _db?.insert('users', user, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    return await _db?.query('users') ?? [];
  }

  // Add CRUD methods for bills, tasks, votes, laundry_schedules, etc.
}
