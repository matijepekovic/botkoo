import 'package:botko/core/models/content_item.dart';
import 'package:botko/data/local/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class ContentRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Create a new content item
  Future<int> createContent(ContentItem item) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      'content_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all content items
  Future<List<ContentItem>> getAllContent() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('content_items');

    return List.generate(maps.length, (i) {
      return ContentItem.fromMap(maps[i]);
    });
  }

  // Get content items by status
  Future<List<ContentItem>> getContentByStatus(String status) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'content_items',
      where: 'status = ?',
      whereArgs: [status],
    );

    return List.generate(maps.length, (i) {
      return ContentItem.fromMap(maps[i]);
    });
  }

  // Update a content item
  Future<int> updateContent(ContentItem item) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'content_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // Delete a content item
  Future<int> deleteContent(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'content_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}