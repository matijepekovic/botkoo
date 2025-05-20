// lib/ui/widgets/platform_selector.dart - Updated with smaller, single-row icons
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PlatformSelector extends StatelessWidget {
  final List<String> selectedPlatforms;
  final Function(String) onToggle;
  final String contentType; // 'text', 'image', 'video', 'reel', etc.
  final Map<String, bool> availablePlatforms; // Map of platform -> has accounts

  const PlatformSelector({
    super.key,
    required this.selectedPlatforms,
    required this.onToggle,
    required this.contentType,
    required this.availablePlatforms,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Share to:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        // Use Row instead of Wrap to ensure single line
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPlatformIcon(
                platform: 'twitter',
                isEnabled: contentType != 'reel' && availablePlatforms['twitter'] == true,
                icon: const FaIcon(FontAwesomeIcons.xTwitter),
                activeColor: const Color(0xFF000000), // X is typically black
              ),
              const SizedBox(width: 8),
              _buildPlatformIcon(
                platform: 'facebook',
                isEnabled: availablePlatforms['facebook'] == true,
                icon: const FaIcon(FontAwesomeIcons.facebook),
                activeColor: const Color(0xFF1877F2),
              ),
              const SizedBox(width: 8),
              _buildPlatformIcon(
                platform: 'instagram',
                isEnabled: contentType != 'text_only' && availablePlatforms['instagram'] == true,
                icon: const FaIcon(FontAwesomeIcons.instagram),
                activeColor: const Color(0xFFE1306C),
              ),
              const SizedBox(width: 8),
              _buildPlatformIcon(
                platform: 'linkedin',
                isEnabled: contentType != 'reel' && availablePlatforms['linkedin'] == true,
                icon: const FaIcon(FontAwesomeIcons.linkedin),
                activeColor: const Color(0xFF0077B5),
              ),
              const SizedBox(width: 8),
              _buildPlatformIcon(
                platform: 'tiktok',
                isEnabled: (contentType == 'video' || contentType == 'reel') && availablePlatforms['tiktok'] == true,
                icon: const FaIcon(FontAwesomeIcons.tiktok),
                activeColor: const Color(0xFF000000),
              ),
              const SizedBox(width: 8),
              _buildPlatformIcon(
                platform: 'threads',
                isEnabled: availablePlatforms['threads'] == true,
                icon: const FaIcon(FontAwesomeIcons.at), // Threads doesn't have a specific icon yet
                activeColor: const Color(0xFF000000),
              ),
              const SizedBox(width: 8),
              _buildPlatformIcon(
                platform: 'youtube',
                isEnabled: (contentType == 'video' || contentType == 'long_video') && availablePlatforms['youtube'] == true,
                icon: const FaIcon(FontAwesomeIcons.youtube),
                activeColor: const Color(0xFFFF0000),
              ),
            ],
          ),
        ),
        // Add an explanation when platforms are disabled
        if (availablePlatforms.values.any((hasAccount) => !hasAccount))
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Grayed out platforms require account connection',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlatformIcon({
    required String platform,
    required bool isEnabled,
    required Widget icon,
    required Color activeColor,
  }) {
    final bool isSelected = selectedPlatforms.contains(platform);
    final bool isActive = isEnabled && isSelected;

    // Make the icons darker when enabled, for better visibility
    final Color iconColor = isActive
        ? activeColor
        : isEnabled
        ? Colors.grey.shade600  // Darker gray for enabled but not selected
        : Colors.grey.shade300;  // Light gray for disabled

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,  // Less transparent when disabled
      child: InkWell(
        onTap: isEnabled
            ? () => onToggle(platform)
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),  // Smaller padding
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withAlpha(25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? activeColor : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: IconTheme(
            data: IconThemeData(
              size: 20,  // Smaller icon size
              color: iconColor,
            ),
            child: icon,
          ),
        ),
      ),
    );
  }
}