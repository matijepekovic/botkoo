// lib/data/local/content_repository.dart
import 'dart:convert';
import 'package:botko/core/models/content_item.dart';
import 'package:botko/data/local/database_helper.dart';
import 'package:botko/core/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

class ContentRepository {
  static const String _tag = 'ContentRepository';
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Enhanced createContent method with detailed logging
  Future<int> createContent(ContentItem item) async {
    final db = await _databaseHelper.database;

    Logger.i(_tag, '=== SAVING TO DATABASE ===');
    Logger.i(_tag, 'Item title: ${item.title}');
    Logger.i(_tag, 'Item contentType: ${item.contentType.toString()}');
    Logger.i(_tag, 'Item mediaUrls: ${item.mediaUrls.length} files');

    // Convert platformMetadata to JSON string if present
    final Map<String, dynamic> itemMap = item.toMap();
    Logger.i(_tag, 'ItemMap contentType: ${itemMap['contentType']}');
    Logger.i(_tag, 'ItemMap mediaUrls: ${itemMap['mediaUrls']}');

    if (item.platformMetadata != null) {
      itemMap['platformMetadata'] = jsonEncode(item.platformMetadata);
    }

    final id = await db.insert(
      'content_items',
      itemMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    Logger.i(_tag, 'Database insert completed with ID: $id');
    Logger.i(_tag, '=== DATABASE SAVE COMPLETE ===');

    return id;
  }

  // FIXED: Get all content items using ContentItem.fromMap()
  Future<List<ContentItem>> getAllContent() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('content_items');

    Logger.i(_tag, '=== LOADING FROM DATABASE ===');
    Logger.i(_tag, 'Found ${maps.length} content items in database');

    return List.generate(maps.length, (i) {
      final Map<String, dynamic> map = maps[i];

      Logger.i(_tag, 'Loading item: ${map['title']}');
      Logger.i(_tag, 'Raw contentType from DB: ${map['contentType']}');
      Logger.i(_tag, 'Raw mediaUrls from DB: ${map['mediaUrls']}');
      Logger.i(_tag, 'Raw metadata from DB: ${map['metadata']}');

      // CRITICAL FIX: Use ContentItem.fromMap() to properly parse all fields including contentType
      final contentItem = ContentItem.fromMap(map);

      Logger.i(_tag, 'Loaded item "${contentItem.title}" with type: ${contentItem.contentType.toString()}');
      Logger.i(_tag, 'Loaded item mediaUrls: ${contentItem.mediaUrls.length}');

      return contentItem;
    });
  }

  // FIXED: Get content items by status using ContentItem.fromMap()
  Future<List<ContentItem>> getContentByStatus(String status) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'content_items',
      where: 'status = ?',
      whereArgs: [status],
    );

    Logger.i(_tag, '=== LOADING BY STATUS: $status ===');
    Logger.i(_tag, 'Found ${maps.length} content items with status $status');

    return List.generate(maps.length, (i) {
      final Map<String, dynamic> map = maps[i];

      Logger.i(_tag, 'Loading item: ${map['title']}');
      Logger.i(_tag, 'Raw contentType from DB: ${map['contentType']}');

      // CRITICAL FIX: Use ContentItem.fromMap() to properly parse all fields including contentType
      final contentItem = ContentItem.fromMap(map);

      Logger.i(_tag, 'Loaded item "${contentItem.title}" with type: ${contentItem.contentType.toString()}');

      return contentItem;
    });
  }

  // Update a content item
  Future<int> updateContent(ContentItem item) async {
    Logger.i(_tag, '=== UPDATING CONTENT ===');
    Logger.i(_tag, 'Updating item: ${item.title}');
    Logger.i(_tag, 'Item contentType: ${item.contentType.toString()}');
    Logger.i(_tag, 'Item mediaUrls: ${item.mediaUrls.length} files');

    final db = await _databaseHelper.database;

    // Convert platformMetadata to JSON string if present
    final Map<String, dynamic> itemMap = item.toMap();
    if (item.platformMetadata != null) {
      itemMap['platformMetadata'] = jsonEncode(item.platformMetadata);
    }

    Logger.i(_tag, 'ItemMap contentType: ${itemMap['contentType']}');
    Logger.i(_tag, 'ItemMap mediaUrls: ${itemMap['mediaUrls']}');

    final result = await db.update(
      'content_items',
      itemMap,
      where: 'id = ?',
      whereArgs: [item.id],
    );

    Logger.i(_tag, 'Update completed, rows affected: $result');
    Logger.i(_tag, '=== UPDATE COMPLETE ===');

    return result;
  }

  // Delete a content item
  Future<int> deleteContent(int id) async {
    Logger.i(_tag, '=== DELETING CONTENT ===');
    Logger.i(_tag, 'Deleting content with ID: $id');

    final db = await _databaseHelper.database;
    final result = await db.delete(
      'content_items',
      where: 'id = ?',
      whereArgs: [id],
    );

    Logger.i(_tag, 'Delete completed, rows affected: $result');
    Logger.i(_tag, '=== DELETE COMPLETE ===');

    return result;
  }
}