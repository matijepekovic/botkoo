// lib/data/local/content_repository.dart
import 'dart:convert';
import 'package:botko/core/models/content_item.dart';
import 'package:botko/data/local/database_helper.dart';
import 'package:botko/core/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

class ContentRepository {
  static const String _tag = 'ContentRepository';
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Create a new content item
  Future<int> createContent(ContentItem item) async {
    final db = await _databaseHelper.database;

    // Convert platformMetadata to JSON string if present
    final Map<String, dynamic> itemMap = item.toMap();
    if (item.platformMetadata != null) {
      itemMap['platformMetadata'] = jsonEncode(item.platformMetadata);
    }

    return await db.insert(
      'content_items',
      itemMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all content items
  Future<List<ContentItem>> getAllContent() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('content_items');

    return List.generate(maps.length, (i) {
      final Map<String, dynamic> map = maps[i];

      // Parse platformMetadata from JSON string
      Map<String, dynamic>? platformMetadata;
      if (map['platformMetadata'] != null) {
        try {
          platformMetadata = jsonDecode(map['platformMetadata']);
        } catch (e) {
          Logger.e(_tag, 'Error parsing platformMetadata', e);
        }
      }

      return ContentItem(
        id: map['id'],
        title: map['title'],
        content: map['content'],
        mediaUrls: map['mediaUrls'] != null && map['mediaUrls'].isNotEmpty
            ? map['mediaUrls'].split(',')
            : [],
        createdAt: DateTime.parse(map['createdAt']),
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'])
            : null,
        status: map['status'],
        platformMetadata: platformMetadata,
      );
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
      final Map<String, dynamic> map = maps[i];

      // Parse platformMetadata from JSON string
      Map<String, dynamic>? platformMetadata;
      if (map['platformMetadata'] != null) {
        try {
          platformMetadata = jsonDecode(map['platformMetadata']);
        } catch (e) {
          Logger.e(_tag, 'Error parsing platformMetadata', e);
        }
      }

      return ContentItem(
        id: map['id'],
        title: map['title'],
        content: map['content'],
        mediaUrls: map['mediaUrls'] != null && map['mediaUrls'].isNotEmpty
            ? map['mediaUrls'].split(',')
            : [],
        createdAt: DateTime.parse(map['createdAt']),
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'])
            : null,
        status: map['status'],
        platformMetadata: platformMetadata,
      );
    });
  }

  // Update a content item
  Future<int> updateContent(ContentItem item) async {
    final db = await _databaseHelper.database;

    // Convert platformMetadata to JSON string if present
    final Map<String, dynamic> itemMap = item.toMap();
    if (item.platformMetadata != null) {
      itemMap['platformMetadata'] = jsonEncode(item.platformMetadata);
    }

    return await db.update(
      'content_items',
      itemMap,
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