// lib/data/local/database_helper.dart
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
// Import only the sqflite_common_ffi package since it provides all needed elements
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  // Add this initialization method for desktop platforms
  static void initialize() {
    if (!kIsWeb) {
      if (Platform.isWindows || Platform.isLinux) {
        // Initialize FFI for Windows/Linux
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'botko.db');
    return await openDatabase(
      path,
      version: 2, // Increment version for migration
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
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
        isActive INTEGER NOT NULL,
        platformSpecificData TEXT
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
        status TEXT NOT NULL,
        platformMetadata TEXT
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
        platformSpecificParams TEXT,
        FOREIGN KEY (contentItemId) REFERENCES content_items (id),
        FOREIGN KEY (socialAccountId) REFERENCES social_accounts (id)
      )
    ''');
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Previous migration steps
      await db.execute('ALTER TABLE social_accounts ADD COLUMN platformSpecificData TEXT');
      await db.execute('ALTER TABLE content_items ADD COLUMN platformMetadata TEXT');
      await db.execute('ALTER TABLE scheduled_posts ADD COLUMN platformSpecificParams TEXT');
    }

    if (oldVersion < 3) {
      // Add new columns for the enhanced content type system
      await db.execute('ALTER TABLE content_items ADD COLUMN contentType TEXT');
      await db.execute('ALTER TABLE content_items ADD COLUMN metadata TEXT');

      // Update existing records to have a default content type based on media
      final List<Map<String, dynamic>> existingContent = await db.query('content_items');
      for (final item in existingContent) {
        final contentId = item['id'];
        final mediaUrls = item['mediaUrls'] as String? ?? '';
        final content = item['content'] as String? ?? '';

        // Determine content type
        String contentType;
        if (mediaUrls.isEmpty) {
          contentType = 'ContentType.textOnly';
        } else if (mediaUrls.contains('.mp4') || mediaUrls.contains('.mov')) {
          contentType = 'ContentType.shortVideo';
        } else if (mediaUrls.contains('.jpg') || mediaUrls.contains('.png')) {
          contentType = content.isEmpty ? 'ContentType.image' : 'ContentType.textWithImage';
        } else {
          contentType = 'ContentType.textOnly';
        }

        // Create default metadata
        final Map<String, dynamic> metadata = {
          'visibility': 'ContentVisibility.public',
        };

        // Update the record
        await db.update(
          'content_items',
          {
            'contentType': contentType,
            'metadata': jsonEncode(metadata),
          },
          where: 'id = ?',
          whereArgs: [contentId],
        );
      }
    }
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
}