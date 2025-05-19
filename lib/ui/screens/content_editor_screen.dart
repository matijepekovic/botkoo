import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:botko/core/models/content_item.dart';
import 'package:botko/core/providers/content_provider.dart';

class ContentEditorScreen extends StatefulWidget {
  final ContentItem? contentItem;

  const ContentEditorScreen({super.key, this.contentItem});

  @override
  State<ContentEditorScreen> createState() => _ContentEditorScreenState();
}

class _ContentEditorScreenState extends State<ContentEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.contentItem != null;
    _titleController =
        TextEditingController(text: widget.contentItem?.title ?? '');
    _contentController =
        TextEditingController(text: widget.contentItem?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Content' : 'Create Content'),
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
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  hintText: 'Enter your content here',
                  border: OutlineInputBorder(),
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
              const Text(
                'Note: Media upload functionality will be available in future updates.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
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

  void _saveContent(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<ContentProvider>(context, listen: false);

      if (_isEditing && widget.contentItem != null) {
        // Update existing content
        final updatedItem = ContentItem(
          id: widget.contentItem!.id,
          title: _titleController.text,
          content: _contentController.text,
          mediaUrls: widget.contentItem!.mediaUrls,
          createdAt: widget.contentItem!.createdAt,
          updatedAt: DateTime.now(),
          status: widget.contentItem!.status,
        );

        // Extract async logic with captured context
        _performUpdate(provider, updatedItem);
      } else {
        // Create new content
        _performCreate(
          provider,
          _titleController.text,
          _contentController.text,
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

  Future<void> _performCreate(ContentProvider provider, String title,
      String content) async {
    await provider.createContent(title, content, []);
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