// lib/ui/widgets/platform_post_preview.dart
import 'package:flutter/material.dart';
import 'package:botko/core/models/content_item.dart';
import 'package:botko/core/models/social_account.dart';

class PlatformPostPreview extends StatelessWidget {
  final ContentItem contentItem;
  final SocialAccount account;
  final String platform;

  const PlatformPostPreview({
    super.key,
    required this.contentItem,
    required this.account,
    required this.platform,
  });

  @override
  Widget build(BuildContext context) {
    switch (platform) {
      case 'tiktok':
        return _TikTokPreview(contentItem: contentItem, account: account);
      case 'threads':
        return _ThreadsPreview(contentItem: contentItem, account: account);
      case 'youtube':
        return _YouTubePreview(contentItem: contentItem, account: account);
      case 'twitter':
        return _TwitterPreview(contentItem: contentItem, account: account);
      case 'instagram':
        return _InstagramPreview(contentItem: contentItem, account: account);
      case 'facebook':
        return _FacebookPreview(contentItem: contentItem, account: account);
      case 'linkedin':
        return _LinkedInPreview(contentItem: contentItem, account: account);
      default:
        return _GenericPreview(contentItem: contentItem, account: account);
    }
  }
}

class _TikTokPreview extends StatelessWidget {
  final ContentItem contentItem;
  final SocialAccount account;

  const _TikTokPreview({
    required this.contentItem,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    final platformData = contentItem.platformMetadata?['tiktok'] ?? {};
    final hashtags = platformData['hashtags'] ?? '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with "TikTok Preview"
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.music_note, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'TikTok Preview',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Video placeholder
          AspectRatio(
            aspectRatio: 9 / 16, // Vertical video
            child: Container(
              color: Colors.grey.shade900,
              child: contentItem.mediaUrls.isNotEmpty
                  ? Image.network(
                contentItem.mediaUrls.first,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.videocam,
                          color: Colors.white54,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Video Preview',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                },
              )
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.videocam,
                      color: Colors.white54,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Video Preview',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Caption area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '@${account.username}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  contentItem.content,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hashtags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      hashtags,
                      style: const TextStyle(
                        color: Colors.cyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadsPreview extends StatelessWidget {
  final ContentItem contentItem;
  final SocialAccount account;

  const _ThreadsPreview({
    required this.contentItem,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with "Threads Preview"
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline),
                const SizedBox(width: 8),
                const Text(
                  'Threads Preview',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Post content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile info
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black12,
                      child: Icon(Icons.person, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '@${account.username}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Post text
                Text(contentItem.content),

                // Post image (if any)
                if (contentItem.mediaUrls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        contentItem.mediaUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '1m ago',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _YouTubePreview extends StatelessWidget {
  final ContentItem contentItem;
  final SocialAccount account;

  const _YouTubePreview({
    required this.contentItem,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    final platformData = contentItem.platformMetadata?['youtube'] ?? {};
    final description = platformData['description'] ?? '';
    final tags = platformData['tags'] ?? '';

    final Map<String, dynamic>? channelData = account.platformSpecificData?['channels'] != null
        ? (account.platformSpecificData!['channels'] as List).firstWhere(
          (channel) => channel['isDefault'] == true,
      orElse: () => (account.platformSpecificData!['channels'] as List).first,
    )
        : null;

    final channelName = channelData?['name'] ?? account.username;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with "YouTube Preview"
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF0000).withAlpha(26),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.play_circle_filled, color: Color(0xFFFF0000)),
                const SizedBox(width: 8),
                const Text(
                  'YouTube Preview',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Thumbnail
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: contentItem.mediaUrls.isNotEmpty
                  ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    contentItem.mediaUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.movie,
                              color: Colors.white54,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Video Thumbnail',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // Play button overlay
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  // Video duration
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(179), // 0.7 opacity = ~179 alpha
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '10:25',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              )
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.movie,
                      color: Colors.white54,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Video Thumbnail',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Video details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  contentItem.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // View count and timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '0 views • Just now',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Channel info
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      channelName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description (truncated)
                if (description.isNotEmpty)
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),

                // Tags (if any)
                if (tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '#$tags',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Basic implementations for existing platforms
class _TwitterPreview extends StatelessWidget {
  final ContentItem contentItem;
  final SocialAccount account;

  const _TwitterPreview({
    required this.contentItem,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    return _GenericPreview(
      contentItem: contentItem,
      account: account,
      platformName: 'X',
      platformIcon: Icons.message,
      platformColor: Colors.black,
    );
  }
}

class _InstagramPreview extends StatelessWidget {
  final ContentItem contentItem;
  final SocialAccount account;

  const _InstagramPreview({
    required this.contentItem,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    return _GenericPreview(
      contentItem: contentItem,
      account: account,
      platformName: 'Instagram',
      platformIcon: Icons.camera_alt,
      platformColor: const Color(0xFFE1306C),
    );
  }
}

class _FacebookPreview extends StatelessWidget {
  final ContentItem contentItem;
  final SocialAccount account;

  const _FacebookPreview({
    required this.contentItem,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    return _GenericPreview(
      contentItem: contentItem,
      account: account,
      platformName: 'Facebook',
      platformIcon: Icons.facebook,
      platformColor: const Color(0xFF1877F2),
    );
  }
}

class _LinkedInPreview extends StatelessWidget {
  final ContentItem contentItem;
  final SocialAccount account;

  const _LinkedInPreview({
    required this.contentItem,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    return _GenericPreview(
      contentItem: contentItem,
      account: account,
      platformName: 'LinkedIn',
      platformIcon: Icons.work,
      platformColor: const Color(0xFF0077B5),
    );
  }
}

// Generic preview for other platforms
class _GenericPreview extends StatelessWidget {
  final ContentItem contentItem;
  final SocialAccount account;
  final String? platformName;
  final IconData? platformIcon;
  final Color? platformColor;

  const _GenericPreview({
    required this.contentItem,
    required this.account,
    this.platformName,
    this.platformIcon,
    this.platformColor,
  });

  @override
  Widget build(BuildContext context) {
    final displayPlatform = platformName ?? account.platform.toUpperCase();
    final icon = platformIcon ?? Icons.public;
    final color = platformColor ?? Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(26), // 0.1 opacity = ~26 alpha
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  '$displayPlatform Preview',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: color.withAlpha(51),
                      child: const Icon(Icons.person, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      account.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Post text
                Text(contentItem.content),

                // Media (if any)
                if (contentItem.mediaUrls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        contentItem.mediaUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}