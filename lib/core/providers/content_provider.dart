import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:botko/core/models/content_item.dart';
import 'package:botko/core/models/content_type.dart';
import 'package:botko/core/models/content_metadata.dart';
import 'package:botko/data/local/content_repository.dart';
import 'package:botko/core/services/media_service.dart';
import 'package:botko/core/utils/logger.dart';

class ContentProvider extends ChangeNotifier {
  final ContentRepository _repository = ContentRepository();

  List<ContentItem> _contentItems = [];
  bool _isLoading = false;
  String? _error;

  List<ContentItem> get contentItems => _contentItems;
  List<ContentItem> get drafts => _contentItems.where((item) => item.status == 'draft').toList();
  List<ContentItem> get scheduled => _contentItems.where((item) => item.status == 'scheduled').toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Enhanced _validateAndFixMediaPaths method with detailed logging
  Future<void> _validateAndFixMediaPaths() async {
    final MediaService mediaService = MediaService();
    bool hasChanges = false;

    Logger.i('ContentProvider', 'Starting media validation for ${_contentItems.length} content items');

    for (int i = 0; i < _contentItems.length; i++) {
      final item = _contentItems[i];
      final List<String> validatedPaths = [];
      bool itemNeedsUpdate = false;

      Logger.i('ContentProvider', 'Validating item "${item.title}" with ${item.mediaUrls.length} media files');

      for (final path in item.mediaUrls) {
        try {
          Logger.i('ContentProvider', 'Checking path: $path');
          final validPath = await mediaService.getPersistedPath(path);
          if (validPath.isNotEmpty) {
            validatedPaths.add(validPath);
            Logger.i('ContentProvider', 'Path valid: $validPath');
          } else {
            itemNeedsUpdate = true;
            Logger.w('ContentProvider', 'Media file not found, will remove: $path');
          }
        } catch (e) {
          Logger.e('ContentProvider', 'Error validating media path: $path', e);
          itemNeedsUpdate = true;
        }
      }

      if (itemNeedsUpdate) {
        Logger.i('ContentProvider', 'Updating item "${item.title}": ${item.mediaUrls.length} -> ${validatedPaths.length} media files');

        // Update the item with valid paths, but preserve original content type
        final updatedItem = item.copyWith(
          mediaUrls: validatedPaths,
          updatedAt: DateTime.now(),
          // Don't change contentType here - preserve original intent
        );

        try {
          _contentItems[i] = updatedItem;
          await _repository.updateContent(updatedItem);
          hasChanges = true;
          Logger.i('ContentProvider', 'Successfully updated item "${item.title}" in database');
        } catch (e) {
          Logger.e('ContentProvider', 'Failed to update item "${item.title}" in database', e);
        }
      } else {
        Logger.i('ContentProvider', 'Item "${item.title}" - no changes needed');
      }
    }

    if (hasChanges) {
      notifyListeners();
      Logger.i('ContentProvider', 'Media paths validation completed with changes - UI updated');
    } else {
      Logger.i('ContentProvider', 'Media paths validation completed - no changes needed');
    }
  }

  // Initialize by loading all content
  Future<void> init() async {
    _setLoading(true);
    try {
      _contentItems = await _repository.getAllContent();

      // Validate and fix media paths after loading
      await _validateAndFixMediaPaths();

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Create a new content item with various options
  // Update this method in ContentProvider
  // Enhanced createContent method with detailed content type logging
  Future<void> createContent(
      String title,
      String content,
      List<String> mediaUrls,
      {ContentType? contentType,
        ContentMetadata? metadata,
        Map<String, dynamic>? platformMetadata}
      ) async {
    _setLoading(true);
    _clearError();

    Logger.i('ContentProvider', '=== CREATING CONTENT ===');
    Logger.i('ContentProvider', 'Title: $title');
    Logger.i('ContentProvider', 'Content: ${content.substring(0, math.min(50, content.length))}...');
    Logger.i('ContentProvider', 'Media URLs: ${mediaUrls.length} files');
    Logger.i('ContentProvider', 'Requested Content Type: ${contentType?.displayName ?? 'null (will default to textOnly)'}');

    try {
      // PERSIST MEDIA FILES FIRST
      final MediaService mediaService = MediaService();
      final List<String> persistedMediaUrls = [];

      for (final mediaUrl in mediaUrls) {
        try {
          final persistedPath = await mediaService.getPersistedPath(mediaUrl);
          if (persistedPath.isNotEmpty) {
            persistedMediaUrls.add(persistedPath);
            Logger.i('ContentProvider', 'Media persisted: $persistedPath');
          } else {
            Logger.w('ContentProvider', 'Failed to persist media: $mediaUrl');
          }
        } catch (e) {
          Logger.e('ContentProvider', 'Failed to persist media: $mediaUrl', e);
        }
      }

      Logger.i('ContentProvider', 'Persisted ${persistedMediaUrls.length} of ${mediaUrls.length} media files');

      // Determine final content type
      final ContentType finalContentType = contentType ?? ContentType.textOnly;
      Logger.i('ContentProvider', 'Final Content Type: ${finalContentType.displayName}');

      final item = ContentItem(
        title: title,
        content: content,
        mediaUrls: persistedMediaUrls,
        createdAt: DateTime.now(),
        status: 'draft',
        contentType: finalContentType, // Use the determined type
        metadata: metadata ?? ContentMetadata(),
        platformMetadata: platformMetadata,
      );

      Logger.i('ContentProvider', 'Created ContentItem with type: ${item.contentType.displayName}');
      Logger.i('ContentProvider', 'ContentItem mediaUrls: ${item.mediaUrls.length}');

      final id = await _repository.createContent(item);
      Logger.i('ContentProvider', 'Repository returned ID: $id');

      final createdItem = item.copyWith(id: id);
      Logger.i('ContentProvider', 'Final item type after copyWith: ${createdItem.contentType.displayName}');

      _contentItems.add(createdItem);
      notifyListeners();

      Logger.i('ContentProvider', 'Content created successfully with ${persistedMediaUrls.length} media files');
      Logger.i('ContentProvider', '=== CONTENT CREATION COMPLETE ===');
    } catch (e) {
      Logger.e('ContentProvider', 'Failed to create content', e);
      _setError('Failed to create content: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update this method in ContentProvider
  Future<void> updateContent(ContentItem item) async {
    _setLoading(true);
    _clearError();

    try {
      // Persist any new media files
      final MediaService mediaService = MediaService();
      final List<String> persistedMediaUrls = [];

      for (final mediaUrl in item.mediaUrls) {
        try {
          final persistedPath = await mediaService.getPersistedPath(mediaUrl);
          if (persistedPath.isNotEmpty) {
            persistedMediaUrls.add(persistedPath);
          }
        } catch (e) {
          Logger.e('ContentProvider', 'Failed to persist media during update: $mediaUrl', e);
        }
      }

      final updatedItem = item.copyWith(
        mediaUrls: persistedMediaUrls, // Use persisted paths
        updatedAt: DateTime.now(),
      );

      await _repository.updateContent(updatedItem);

      final index = _contentItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _contentItems[index] = updatedItem;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update content: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update content status
  Future<void> updateContentStatus(int id, String status) async {
    _setLoading(true);
    _clearError();

    try {
      final index = _contentItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        final item = _contentItems[index];
        final updatedItem = item.copyWith(
          updatedAt: DateTime.now(),
          status: status,
        );

        await _repository.updateContent(updatedItem);
        _contentItems[index] = updatedItem;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update content status: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Delete a content item
  Future<void> deleteContent(int id) async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.deleteContent(id);
      _contentItems.removeWhere((item) => item.id == id);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete content: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Get content by type
  List<ContentItem> getContentByType(ContentType type) {
    return _contentItems.where((item) => item.contentType == type).toList();
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