// lib/core/models/content_item.dart (Updated)
import 'dart:convert';
import 'package:botko/core/models/content_type.dart';
import 'package:botko/core/models/content_metadata.dart';

class ContentItem {
  final int? id;
  final String title;
  final String content;
  final List<String> mediaUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String status; // 'draft', 'scheduled', 'published'
  final Map<String, dynamic>? platformMetadata; // Keep for backward compatibility

  // New fields
  final ContentType contentType;
  final ContentMetadata metadata;

  ContentItem({
    this.id,
    required this.title,
    required this.content,
    this.mediaUrls = const [],
    required this.createdAt,
    this.updatedAt,
    this.status = 'draft',
    this.platformMetadata,
    this.contentType = ContentType.textOnly,
    ContentMetadata? metadata,
  }) : metadata = metadata ?? ContentMetadata();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'mediaUrls': mediaUrls.join(','),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'status': status,
      'platformMetadata': platformMetadata != null ? jsonEncode(platformMetadata) : null,
      'contentType': contentType.toString(),
      'metadata': jsonEncode(metadata.toMap()),
    };
  }

  factory ContentItem.fromMap(Map<String, dynamic> map) {
    ContentType? parsedContentType;
    try {
      final contentTypeString = map['contentType'] as String?;
      if (contentTypeString != null) {
        parsedContentType = ContentType.values.firstWhere(
              (type) => type.toString() == contentTypeString,
          orElse: () => ContentType.textOnly,
        );
      }
    } catch (_) {
      parsedContentType = ContentType.textOnly;
    }

    ContentMetadata? parsedMetadata;
    try {
      final metadataString = map['metadata'] as String?;
      if (metadataString != null) {
        final metadataMap = jsonDecode(metadataString) as Map<String, dynamic>;
        parsedMetadata = ContentMetadata.fromMap(metadataMap);
      }
    } catch (_) {
      parsedMetadata = null;
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
      platformMetadata: map['platformMetadata'] != null
          ? jsonDecode(map['platformMetadata'])
          : null,
      contentType: parsedContentType ?? ContentType.textOnly,
      metadata: parsedMetadata,
    );
  }

  // Helper method to detect content type from mediaUrls
  static ContentType detectContentType(List<String> mediaUrls, String content) {
    if (mediaUrls.isEmpty) {
      return ContentType.textOnly;
    } else if (mediaUrls.length == 1) {
      final url = mediaUrls.first.toLowerCase();
      if (url.endsWith('.mp4') || url.endsWith('.mov') || url.endsWith('.avi')) {
        // This is a simplistic check - in a real app you would examine the duration
        if (_isShortVideo(url)) {
          return ContentType.shortVideo;
        } else {
          return ContentType.longVideo;
        }
      } else if (url.endsWith('.jpg') || url.endsWith('.jpeg') ||
          url.endsWith('.png') || url.endsWith('.gif')) {
        return content.isEmpty ? ContentType.image : ContentType.textWithImage;
      }
    } else if (mediaUrls.length > 1) {
      // Multiple media usually means carousel
      return ContentType.carousel;
    }

    return ContentType.textOnly;
  }

  // Simplified check - in a real app you would examine the actual video
  static bool _isShortVideo(String url) {
    // Assumption: all videos are short for now
    return true;
  }

  // Add copyWith method for easy object updates
  ContentItem copyWith({
    int? id,
    String? title,
    String? content,
    List<String>? mediaUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    Map<String, dynamic>? platformMetadata,
    ContentType? contentType,
    ContentMetadata? metadata,
  }) {
    return ContentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      platformMetadata: platformMetadata ?? this.platformMetadata,
      contentType: contentType ?? this.contentType,
      metadata: metadata ?? this.metadata,
    );
  }

  // Equality operators
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContentItem && other.id == id;
  }

  @override
  int get hashCode => id?.hashCode ?? 0;
}