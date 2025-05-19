import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'botko.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Social Accounts table
    await db.execute('''
      CREATE TABLE social_accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        platform TEXT NOT NULL,
        username TEXT NOT NULL,
        token TEXT NOT NULL,
        refreshToken TEXT,
        tokenExpiry TEXT,
        isActive INTEGER NOT NULL
      )
    ''');

    // Content Items table
    await db.execute('''
      CREATE TABLE content_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        mediaUrls TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        status TEXT NOT NULL
      )
    ''');

    // Scheduled Posts table
    await db.execute('''
      CREATE TABLE scheduled_posts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contentItemId INTEGER NOT NULL,
        socialAccountId INTEGER NOT NULL,
        scheduledTime TEXT NOT NULL,
        status TEXT NOT NULL,
        failureReason TEXT,
        FOREIGN KEY (contentItemId) REFERENCES content_items (id),
        FOREIGN KEY (socialAccountId) REFERENCES social_accounts (id)
      )
    ''');
  }

  // CRUD operations for Social Accounts
  Future<int> insertSocialAccount(Map<String, dynamic> account) async {
    Database db = await database;
    return await db.insert('social_accounts', account);
  }

  Future<List<Map<String, dynamic>>> getSocialAccounts() async {
    Database db = await database;
    return await db.query('social_accounts');
  }

  Future<Map<String, dynamic>?> getSocialAccount(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'social_accounts',
      where: 'id = ?',
      whereArgs: [id],
    );

    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateSocialAccount(Map<String, dynamic> account) async {
    Database db = await database;
    return await db.update(
      'social_accounts',
      account,
      where: 'id = ?',
      whereArgs: [account['id']],
    );
  }

  Future<int> deleteSocialAccount(int id) async {
    Database db = await database;
    return await db.delete(
      'social_accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

// Similar CRUD operations can be implemented for content_items and scheduled_posts
}