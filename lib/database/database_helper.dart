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

    return await openDatabase(path, version: 7, onCreate: _createDB, onUpgrade: _onUpgradeDB); // Incremented version to 7
  }

  Future _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE users ADD COLUMN community_tree_points INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE users ADD COLUMN income_pool_points INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE users ADD COLUMN amazon_coupon_points INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE users ADD COLUMN paypal_points INTEGER DEFAULT 0");
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE users ADD COLUMN owned_tree_skins TEXT DEFAULT ''");
    }
    if (oldVersion < 4) {
      await db.execute("ALTER TABLE users ADD COLUMN active_subscription_id TEXT");
      await db.execute("ALTER TABLE users ADD COLUMN subscription_expiry_date TEXT");
      await db.execute("ALTER TABLE users ADD COLUMN is_free_trial_active INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE users ADD COLUMN free_trial_expiry_date TEXT");
    }
    if (oldVersion < 5) {
      await db.execute("ALTER TABLE users ADD COLUMN last_modified TEXT"); // Default handled by AppUser model or later by DEFAULT clause in v7
      await db.execute("ALTER TABLE schedules ADD COLUMN last_modified TEXT");
      await db.execute("ALTER TABLE votes ADD COLUMN last_modified TEXT");
      await db.execute("ALTER TABLE investments ADD COLUMN last_modified TEXT");
      // Note: bills.last_modified and noticeboards.last_modified were added directly to _createDB in v5 logic,
      // but if these tables could exist from before v5 without it, migration is needed.
      // Assuming they were new enough or handled. If not, add their ALTER TABLE here for < 5.
    }
    if (oldVersion < 6) {
      // Add last_modified to tables that might have missed it if created before default was added,
      // or for tables like chats that didn't have it yet.
      // Safe to run even if column exists if using ADD COLUMN with proper checks or if DB handles it.
      // However, typical SQLite `ADD COLUMN` fails if column exists. Better to check.
      // For simplicity here, we assume these are for tables that definitely didn't have it.
      // A more robust migration checks `PRAGMA table_info(table_name);`
      await _addColumnIfNotExists(db, 'bills', 'last_modified TEXT DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))');
      await _addColumnIfNotExists(db, 'noticeboards', 'last_modified TEXT DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))');
      await _addColumnIfNotExists(db, 'chats', 'last_modified TEXT DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))');
    }
    if (oldVersion < 7) {
      await _addColumnIfNotExists(db, 'users', 'is_device_lost INTEGER DEFAULT 0');
      // Ensure last_modified on users has a default if it was added in v5 without one.
      // This specific ALTER might fail if the column already has a default or is being added.
      // It's safer to add DEFAULT when column is created. For now, this is a catch-all.
      // await db.execute("ALTER TABLE users ALTER COLUMN last_modified SET DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))"); // This syntax is not standard SQLite.
      // SQLite requires recreating table to add default to existing column or change it.
      // The createDB statement for users already adds DEFAULT for last_modified.
      // If user.last_modified was added in v5 without default, new inserts would be null.
      // For simplicity, we assume new inserts get default from model or DB, and old rows might have null.
    }
    // if (oldVersion < 8) { ... }
  }

  // Helper function to add a column only if it doesn't exist
  Future<void> _addColumnIfNotExists(DatabaseExecutor db, String tableName, String columnDefinition) async {
    var columnName = columnDefinition.split(" ")[0];
    var tableInfo = await db.rawQuery('PRAGMA table_info("$tableName")');
    bool columnExists = tableInfo.any((col) => col['name'] == columnName);
    if (!columnExists) {
      await db.execute('ALTER TABLE "$tableName" ADD COLUMN $columnDefinition');
    }
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
      coins $integerType DEFAULT 0,
      community_tree_points $integerType DEFAULT 0,
      income_pool_points $integerType DEFAULT 0,
      amazon_coupon_points $integerType DEFAULT 0,
      paypal_points $integerType DEFAULT 0,
      owned_tree_skins $textType DEFAULT '',
      active_subscription_id $nullableTextType,
      subscription_expiry_date $nullableTextType,
      is_free_trial_active $boolType DEFAULT 0,
      free_trial_expiry_date $nullableTextType,
      last_modified $textType DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
      is_device_lost $boolType DEFAULT 0
    )
    ''');

    await db.execute('''
    CREATE TABLE bills (
      id $idType,
      name $textType,
      amount $realType,
      type $textType, -- 'rent', 'utilities', 'custom'
      paid_status $boolType DEFAULT 0,
      due_date $textType,
      bed_pricing_rule $nullableTextType,
      last_modified $textType DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')) -- Assuming bills also need this
    )
    ''');

    await db.execute('''
    CREATE TABLE schedules (
      id $idType,
      type $textType,
      assignee_id INTEGER,
      description $textType,
      schedule_time $textType,
      is_completed $boolType DEFAULT 0,
      last_modified $textType DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
      FOREIGN KEY (assignee_id) REFERENCES users (id) ON DELETE SET NULL
    )
    ''');

    // Votes, Noticeboards, Investments, Chats

    await db.execute('''
    CREATE TABLE votes (
      id $idType,
      question $textType,
      options $textType,
      deadline $textType,
      is_anonymous $boolType DEFAULT 1,
      allow_comments $boolType DEFAULT 1,
      last_modified $textType DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
    )
    ''');

    // Assuming Noticeboards table was intended to be created:
    await db.execute('''
    CREATE TABLE IF NOT EXISTS noticeboards (
      id $idType,
      message $textType,
      created_at $textType DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
      is_pinned $boolType DEFAULT 0,
      acknowledged_by $nullableTextType,
      last_modified $textType DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
    )
    ''');

    await db.execute('''
    CREATE TABLE investments (
      id $idType,
      group_name $textType,
      investment_name $textType,
      contributions_json $nullableTextType,
      returns_percentage $nullableTextType,
      calculation_details $nullableTextType,
      last_modified $textType DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
    )
    ''');

    await db.execute('''
    CREATE TABLE chats (
      id $idType,
      group_id $textType,
      sender_id INTEGER NOT NULL,
      message $textType,
      timestamp $textType,
      last_modified $textType DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
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
      columns: [
        'id', 'name', 'bed', 'role', 'trust_score', 'coins',
        'community_tree_points', 'income_pool_points', 'amazon_coupon_points', 'paypal_points',
        'owned_tree_skins',
        'active_subscription_id', 'subscription_expiry_date',
        'is_free_trial_active', 'free_trial_expiry_date',
        'last_modified',
        'is_device_lost' // Added is_device_lost
      ],
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
    // Ensure all columns are fetched if AppUser.fromMap expects them all.
    // Querying without explicit columns list fetches all, which is also an option.
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
      columns: ['id', 'name', 'amount', 'type', 'paid_status', 'due_date', 'bed_pricing_rule', 'last_modified'],
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
