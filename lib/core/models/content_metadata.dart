// lib/core/models/content_metadata.dart
import 'package:botko/core/models/content_type.dart';

class ContentMetadata {
  final String? description;
  final String? title; // For videos
  final List<String> hashtags;
  final String? thumbnailUrl; // For videos
  final Duration? duration; // For videos
  final List<String> tags; // For YouTube
  final ContentVisibility visibility;
  final Map<String, dynamic>? platformSpecificSettings;

  ContentMetadata({
    this.description,
    this.title,
    this.hashtags = const [],
    this.thumbnailUrl,
    this.duration,
    this.tags = const [],
    this.visibility = ContentVisibility.public,
    this.platformSpecificSettings,
  });

  // Create from map (for database storage)
  factory ContentMetadata.fromMap(Map<String, dynamic> map) {
    return ContentMetadata(
      description: map['description'],
      title: map['title'],
      hashtags: (map['hashtags'] as String?)?.split(',') ?? [],
      thumbnailUrl: map['thumbnailUrl'],
      duration: map['duration'] != null ? Duration(milliseconds: map['duration']) : null,
      tags: (map['tags'] as String?)?.split(',') ?? [],
      visibility: ContentVisibility.values.firstWhere(
            (v) => v.toString() == map['visibility'],
        orElse: () => ContentVisibility.public,
      ),
      platformSpecificSettings: map['platformSpecificSettings'] != null
          ? Map<String, dynamic>.from(map['platformSpecificSettings'])
          : null,
    );
  }

  // Convert to map (for database storage)
  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'title': title,
      'hashtags': hashtags.join(','),
      'thumbnailUrl': thumbnailUrl,
      'duration': duration?.inMilliseconds,
      'tags': tags.join(','),
      'visibility': visibility.toString(),
      'platformSpecificSettings': platformSpecificSettings,
    };
  }

  // Create a copy with some fields updated
  ContentMetadata copyWith({
    String? description,
    String? title,
    List<String>? hashtags,
    String? thumbnailUrl,
    Duration? duration,
    List<String>? tags,
    ContentVisibility? visibility,
    Map<String, dynamic>? platformSpecificSettings,
  }) {
    return ContentMetadata(
      description: description ?? this.description,
      title: title ?? this.title,
      hashtags: hashtags ?? this.hashtags,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      tags: tags ?? this.tags,
      visibility: visibility ?? this.visibility,
      platformSpecificSettings: platformSpecificSettings ?? this.platformSpecificSettings,
    );
  }

  // Platform-specific helpers

  // Get YouTube specific metadata
  Map<String, dynamic> get youtubeMetadata {
    return platformSpecificSettings?['youtube'] ?? {};
  }

  // Get TikTok specific metadata
  Map<String, dynamic> get tiktokMetadata {
    return platformSpecificSettings?['tiktok'] ?? {};
  }

  // Get Instagram specific metadata
  Map<String, dynamic> get instagramMetadata {
    return platformSpecificSettings?['instagram'] ?? {};
  }

  // Update platform-specific settings
  ContentMetadata updatePlatformSettings(String platform, Map<String, dynamic> settings) {
    final Map<String, dynamic> updatedSettings = {...?platformSpecificSettings};
    updatedSettings[platform] = settings;

    return copyWith(platformSpecificSettings: updatedSettings);
  }
}