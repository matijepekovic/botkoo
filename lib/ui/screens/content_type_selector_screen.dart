// lib/ui/screens/content_type_selector_screen.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:botko/core/models/content_type.dart';
import 'package:botko/ui/screens/content_editor_screen.dart';

class ContentTypeSelectorScreen extends StatelessWidget {
  const ContentTypeSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Content Type'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What kind of content would you like to create?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Grid of content type options
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: ContentType.values.map((type) =>
                  _buildContentTypeCard(context, type)
              ).toList(),
            ),

            const SizedBox(height: 24),

            // Information section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.circleInfo, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Platform Availability',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Different content types are supported on different platforms. '
                        'When you select a content type, only compatible platforms will be '
                        'available for publishing.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTypeCard(BuildContext context, ContentType type) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to the content editor with the selected content type
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContentEditorScreen(
                contentType: type,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                type.icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                type.displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildPlatformIndicators(type),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformIndicators(ContentType type) {
    // Show small icons of supported platforms
    final List<String> supportedPlatforms = [
      'twitter', 'facebook', 'instagram', 'linkedin', 'tiktok', 'youtube', 'threads'
    ].where((platform) => type.isCompatibleWith(platform)).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: supportedPlatforms.map((platform) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _getPlatformIcon(platform, size: 12),
        );
      }).toList(),
    );
  }

  Widget _getPlatformIcon(String platform, {double size = 16}) {
    switch (platform) {
      case 'twitter':
        return FaIcon(FontAwesomeIcons.xTwitter, size: size, color: Colors.black);
      case 'facebook':
        return FaIcon(FontAwesomeIcons.facebook, size: size, color: const Color(0xFF1877F2));
      case 'instagram':
        return FaIcon(FontAwesomeIcons.instagram, size: size, color: const Color(0xFFE1306C));
      case 'linkedin':
        return FaIcon(FontAwesomeIcons.linkedin, size: size, color: const Color(0xFF0077B5));
      case 'tiktok':
        return FaIcon(FontAwesomeIcons.tiktok, size: size, color: Colors.black);
      case 'threads':
        return FaIcon(FontAwesomeIcons.at, size: size, color: Colors.black);
      case 'youtube':
        return FaIcon(FontAwesomeIcons.youtube, size: size, color: const Color(0xFFFF0000));
      default:
        return FaIcon(FontAwesomeIcons.globe, size: size, color: Colors.grey);
    }
  }
}