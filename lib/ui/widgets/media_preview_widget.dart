// lib/ui/widgets/media_preview_widget.dart - Windows Compatible Version
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:botko/core/services/media_service.dart';

class MediaPreviewWidget extends StatefulWidget {
  final List<String> mediaPaths;
  final Function(String) onRemove;
  final double height;
  final bool isCarousel;

  const MediaPreviewWidget({
    super.key,
    required this.mediaPaths,
    required this.onRemove,
    this.height = 200,
    this.isCarousel = false,
  });

  @override
  State<MediaPreviewWidget> createState() => _MediaPreviewWidgetState();
}

class _MediaPreviewWidgetState extends State<MediaPreviewWidget> {
  final MediaService _mediaService = MediaService();
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    if (widget.mediaPaths.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: widget.isCarousel
          ? _buildCarouselPreview()
          : _buildSingleMediaPreview(widget.mediaPaths.first),
    );
  }

  Widget _buildCarouselPreview() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              // Main PageView for swiping
              PageView.builder(
                controller: _pageController,
                itemCount: widget.mediaPaths.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildSingleMediaPreview(widget.mediaPaths[index]);
                },
              ),

              // Left navigation arrow
              if (widget.mediaPaths.length > 1)
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(100),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.angleLeft,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          if (_currentIndex > 0) {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),

              // Right navigation arrow
              if (widget.mediaPaths.length > 1)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(100),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.angleRight,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          if (_currentIndex < widget.mediaPaths.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Page indicator dots
        if (widget.mediaPaths.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < widget.mediaPaths.length; i++)
                  GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      width: i == _currentIndex ? 10 : 8,
                      height: i == _currentIndex ? 10 : 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _currentIndex
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSingleMediaPreview(String path) {
    final isVideo = _mediaService.isVideoFile(path);

    return Container(
      constraints: BoxConstraints(
        minHeight: 100,
        maxHeight: widget.height,
      ),
      child: Stack(
        children: [
          // Media content
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isVideo
                  ? _buildVideoThumbnail(path)
                  : Image.file(
                File(path),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading image: $error');
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.image,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Remove button
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(128),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.xmark,
                  color: Colors.white,
                  size: 16,
                ),
                onPressed: () => widget.onRemove(path),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Video thumbnail without video player - Phase 1 compatible
  Widget _buildVideoThumbnail(String path) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51), // 0.2 opacity
                shape: BoxShape.circle,
              ),
              child: const FaIcon(
                FontAwesomeIcons.play,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Video Preview',
              style: TextStyle(
                color: Colors.white.withAlpha(179), // 0.7 opacity
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              path.split('/').last,
              style: TextStyle(
                color: Colors.white.withAlpha(128), // 0.5 opacity
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}