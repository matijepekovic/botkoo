// lib/core/providers/content_provider.dart
import 'package:flutter/material.dart';
import 'package:botko/core/models/content_item.dart';
import 'package:botko/core/models/content_type.dart';
import 'package:botko/core/models/content_metadata.dart';
import 'package:botko/data/local/content_repository.dart';

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

  // Initialize by loading all content
  Future<void> init() async {
    _setLoading(true);
    try {
      _contentItems = await _repository.getAllContent();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Create a new content item with various options
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

    try {
      final item = ContentItem(
        title: title,
        content: content,
        mediaUrls: mediaUrls,
        createdAt: DateTime.now(),
        status: 'draft',
        contentType: contentType ?? ContentType.textOnly,
        metadata: metadata ?? ContentMetadata(),
        platformMetadata: platformMetadata,
      );

      final id = await _repository.createContent(item);
      final createdItem = item.copyWith(id: id);

      _contentItems.add(createdItem);
      notifyListeners();
    } catch (e) {
      _setError('Failed to create content: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Update an existing content item
  Future<void> updateContent(ContentItem item) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedItem = item.copyWith(
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