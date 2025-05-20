import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum ContentType {
  textOnly,
  textWithImage,
  image,
  carousel, // Multiple images
  story,
  reel,
  shortVideo, // TikTok, YouTube Shorts
  longVideo, // YouTube, Facebook Watch
}

// Helper extension to handle platform compatibility
extension ContentTypeExtension on ContentType {
  bool isCompatibleWith(String platform) {
    switch (this) {
      case ContentType.textOnly:
        return platform == 'twitter' ||
            platform == 'facebook' ||
            platform == 'linkedin' ||
            platform == 'threads';
      case ContentType.textWithImage:
        return platform == 'twitter' ||
            platform == 'facebook' ||
            platform == 'linkedin' ||
            platform == 'instagram' ||
            platform == 'threads';
      case ContentType.image:
        return platform == 'twitter' ||
            platform == 'facebook' ||
            platform == 'linkedin' ||
            platform == 'instagram' ||
            platform == 'threads';
      case ContentType.carousel:
        return platform == 'facebook' ||
            platform == 'instagram' ||
            platform == 'linkedin';
      case ContentType.story:
        return platform == 'instagram' ||
            platform == 'facebook';
      case ContentType.reel:
        return platform == 'instagram' ||
            platform == 'facebook' ||
            platform == 'tiktok';
      case ContentType.shortVideo:
        return platform == 'tiktok' ||
            platform == 'instagram' ||
            platform == 'youtube' ||
            platform == 'facebook';
      case ContentType.longVideo:
        return platform == 'youtube' ||
            platform == 'facebook';
    }
  }

  String get displayName {
    switch (this) {
      case ContentType.textOnly:
        return 'Text Only';
      case ContentType.textWithImage:
        return 'Text with Image';
      case ContentType.image:
        return 'Image';
      case ContentType.carousel:
        return 'Carousel';
      case ContentType.story:
        return 'Story';
      case ContentType.reel:
        return 'Reel';
      case ContentType.shortVideo:
        return 'Short Video';
      case ContentType.longVideo:
        return 'Long Video';
    }
  }

  IconData get icon {
    switch (this) {
      case ContentType.textOnly:
        return FontAwesomeIcons.font;
      case ContentType.textWithImage:
        return FontAwesomeIcons.fileImage;
      case ContentType.image:
        return FontAwesomeIcons.image;
      case ContentType.carousel:
        return FontAwesomeIcons.images;
      case ContentType.story:
        return FontAwesomeIcons.circlePlay;
      case ContentType.reel:
        return FontAwesomeIcons.video;
      case ContentType.shortVideo:
        return FontAwesomeIcons.film;
      case ContentType.longVideo:
        return FontAwesomeIcons.videoCamera;
    }
  }
}

// Content visibility options
enum ContentVisibility {
  public,
  followers,
  private,
  draft
}

extension ContentVisibilityExtension on ContentVisibility {
  String get displayName {
    switch (this) {
      case ContentVisibility.public:
        return 'Public';
      case ContentVisibility.followers:
        return 'Followers Only';
      case ContentVisibility.private:
        return 'Private';
      case ContentVisibility.draft:
        return 'Draft';
    }
  }
}