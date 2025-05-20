// lib/ui/utils/content_type_helper.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:botko/core/models/content_type.dart';

class ContentTypeHelper {
  static Widget getIcon(ContentType type, {double size = 24, Color? color}) {
    final IconData iconData = type.icon;
    return FaIcon(iconData, size: size, color: color);
  }

  static Color getColor(ContentType type) {
    switch (type) {
      case ContentType.textOnly:
        return Colors.blue;
      case ContentType.textWithImage:
        return Colors.green;
      case ContentType.image:
        return Colors.purple;
      case ContentType.carousel:
        return Colors.amber;
      case ContentType.story:
        return Colors.pinkAccent;
      case ContentType.reel:
        return Colors.redAccent;
      case ContentType.shortVideo:
        return Colors.orange;
      case ContentType.longVideo:
        return Colors.deepPurple;
    }
  }

  static String getDescription(ContentType type) {
    switch (type) {
      case ContentType.textOnly:
        return 'Text-only posts without media';
      case ContentType.textWithImage:
        return 'Text posts with accompanying images';
      case ContentType.image:
        return 'Image-focused posts with optional captions';
      case ContentType.carousel:
        return 'Multiple images in a single post';
      case ContentType.story:
        return 'Temporary content that disappears after 24 hours';
      case ContentType.reel:
        return 'Short vertical videos with music and effects';
      case ContentType.shortVideo:
        return 'Short video content (under 3 minutes)';
      case ContentType.longVideo:
        return 'Extended video content with detailed descriptions';
    }
  }
}