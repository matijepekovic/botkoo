// lib/core/services/media_service.dart
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:botko/core/models/content_type.dart';
import 'package:botko/core/utils/logger.dart';
import 'package:botko/core/utils/media_utils.dart';
import 'package:path/path.dart' as path;

class MediaService {
  static const String _tag = 'MediaService';
  static final MediaService _instance = MediaService._internal();

  factory MediaService() => _instance;

  MediaService._internal();

  final Uuid _uuid = const Uuid();
  Future<String> getPersistedPath(String originalPath) async {
    // If the path is null or empty, return empty string
    if (originalPath.isEmpty) {
      return '';
    }

    try {
      final mediaDir = await _mediaDirectory;
      final File originalFile = File(originalPath);

      // Check if file exists
      if (!await originalFile.exists()) {
        Logger.e(_tag, 'File does not exist: $originalPath');
        return originalPath; // Return original path, will be handled later
      }

      // If the path already points to our media directory, return it as is
      if (originalPath.startsWith(mediaDir.path)) {
        // Verify the file still exists
        if (await originalFile.exists()) {
          return originalPath;
        } else {
          Logger.e(_tag, 'File in media directory does not exist: $originalPath');
          return ''; // Return empty string to indicate file is missing
        }
      }

      // If it's an external path, copy it to our media directory
      final fileName = '${_uuid.v4()}_${path.basename(originalPath)}';
      final newPath = '${mediaDir.path}/$fileName';
      await originalFile.copy(newPath);
      Logger.i(_tag, 'Copied file from $originalPath to $newPath');
      return newPath;
    } catch (e) {
      Logger.e(_tag, 'Error persisting path: $e');
      return originalPath; // Return original path on error
    }
  }
  // Get the app's media directory
  Future<Directory> get _mediaDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${appDir.path}/botko_media');

    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    return mediaDir;
  }

  // Pick image files
  Future<List<String>> pickImages({bool multiple = false}) async {
    try {
      // Define the types of files we want to pick
      final XTypeGroup imageTypeGroup = XTypeGroup(
        label: 'Images',
        extensions: ['jpg', 'jpeg', 'png', 'gif'],
      );

      List<XFile> files = [];

      if (multiple) {
        files = await openFiles(acceptedTypeGroups: [imageTypeGroup]);
      } else {
        final XFile? file = await openFile(acceptedTypeGroups: [imageTypeGroup]);
        if (file != null) {
          files = [file];
        }
      }

      if (files.isEmpty) {
        return [];
      }

      return _savePickedFiles(files);
    } catch (e) {
      Logger.e(_tag, 'Error picking images: $e');
      return [];
    }
  }

  // Pick video files
  Future<List<String>> pickVideos() async {
    try {
      // Define the types of files we want to pick
      final XTypeGroup videoTypeGroup = XTypeGroup(
        label: 'Videos',
        extensions: ['mp4', 'mov', 'avi'],
      );

      final XFile? file = await openFile(acceptedTypeGroups: [videoTypeGroup]);

      if (file == null) {
        return [];
      }

      return _savePickedFiles([file]);
    } catch (e) {
      Logger.e(_tag, 'Error picking videos: $e');
      return [];
    }
  }

  // Pick media based on content type
  Future<List<String>> pickMediaForContentType(ContentType contentType) async {
    switch (contentType) {
      case ContentType.textOnly:
        return [];
      case ContentType.textWithImage:
      case ContentType.image:
        return pickImages();
      case ContentType.carousel:
        return pickImages(multiple: true);
      case ContentType.story:
      // Stories can be either image or video
        return _pickImageOrVideo();
      case ContentType.reel:
      case ContentType.shortVideo:
      case ContentType.longVideo:
        return pickVideos();
    }
  }

  // Pick either image or video
  Future<List<String>> _pickImageOrVideo() async {
    try {
      // Define the types of files we want to pick
      final XTypeGroup mediaTypeGroup = XTypeGroup(
        label: 'Images & Videos',
        extensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov', 'avi'],
      );

      final XFile? file = await openFile(acceptedTypeGroups: [mediaTypeGroup]);

      if (file == null) {
        return [];
      }

      return _savePickedFiles([file]);
    } catch (e) {
      Logger.e(_tag, 'Error picking media: $e');
      return [];
    }
  }

  // Save picked files to app directory and return their paths
  Future<List<String>> _savePickedFiles(List<XFile> files) async {
    final mediaDir = await _mediaDirectory;
    final List<String> savedPaths = [];

    for (final file in files) {
      try {
        final String fileName = '${_uuid.v4()}_${file.name}';
        final String destinationPath = '${mediaDir.path}/$fileName';

        // Copy the file to our app's media directory
        final sourceBytes = await file.readAsBytes();
        await File(destinationPath).writeAsBytes(sourceBytes);

        // Add the saved path to our list
        savedPaths.add(destinationPath);
        Logger.i(_tag, 'Saved media file: $destinationPath');
      } catch (e) {
        Logger.e(_tag, 'Error saving file ${file.name}: $e');
      }
    }

    return savedPaths;
  }

  // Get media file from path
  File? getMediaFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        return file;
      }
    } catch (e) {
      Logger.e(_tag, 'Error getting media file: $e');
    }
    return null;
  }

  // Delete a media file
  Future<bool> deleteMediaFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      Logger.e(_tag, 'Error deleting media file: $e');
    }
    return false;
  }

  // Check if a file is an image
  bool isImageFile(String path) {
    return MediaUtils.isImageFile(path);
  }

// Check if a file is a video
  bool isVideoFile(String path) {
    return MediaUtils.isVideoFile(path);
  }
}