// lib/ui/screens/content_editor_screen.dart (Updated)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:botko/core/models/content_item.dart';
import 'package:botko/core/models/content_type.dart';
import 'package:botko/core/models/content_metadata.dart';
import 'package:botko/core/providers/content_provider.dart';

class ContentEditorScreen extends StatefulWidget {
  final ContentItem? contentItem;
  final ContentType contentType;

  const ContentEditorScreen({
    super.key,
    this.contentItem,
    this.contentType = ContentType.textOnly,
  });

  @override
  State<ContentEditorScreen> createState() => _ContentEditorScreenState();
}

class _ContentEditorScreenState extends State<ContentEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _hashtagsController;
  late final TextEditingController _tagsController;
  late ContentVisibility _visibility;
  late ContentType _contentType;
  bool _isEditing = false;
  List<String> _mediaUrls = [];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.contentItem != null;
    _contentType = _isEditing ? widget.contentItem!.contentType : widget.contentType;

    // Initialize controllers
    _titleController = TextEditingController(text: widget.contentItem?.title ?? '');
    _contentController = TextEditingController(text: widget.contentItem?.content ?? '');

    // Initialize metadata controllers
    final metadata = widget.contentItem?.metadata ?? ContentMetadata();
    _descriptionController = TextEditingController(text: metadata.description ?? '');
    _hashtagsController = TextEditingController(text: metadata.hashtags.join(' '));
    _tagsController = TextEditingController(text: metadata.tags.join(', '));
    _visibility = metadata.visibility;

    // Initialize media urls
    _mediaUrls = widget.contentItem?.mediaUrls ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _descriptionController.dispose();
    _hashtagsController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit ${_contentType.displayName}' : 'Create ${_contentType.displayName}'),
        actions: [
          if (_isEditing && widget.contentItem?.status == 'draft')
            TextButton.icon(
              onPressed: () {
                _updateContentStatus(context, 'published');
              },
              icon: const FaIcon(FontAwesomeIcons.check),
              label: const Text('Publish'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field - common for all content types
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter a title for your content',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Content fields based on content type
              ..._buildContentTypeFields(),

              const SizedBox(height: 16),

              // Media upload section
              _buildMediaUploadSection(),

              const SizedBox(height: 24),

              // Visibility selector
              _buildVisibilitySelector(),

              const SizedBox(height: 24),

              // Save/Cancel buttons
              Consumer<ContentProvider>(
                builder: (context, provider, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: provider.isLoading
                              ? null
                              : () => _saveContent(context),
                          child: provider.isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : Text(_isEditing ? 'Update' : 'Save'),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Error display
              Consumer<ContentProvider>(
                builder: (context, provider, child) {
                  if (provider.error != null) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        provider.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build different form fields based on content type
  List<Widget> _buildContentTypeFields() {
    final List<Widget> fields = [];

    // Main content field - different label based on type
    String contentLabel;
    String contentHint;
    int? contentMaxLines;

    switch (_contentType) {
      case ContentType.textOnly:
        contentLabel = 'Post Text';
        contentHint = 'What would you like to say?';
        contentMaxLines = 8;
        break;
      case ContentType.textWithImage:
        contentLabel = 'Post Text';
        contentHint = 'Add text to go with your image';
        contentMaxLines = 8;
        break;
      case ContentType.image:
        contentLabel = 'Caption';
        contentHint = 'Add a caption for your image (optional)';
        contentMaxLines = 4;
        break;
      case ContentType.carousel:
        contentLabel = 'Caption';
        contentHint = 'Add a caption for your carousel';
        contentMaxLines = 4;
        break;
      case ContentType.story:
        contentLabel = 'Caption';
        contentHint = 'Add a caption for your story (optional)';
        contentMaxLines = 2;
        break;
      case ContentType.reel:
        contentLabel = 'Caption';
        contentHint = 'Add a caption for your reel';
        contentMaxLines = 4;
        break;
      case ContentType.shortVideo:
        contentLabel = 'Caption';
        contentHint = 'Add a caption for your video';
        contentMaxLines = 4;
        break;
      case ContentType.longVideo:
        contentLabel = 'Description';
        contentHint = 'Add a description for your video';
        contentMaxLines = 8;
        break;
    }

    fields.add(
      TextFormField(
        controller: _contentController,
        decoration: InputDecoration(
          labelText: contentLabel,
          hintText: contentHint,
          border: const OutlineInputBorder(),
        ),
        maxLines: contentMaxLines,
        validator: (value) {
          if (_contentType == ContentType.textOnly && (value == null || value.isEmpty)) {
            return 'Please enter some content';
          }
          return null;
        },
      ),
    );

    // Additional fields based on content type
    if (_contentType == ContentType.reel ||
        _contentType == ContentType.shortVideo ||
        _contentType == ContentType.longVideo) {
      // Video-specific fields
      fields.add(const SizedBox(height: 16));
      fields.add(
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Extended Description',
            hintText: 'Add more details about your video',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
      );
    }

    // Hashtags field for platforms that support them
    if (_contentType == ContentType.image ||
        _contentType == ContentType.carousel ||
        _contentType == ContentType.reel ||
        _contentType == ContentType.shortVideo) {
      fields.add(const SizedBox(height: 16));
      fields.add(
        TextFormField(
          controller: _hashtagsController,
          decoration: const InputDecoration(
            labelText: 'Hashtags',
            hintText: 'Add hashtags separated by space (e.g. #social #media)',
            border: OutlineInputBorder(),
          ),
        ),
      );
    }

    // YouTube-specific fields
    if (_contentType == ContentType.longVideo) {
      fields.add(const SizedBox(height: 16));
      fields.add(
        TextFormField(
          controller: _tagsController,
          decoration: const InputDecoration(
            labelText: 'Tags',
            hintText: 'Add tags separated by commas (e.g. social media, tutorial)',
            border: OutlineInputBorder(),
          ),
        ),
      );
    }

    return fields;
  }

  // Media upload section
  Widget _buildMediaUploadSection() {
    // Determine media label based on content type
    String mediaLabel;
    String mediaHint;

    switch (_contentType) {
      case ContentType.textOnly:
        return const SizedBox.shrink(); // No media for text-only
      case ContentType.textWithImage:
      case ContentType.image:
        mediaLabel = 'Image';
        mediaHint = 'Upload an image';
        break;
      case ContentType.carousel:
        mediaLabel = 'Images';
        mediaHint = 'Upload multiple images (up to 10)';
        break;
      case ContentType.story:
        mediaLabel = 'Story Media';
        mediaHint = 'Upload a photo or video for your story';
        break;
      case ContentType.reel:
        mediaLabel = 'Reel Video';
        mediaHint = 'Upload a vertical video (max 60 seconds)';
        break;
      case ContentType.shortVideo:
        mediaLabel = 'Short Video';
        mediaHint = 'Upload a short video (max 3 minutes)';
        break;
      case ContentType.longVideo:
        mediaLabel = 'Video';
        mediaHint = 'Upload your video';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mediaLabel,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),

        // Media preview or upload area
        _mediaUrls.isEmpty
            ? _buildMediaUploadPlaceholder(mediaHint)
            : _buildMediaPreview(),
      ],
    );
  }

  // Media upload placeholder
  Widget _buildMediaUploadPlaceholder(String hint) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              _getMediaUploadIcon(),
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickMedia,
              icon: const FaIcon(FontAwesomeIcons.upload, size: 16),
              label: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  // Choose appropriate icon for media upload
  IconData _getMediaUploadIcon() {
    switch (_contentType) {
      case ContentType.textOnly:
        return FontAwesomeIcons.font;
      case ContentType.textWithImage:
      case ContentType.image:
        return FontAwesomeIcons.image;
      case ContentType.carousel:
        return FontAwesomeIcons.images;
      case ContentType.story:
        return FontAwesomeIcons.cameraRetro;
      case ContentType.reel:
      case ContentType.shortVideo:
      case ContentType.longVideo:
        return FontAwesomeIcons.video;
    }
  }

  // Media preview
  Widget _buildMediaPreview() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Preview content
          Center(
            child: Text(
              'Media Preview (${_mediaUrls.length} files)',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),

          // Upload new / remove buttons
          Positioned(
            bottom: 8,
            right: 8,
            child: Row(
              children: [
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 16),
                  onPressed: _pickMedia,
                  tooltip: 'Replace media',
                ),
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.trash, size: 16),
                  onPressed: () {
                    setState(() {
                      _mediaUrls = [];
                    });
                  },
                  tooltip: 'Remove all media',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Visibility selector
  Widget _buildVisibilitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visibility',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ContentVisibility>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          value: _visibility,
          items: ContentVisibility.values.map((visibility) {
            return DropdownMenuItem<ContentVisibility>(
              value: visibility,
              child: Text(visibility.displayName),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _visibility = value;
              });
            }
          },
        ),
      ],
    );
  }

  // Media picker
  void _pickMedia() {
    // This would be implemented with file picker in a real app
    // For now, simulate adding a media URL
    setState(() {
      if (_contentType == ContentType.carousel) {
        // For carousel, allow multiple images
        _mediaUrls = [
          'image1.jpg',
          'image2.jpg',
          'image3.jpg',
        ];
      } else if (_contentType == ContentType.textWithImage ||
          _contentType == ContentType.image) {
        _mediaUrls = ['image.jpg'];
      } else if (_contentType == ContentType.reel ||
          _contentType == ContentType.shortVideo) {
        _mediaUrls = ['video.mp4'];
      } else if (_contentType == ContentType.longVideo) {
        _mediaUrls = ['long_video.mp4'];
      } else if (_contentType == ContentType.story) {
        _mediaUrls = ['story.mp4'];
      }
    });
  }

  // Inside ContentEditorScreen.dart, replace the _saveContent method with this:
  void _saveContent(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<ContentProvider>(context, listen: false);

      // Process hashtags
      final List<String> hashtags = _hashtagsController.text
          .split(' ')
          .where((tag) => tag.isNotEmpty)
          .toList();

      // Process tags
      final List<String> tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      // Create metadata
      final ContentMetadata metadata = ContentMetadata(
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        hashtags: hashtags,
        tags: tags,
        visibility: _visibility,
      );

      if (_isEditing && widget.contentItem != null) {
        // Update existing content
        final updatedItem = widget.contentItem!.copyWith(
          title: _titleController.text,
          content: _contentController.text,
          mediaUrls: _mediaUrls,
          updatedAt: DateTime.now(),
          contentType: _contentType,
          metadata: metadata,
        );

        _performUpdate(provider, updatedItem);
      } else {
        // Create new content
        _performCreate(
          provider,
          _titleController.text,
          _contentController.text,
          _mediaUrls,
          _contentType,
          metadata,
        );
      }
    }
  }

// Add these helper methods to handle async operations safely
  Future<void> _performUpdate(ContentProvider provider, ContentItem updatedItem) async {
    await provider.updateContent(updatedItem);
    if (!mounted) return; // Check if widget is still mounted

    if (provider.error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content updated successfully')),
      );
    }
  }

  Future<void> _performCreate(
      ContentProvider provider,
      String title,
      String content,
      List<String> mediaUrls,
      ContentType contentType,
      ContentMetadata metadata) async {
    await provider.createContent(
      title,
      content,
      mediaUrls,
      contentType: contentType,
      metadata: metadata,
    );
    if (!mounted) return; // Check if widget is still mounted

    if (provider.error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content created successfully')),
      );
    }
  }
  // Update content status
  void _updateContentStatus(BuildContext context, String status) {
    if (widget.contentItem?.id != null) {
      final provider = Provider.of<ContentProvider>(context, listen: false);
      _performStatusUpdate(provider, widget.contentItem!.id!, status);
    }
  }

  Future<void> _performStatusUpdate(ContentProvider provider, int itemId, String status) async {
    await provider.updateContentStatus(itemId, status);
    if (!mounted) return; // Check if widget is still mounted

    if (provider.error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Content ${status == 'published' ? 'published' : 'updated'} successfully')),
      );
    }
  }
}