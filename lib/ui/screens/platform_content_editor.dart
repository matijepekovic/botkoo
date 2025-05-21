// lib/ui/screens/platform_content_editor.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:botko/core/models/content_item.dart';
import 'package:botko/core/providers/content_provider.dart';

class PlatformContentEditor extends StatefulWidget {
  final ContentItem? contentItem;
  final String platform;

  const PlatformContentEditor({
    super.key,
    this.contentItem,
    required this.platform,
  });

  @override
  State<PlatformContentEditor> createState() => _PlatformContentEditorState();
}

class _PlatformContentEditorState extends State<PlatformContentEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _hashtagsController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagsController;
  bool _isEditing = false;
  late Map<String, dynamic> _platformMetadata;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.contentItem != null;
    _titleController = TextEditingController(text: widget.contentItem?.title ?? '');
    _contentController = TextEditingController(text: widget.contentItem?.content ?? '');

    // Initialize platform-specific controllers
    _platformMetadata = widget.contentItem?.platformMetadata?[widget.platform] ?? {};

    _hashtagsController = TextEditingController(
      text: _platformMetadata['hashtags'] ?? '',
    );

    _descriptionController = TextEditingController(
      text: _platformMetadata['description'] ?? '',
    );

    _tagsController = TextEditingController(
      text: _platformMetadata['tags'] ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _hashtagsController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_isEditing ? 'Edit' : 'Create'} ${_getPlatformName()} Content'),
        actions: [
          if (_isEditing && widget.contentItem?.status == 'draft')
            TextButton.icon(
              onPressed: () {
                _updateContentStatus(context, 'published');
              },
              icon: const Icon(Icons.publish),
              label: const Text('Publish'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              // Platform-specific fields
              ..._buildPlatformSpecificFields(),

              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: _getContentLabel(),
                  hintText: _getContentHint(),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Media upload section
              _buildMediaUploadSection(),

              const SizedBox(height: 24),
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

  String _getPlatformName() {
    switch (widget.platform) {
      case 'tiktok':
        return 'TikTok';
      case 'threads':
        return 'Threads';
      case 'youtube':
        return 'YouTube';
      default:
        return widget.platform.substring(0, 1).toUpperCase() + widget.platform.substring(1);
    }
  }

  String _getContentLabel() {
    switch (widget.platform) {
      case 'tiktok':
        return 'Caption';
      case 'youtube':
        return 'Script/Notes';
      case 'threads':
        return 'Content';
      default:
        return 'Content';
    }
  }

  String _getContentHint() {
    switch (widget.platform) {
      case 'tiktok':
        return 'Enter your TikTok caption here';
      case 'youtube':
        return 'Enter your YouTube video script or notes here';
      case 'threads':
        return 'Enter your Threads post content here';
      default:
        return 'Enter your content here';
    }
  }

  List<Widget> _buildPlatformSpecificFields() {
    final List<Widget> fields = [];

    switch (widget.platform) {
      case 'tiktok':
        fields.add(
          TextFormField(
            controller: _hashtagsController,
            decoration: const InputDecoration(
              labelText: 'Hashtags',
              hintText: 'Add trending hashtags (e.g., #fyp #trending)',
              border: OutlineInputBorder(),
            ),
          ),
        );
        break;

      case 'youtube':
        fields.add(
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Enter detailed video description with SEO keywords',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
          ),
        );
        fields.add(const SizedBox(height: 16));
        fields.add(
          TextFormField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags',
              hintText: 'Enter comma-separated tags (e.g., botko, social media, automation)',
              border: OutlineInputBorder(),
            ),
          ),
        );
        // Add channel selection dropdown here if needed
        break;

      case 'threads':
      // Threads-specific fields if any
        break;
    }

    // Add spacing if we added fields
    if (fields.isNotEmpty) {
      fields.add(const SizedBox(height: 16));
    }

    return fields;
  }

  Widget _buildMediaUploadSection() {
    late String mediaType;
    late String mediaHint;

    switch (widget.platform) {
      case 'tiktok':
        mediaType = 'Video';
        mediaHint = 'Upload a short-form vertical video for TikTok';
        break;
      case 'youtube':
        mediaType = 'Video';
        mediaHint = 'Upload your long-form video content for YouTube';
        break;
      case 'threads':
        mediaType = 'Image (Optional)';
        mediaHint = 'Add images to your Threads post (optional)';
        break;
      default:
        mediaType = 'Media';
        mediaHint = 'Upload media for your post';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mediaType,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  mediaHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement media upload functionality
                  },
                  icon: const Icon(Icons.add),
                  label: Text('Add $mediaType'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Note: Media upload functionality will be available in future updates.',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _saveContent(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<ContentProvider>(context, listen: false);

      // Collect platform-specific metadata
      final Map<String, dynamic> platformMetadata = {};

      switch (widget.platform) {
        case 'tiktok':
          platformMetadata['hashtags'] = _hashtagsController.text;
          break;
        case 'youtube':
          platformMetadata['description'] = _descriptionController.text;
          platformMetadata['tags'] = _tagsController.text;
          break;
      }

      if (_isEditing && widget.contentItem != null) {
        // Update existing content
        // First, get existing metadata from all platforms
        final Map<String, dynamic> allPlatformMetadata =
            widget.contentItem!.platformMetadata ?? {};

        // Update only this platform's metadata
        allPlatformMetadata[widget.platform] = platformMetadata;

        final updatedItem = ContentItem(
          id: widget.contentItem!.id,
          title: _titleController.text,
          content: _contentController.text,
          mediaUrls: widget.contentItem!.mediaUrls,
          createdAt: widget.contentItem!.createdAt,
          updatedAt: DateTime.now(),
          status: widget.contentItem!.status,
          platformMetadata: allPlatformMetadata,
        );

        // Extract async logic with captured context
        _performUpdate(provider, updatedItem);
      } else {
        // Create new content with platform-specific metadata


        // Create new content
        _performCreate(
          provider,
          _titleController.text,
          _contentController.text,
          platformMetadata: platformMetadata,
        );
      }
    }
  }

  // Extracted methods that handle the async operations
  Future<void> _performUpdate(ContentProvider provider,
      ContentItem updatedItem) async {
    await provider.updateContent(updatedItem);
    if (!mounted) return;
    _handleSuccess(provider, context, 'Content updated successfully');
  }

  Future<void> _performCreate(
      ContentProvider provider,
      String title,
      String content,
      {Map<String, dynamic>? platformMetadata}) async {
    // Make sure createContent method accepts platformMetadata as a named parameter
    await provider.createContent(
        title,
        content,
        [],
        platformMetadata: platformMetadata
    );
    if (!mounted) return;
    _handleSuccess(provider, context, 'Content created successfully');
  }

  // Helper to handle navigation and snackbar after success
  void _handleSuccess(ContentProvider provider, BuildContext context,
      String message) {
    if (provider.error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _updateContentStatus(BuildContext context, String status) {
    if (widget.contentItem?.id != null) {
      final provider = Provider.of<ContentProvider>(context, listen: false);
      _performStatusUpdate(provider, widget.contentItem!.id!, status);
    }
  }

  Future<void> _performStatusUpdate(ContentProvider provider, int itemId,
      String status) async {
    await provider.updateContentStatus(itemId, status);
    if (!mounted) return;

    if (provider.error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Content ${status == 'published'
            ? 'published'
            : 'updated'} successfully')),
      );
    }
  }
}