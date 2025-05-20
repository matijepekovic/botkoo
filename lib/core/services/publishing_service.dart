import 'dart:async';
import 'package:botko/core/models/scheduled_post.dart';
import 'package:botko/core/models/content_item.dart';
import 'package:botko/core/models/social_account.dart';
import 'package:botko/data/local/database_helper.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class PublishingService {
  static final PublishingService _instance = PublishingService._internal();
  factory PublishingService() => _instance;

  PublishingService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  Timer? _publishingTimer;
  bool _isRunning = false;

  // Add stream controller for status updates
  final StreamController<int> _publishingEventsController = StreamController<int>.broadcast();
  Stream<int> get publishingEvents => _publishingEventsController.stream;

  // Add dispose method
  void dispose() {
    stopService();
    _publishingEventsController.close();
  }

  // Start the publishing service
  void startService({Duration checkInterval = const Duration(minutes: 1)}) {
    if (_isRunning) return;

    _isRunning = true;

    // Run immediately to catch any pending posts
    _checkScheduledPosts();

    _publishingTimer = Timer.periodic(checkInterval, (_) {
      debugPrint("Timer checking scheduled posts at ${DateTime.now()}");
      _checkScheduledPosts();
    });

    debugPrint("Publishing service started with interval: $checkInterval");
  }

  // Stop the publishing service
  void stopService() {
    _publishingTimer?.cancel();
    _publishingTimer = null;
    _isRunning = false;
    debugPrint("Publishing service stopped");
  }

  // Check for posts that need to be published
  Future<void> _checkScheduledPosts() async {
    debugPrint("Checking for scheduled posts at ${DateTime.now()}");

    final now = DateTime.now();
    final db = await _databaseHelper.database;

    // Get all pending posts
    final List<Map<String, dynamic>> pendingPosts = await db.query(
      'scheduled_posts',
      where: 'status = ?',
      whereArgs: ['pending'],
    );

    debugPrint("Found ${pendingPosts.length} pending posts");

    // Filter posts that are due in Dart code
    final List<ScheduledPost> postsToPublish = pendingPosts
        .map((map) => ScheduledPost.fromMap(map))
        .where((post) => post.scheduledTime.isBefore(now) ||
        post.scheduledTime.isAtSameMomentAs(now))
        .toList();

    debugPrint("${postsToPublish.length} posts are due for publishing");

    // Process each post
    for (var post in postsToPublish) {
      await _publishPost(post);
    }
  }

  // Publish a single post
  Future<void> _publishPost(ScheduledPost post) async {
    try {
      // Get the content and account for this post
      final contentItem = await _getContentItem(post.contentItemId);
      final account = await _getSocialAccount(post.socialAccountId);

      if (contentItem == null || account == null) {
        await _markPostAsFailed(post.id!, 'Content or account not found');
        return;
      }

      // Simulate API call to publish the post
      final success = await _simulatePublishToSocialMedia(
        account: account,
        content: contentItem,
      );

      if (success) {
        await _markPostAsPublished(post.id!);
      } else {
        await _markPostAsFailed(post.id!, 'Failed to publish to social media');
      }
    } catch (e) {
      await _markPostAsFailed(post.id!, e.toString());
    }
  }

  // Helper methods
  Future<ContentItem?> _getContentItem(int id) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'content_items',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return ContentItem.fromMap(results.first);
  }

  Future<SocialAccount?> _getSocialAccount(int id) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'social_accounts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return SocialAccount.fromMap(results.first);
  }

  Future<void> _markPostAsPublished(int postId) async {
    final db = await _databaseHelper.database;
    await db.update(
      'scheduled_posts',
      {'status': 'published'},
      where: 'id = ?',
      whereArgs: [postId],
    );

    // Notify listeners of status change
    _publishingEventsController.add(postId);
    debugPrint("Post $postId marked as published");
  }

  Future<void> _markPostAsFailed(int postId, String reason) async {
    final db = await _databaseHelper.database;
    await db.update(
      'scheduled_posts',
      {
        'status': 'failed',
        'failureReason': reason,
      },
      where: 'id = ?',
      whereArgs: [postId],
    );

    // Notify listeners of status change
    _publishingEventsController.add(postId);
    debugPrint("Post $postId marked as failed: $reason");
  }

  Future<bool> _simulatePublishToSocialMedia({
    required SocialAccount account,
    required ContentItem content,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Always succeed
    const success = true; // 100% success rate, no failures

    // In real implementation, this would make API calls to publish
    // to the respective social media platform
    debugPrint('Published content "${content.title}" to ${account.platform} as ${account.username}');

    return success;
  }

  // Manual publish method (can be triggered from UI)
  Future<bool> manualPublish(int scheduledPostId) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'scheduled_posts',
      where: 'id = ?',
      whereArgs: [scheduledPostId],
    );

    if (results.isEmpty) return false;

    final post = ScheduledPost.fromMap(results.first);
    await _publishPost(post);

    // Check if publishing succeeded
    final updatedResults = await db.query(
      'scheduled_posts',
      where: 'id = ?',
      whereArgs: [scheduledPostId],
    );

    if (updatedResults.isEmpty) return false;
    final updatedPost = ScheduledPost.fromMap(updatedResults.first);

    return updatedPost.status == 'published';
  }

  // Status check method
  void debugServiceStatus() {
    debugPrint("Publishing service status:");
    debugPrint("- Is running: $_isRunning");
    debugPrint("- Timer active: ${_publishingTimer?.isActive ?? false}");
  }
}