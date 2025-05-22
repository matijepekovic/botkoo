// lib/core/utils/media_utils.dart
import 'dart:io';
import 'dart:math' as math; // Add this import
import 'package:path/path.dart' as path;
import 'package:video_player/video_player.dart';
import 'package:botko/core/utils/logger.dart';

class MediaUtils {
  static const String _tag = 'MediaUtils';

  // Get file extension
  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  // Get file name without path
  static String getFileName(String filePath) {
    return path.basename(filePath);
  }

  // Get file size in readable format
  static String getFileSize(String filePath, {int decimals = 1}) {
    try {
      final file = File(filePath);
      final bytes = file.lengthSync();
      if (bytes <= 0) return "0 B";

      const suffixes = ["B", "KB", "MB", "GB", "TB"];
      final i = (log(bytes) / log(1024)).floor();
      return '${(bytes / math.pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
    } catch (e) {
      Logger.e(_tag, 'Error getting file size: $e');
      return 'Unknown size';
    }
  }

  // Check if file is an image
  static bool isImageFile(String filePath) {
    final ext = getFileExtension(filePath);
    return ext == '.jpg' || ext == '.jpeg' || ext == '.png' || ext == '.gif';
  }

  // Check if file is a video
  static bool isVideoFile(String filePath) {
    final ext = getFileExtension(filePath);
    return ext == '.mp4' || ext == '.mov' || ext == '.avi';
  }

  // Get video duration (async)
  static Future<Duration?> getVideoDuration(String filePath) async {
    try {
      final controller = VideoPlayerController.file(File(filePath));
      await controller.initialize();
      final duration = controller.value.duration;
      await controller.dispose();
      return duration;
    } catch (e) {
      Logger.e(_tag, 'Error getting video duration: $e');
      return null;
    }
  }

  // Get formatted duration string
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  // Clean up unused media files
  static Future<void> cleanupUnusedMediaFiles(
      List<String> usedMediaPaths,
      Directory mediaDirectory
      ) async {
    try {
      final entities = await mediaDirectory.list().toList();
      for (final entity in entities) {
        if (entity is File && !usedMediaPaths.contains(entity.path)) {
          await entity.delete();
          Logger.i(_tag, 'Deleted unused media file: ${entity.path}');
        }
      }
    } catch (e) {
      Logger.e(_tag, 'Error cleaning up unused media files: $e');
    }
  }

  // Helper for log function
  static double log(num x) => log10(x) / log10(1024);

  // log base 10
  static double log10(num x) => log(x) / ln10;

  // Constants
  static const double ln10 = 2.302585092994046;

  // Helper to calculate suitable aspect ratio
  static double calculateAspectRatio(VideoPlayerController controller) {
    final aspectRatio = controller.value.aspectRatio;

    // If aspect ratio is too extreme, use a more reasonable default
    if (aspectRatio < 0.2 || aspectRatio > 5.0) {
      return 16/9; // Default to widescreen
    }

    return aspectRatio;
  }
}