// lib/ui/widgets/media_preview_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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
  final Map<String, VideoPlayerController> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeVideoControllers();
  }

  @override
  void didUpdateWidget(MediaPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaPaths != widget.mediaPaths) {
      _disposeVideoControllers();
      _initializeVideoControllers();
    }
  }

  @override
  void dispose() {
    _disposeVideoControllers();
    _pageController.dispose();
    super.dispose();
  }

  void _initializeVideoControllers() {
    for (final path in widget.mediaPaths) {
      if (_mediaService.isVideoFile(path)) {
        try {
          final file = File(path);
          if (file.existsSync()) {
            final controller = VideoPlayerController.file(file);
            _videoControllers[path] = controller;
            controller.initialize().then((_) {
              // Ensure the controller is still needed when initialization completes
              if (mounted && _videoControllers.containsKey(path)) {
                setState(() {});
              }
            });
          }
        } catch (e) {
          debugPrint('Error initializing video controller: $e');
        }
      }
    }
  }

  void _disposeVideoControllers() {
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
  }

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
                        icon: const Icon(
                          Icons.arrow_back_ios_rounded,
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
                        icon: const Icon(
                          Icons.arrow_forward_ios_rounded,
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
                  ? _buildVideoPreview(path)
                  : Image.file(
                File(path),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading image: $error');
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Overlay for video controls
          if (isVideo && _videoControllers[path]?.value.isInitialized == true)
            Positioned.fill(
              child: Center(
                child: IconButton(
                  icon: Icon(
                    _videoControllers[path]!.value.isPlaying
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    size: 48,
                    color: Colors.white.withAlpha(204), // 0.8 opacity
                  ),
                  onPressed: () {
                    setState(() {
                      if (_videoControllers[path]!.value.isPlaying) {
                        _videoControllers[path]!.pause();
                      } else {
                        _videoControllers[path]!.play();
                      }
                    });
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
                color: Colors.black.withAlpha(128), // 0.5 opacity
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.close,
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

  Widget _buildVideoPreview(String path) {
    final controller = _videoControllers[path];

    if (controller?.value.isInitialized != true) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Calculate a safe aspect ratio (default to 16:9 if extreme values)
    double aspectRatio = controller!.value.aspectRatio;
    if (aspectRatio <= 0.1 || aspectRatio >= 10.0) {
      aspectRatio = 16/9;
    }

    return Center(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: VideoPlayer(controller),
      ),
    );
  }
}