// lib/core/services/file_management_service.dart
import 'dart:io';
import 'dart:async';
import 'package:botko/core/utils/logger.dart';
import 'package:botko/core/utils/media_utils.dart';
import 'package:botko/data/local/database_helper.dart';
import 'package:path_provider/path_provider.dart';

class FileManagementService {
  static const String _tag = 'FileManagementService';
  static final FileManagementService _instance = FileManagementService._internal();

  factory FileManagementService() => _instance;

  FileManagementService._internal();

  Timer? _cleanupTimer;
  bool _isRunning = false;

  // Start the service
  void startService({Duration checkInterval = const Duration(hours: 24)}) {
    if (_isRunning) return;

    _isRunning = true;
    Logger.i(_tag, 'File management service started with interval: $checkInterval');

    // Run cleanup once at startup
    _runCleanup();

    // Set up periodic cleanup
    _cleanupTimer = Timer.periodic(checkInterval, (_) {
      _runCleanup();
    });
  }

  // Stop the service
  void stopService() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _isRunning = false;
    Logger.i(_tag, 'File management service stopped');
  }

  // Run media file cleanup
  Future<void> _runCleanup() async {
    Logger.i(_tag, 'Running media file cleanup');

    try {
      // Get all media paths used in content items
      final usedMediaPaths = await _getAllUsedMediaPaths();
      Logger.i(_tag, 'Found ${usedMediaPaths.length} media files in use');

      // Get media directory
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${appDir.path}/botko_media');

      if (await mediaDir.exists()) {
        // Clean up unused files
        await MediaUtils.cleanupUnusedMediaFiles(usedMediaPaths, mediaDir);
      }

      Logger.i(_tag, 'Media cleanup completed');
    } catch (e) {
      Logger.e(_tag, 'Error during media cleanup: $e');
    }
  }

  // Get all media paths referenced in content items
  Future<List<String>> _getAllUsedMediaPaths() async {
    final List<String> paths = [];
    final DatabaseHelper dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // Query all content items
    final List<Map<String, dynamic>> items = await db.query('content_items');

    for (final item in items) {
      final mediaUrls = item['mediaUrls'] as String?;
      if (mediaUrls != null && mediaUrls.isNotEmpty) {
        // Split comma-separated paths and add to list
        paths.addAll(mediaUrls.split(',').where((path) => path.isNotEmpty));
      }
    }

    return paths;
  }

  // Clean up specific files that are no longer needed
  Future<void> cleanupFiles(List<String> filePaths) async {
    for (final path in filePaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          Logger.i(_tag, 'Deleted file: $path');
        }
      } catch (e) {
        Logger.e(_tag, 'Error deleting file $path: $e');
      }
    }
  }
}