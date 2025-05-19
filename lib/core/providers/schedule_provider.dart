import 'package:flutter/material.dart';
import 'package:botko/core/models/social_account.dart';
import 'package:botko/core/models/content_item.dart';
import 'package:botko/core/models/scheduled_post.dart';
import 'package:botko/data/local/database_helper.dart';

class ScheduleProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<ScheduledPost> _scheduledPosts = [];
  final Map<int, ContentItem> _contentItems = {};
  final Map<int, SocialAccount> _accounts = {};
  bool _isLoading = false;
  String? _error;

  List<ScheduledPost> get scheduledPosts => _scheduledPosts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get content item for a scheduled post
  ContentItem? getContentForPost(int contentItemId) => _contentItems[contentItemId];

  // Get account for a scheduled post
  SocialAccount? getAccountForPost(int accountId) => _accounts[accountId];

  // Initialize by loading all scheduled posts
  Future<void> init() async {
    _setLoading(true);
    try {
      await _loadScheduledPosts();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load all scheduled posts and related content and accounts
  Future<void> _loadScheduledPosts() async {
    final db = await _databaseHelper.database;

    // Load scheduled posts
    final postsData = await db.query('scheduled_posts');
    _scheduledPosts = postsData.map((e) => ScheduledPost.fromMap(e)).toList();

    // Load content items for these posts
    final contentIds = _scheduledPosts.map((post) => post.contentItemId).toSet();
    for (final id in contentIds) {
      final contentData = await db.query(
        'content_items',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (contentData.isNotEmpty) {
        _contentItems[id] = ContentItem.fromMap(contentData.first);
      }
    }

    // Load social accounts for these posts
    final accountIds = _scheduledPosts.map((post) => post.socialAccountId).toSet();
    for (final id in accountIds) {
      final accountData = await db.query(
        'social_accounts',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (accountData.isNotEmpty) {
        _accounts[id] = SocialAccount.fromMap(accountData.first);
      }
    }

    notifyListeners();
  }

  // Schedule a post
  Future<void> schedulePost({
    required int contentItemId,
    required int socialAccountId,
    required DateTime scheduledTime,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final post = ScheduledPost(
        contentItemId: contentItemId,
        socialAccountId: socialAccountId,
        scheduledTime: scheduledTime,
      );

      final db = await _databaseHelper.database;
      final id = await db.insert('scheduled_posts', post.toMap());

      final createdPost = ScheduledPost(
        id: id,
        contentItemId: post.contentItemId,
        socialAccountId: post.socialAccountId,
        scheduledTime: post.scheduledTime,
        status: post.status,
      );

      _scheduledPosts.add(createdPost);

      // Also load the content item and account if not already loaded
      if (!_contentItems.containsKey(contentItemId)) {
        final contentData = await db.query(
          'content_items',
          where: 'id = ?',
          whereArgs: [contentItemId],
        );
        if (contentData.isNotEmpty) {
          _contentItems[contentItemId] = ContentItem.fromMap(contentData.first);
        }
      }

      if (!_accounts.containsKey(socialAccountId)) {
        final accountData = await db.query(
          'social_accounts',
          where: 'id = ?',
          whereArgs: [socialAccountId],
        );
        if (accountData.isNotEmpty) {
          _accounts[socialAccountId] = SocialAccount.fromMap(accountData.first);
        }
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to schedule post: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update a scheduled post
  Future<void> updateScheduledPost(ScheduledPost post) async {
    _setLoading(true);
    _clearError();

    try {
      final db = await _databaseHelper.database;
      await db.update(
        'scheduled_posts',
        post.toMap(),
        where: 'id = ?',
        whereArgs: [post.id],
      );

      final index = _scheduledPosts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _scheduledPosts[index] = post;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update scheduled post: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Delete a scheduled post
  Future<void> deleteScheduledPost(int id) async {
    _setLoading(true);
    _clearError();

    try {
      final db = await _databaseHelper.database;
      await db.delete(
        'scheduled_posts',
        where: 'id = ?',
        whereArgs: [id],
      );

      _scheduledPosts.removeWhere((post) => post.id == id);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete scheduled post: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Get posts scheduled for a specific day
  List<ScheduledPost> getPostsForDay(DateTime day) {
    return _scheduledPosts.where((post) {
      final postDate = post.scheduledTime;
      return postDate.year == day.year &&
          postDate.month == day.month &&
          postDate.day == day.day;
    }).toList();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}