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
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPlatformIcon(
              platform: 'twitter',
              isEnabled: contentType != 'reel' && availablePlatforms['twitter'] == true,
              icon: const FaIcon(FontAwesomeIcons.xTwitter),
              activeColor: const Color(0xFF000000), // X is typically black
            ),
            _buildPlatformIcon(
              platform: 'facebook',
              isEnabled: availablePlatforms['facebook'] == true,
              icon: const FaIcon(FontAwesomeIcons.facebook),
              activeColor: const Color(0xFF1877F2),
            ),
            _buildPlatformIcon(
              platform: 'instagram',
              isEnabled: contentType != 'text_only' && availablePlatforms['instagram'] == true,
              icon: const FaIcon(FontAwesomeIcons.instagram),
              activeColor: const Color(0xFFE1306C),
            ),
            _buildPlatformIcon(
              platform: 'linkedin',
              isEnabled: contentType != 'reel' && availablePlatforms['linkedin'] == true,
              icon: const FaIcon(FontAwesomeIcons.linkedin),
              activeColor: const Color(0xFF0077B5),
            ),
          ],
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

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: isEnabled
            ? () => onToggle(platform)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withAlpha(25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? activeColor : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: IconTheme(
            data: IconThemeData(
              size: 28,
              color: isActive ? activeColor : Colors.grey,
            ),
            child: icon,
          ),
        ),
      ),
    );
  }
}