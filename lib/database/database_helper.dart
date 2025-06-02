import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const nullableTextType = 'TEXT';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';
    const boolType = 'INTEGER NOT NULL'; // 0 for false, 1 for true

    await db.execute('''
    CREATE TABLE users (
      id $idType,
      name $textType,
      bed $nullableTextType,
      role $textType, -- 'Roommate-Admin', 'Roommate'
      trust_score $integerType DEFAULT 0,
      coins $integerType DEFAULT 0
    )
    ''');

    await db.execute('''
    CREATE TABLE bills (
      id $idType,
      name $textType,
      amount $realType,
      type $textType, -- 'rent', 'utilities', 'custom'
      paid_status $boolType DEFAULT 0,
      due_date $textType, -- Store as ISO8601 String
      bed_pricing_rule $nullableTextType -- JSON string or reference to another table
    )
    ''');

    await db.execute('''
    CREATE TABLE schedules (
      id $idType,
      type $textType, -- 'task', 'meal', 'laundry'
      assignee_id INTEGER, -- Foreign key to users table
      description $textType,
      schedule_time $textType, -- Store as ISO8601 String or relevant format
      is_completed $boolType DEFAULT 0,
      FOREIGN KEY (assignee_id) REFERENCES users (id) ON DELETE SET NULL
    )
    ''');

    // Add other tables here in subsequent steps:
    // Votes, Noticeboards, Investments, Chats

    await db.execute('''
    CREATE TABLE votes (
      id $idType,
      question $textType,
      options $textType, -- JSON string for list of options
      deadline $textType, -- Store as ISO8601 String
      is_anonymous $boolType DEFAULT 1,
      allow_comments $boolType DEFAULT 1
      -- votes and comments might be handled in a separate related table or as JSON
    )
    ''');

    await db.execute('''
    CREATE TABLE noticeboards (
      id $idType,
      message $textType,
      created_at $textType, -- Store as ISO8601 String, default to current time
      is_pinned $boolType DEFAULT 0,
      acknowledged_by $nullableTextType -- JSON string for list of user IDs
    )
    ''');

    await db.execute('''
    CREATE TABLE investments (
      id $idType,
      group_name $textType,
      investment_name $textType,
      -- contributions and returns might be complex; consider JSON or separate tables
      contributions_json $nullableTextType, -- JSON: {'userID': amount, ...}
      returns_percentage $nullableTextType, -- e.g., "3.5" for 3.5%
      calculation_details $nullableTextType -- For storing how returns are applied
    )
    ''');

    await db.execute('''
    CREATE TABLE chats (
      id $idType,
      group_id $textType, -- e.g., 'apartment_wide', 'team_A'
      sender_id INTEGER NOT NULL,
      message $textType,
      timestamp $textType, -- Store as ISO8601 String
      FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''');

    // This is a new table to handle vote responses and comments,
    // as it's a many-to-many relationship or one-to-many with details.
    await db.execute('''
    CREATE TABLE vote_responses (
      id $idType,
      vote_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      selected_option $integerType, -- Index of the option
      comment $nullableTextType,
      voted_at $textType,
      FOREIGN KEY (vote_id) REFERENCES votes (id) ON DELETE CASCADE,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''');
  }

  // Placeholder for CRUD methods - to be added later

  // CRUD methods for Users table
  Future<int> createUser(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('users', row);
  }

  Future<Map<String, dynamic>?> readUser(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      columns: ['id', 'name', 'bed', 'role', 'trust_score', 'coins'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  Future<int> updateUser(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update(
      'users',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await instance.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> readAllUsers() async {
    final db = await instance.database;
    return await db.query('users');
  }

  // CRUD methods for Bills table
  Future<int> createBill(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('bills', row);
  }

  Future<Map<String, dynamic>?> readBill(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'bills',
      columns: ['id', 'name', 'amount', 'type', 'paid_status', 'due_date', 'bed_pricing_rule'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  Future<int> updateBill(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update(
      'bills',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteBill(int id) async {
    final db = await instance.database;
    return await db.delete(
      'bills',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> readAllBills() async {
    final db = await instance.database;
    return await db.query('bills');
  }

  // Placeholder for Schedules CRUD methods
  // Placeholder for Votes CRUD methods
  // Placeholder for Noticeboards CRUD methods
  // Placeholder for Investments CRUD methods
  // Placeholder for Chats CRUD methods
  // Placeholder for VoteResponses CRUD methods

  // Backup and Restore Methods
  Future<String> exportDatabaseToJson() async {
    // Implementation pending
    return "";
  }

  Future<void> importDatabaseFromJson(String jsonString) async {
    // Implementation pending
  }
}
