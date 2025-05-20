// lib/ui/screens/content_library_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:botko/core/models/content_item.dart';
import 'package:botko/core/models/content_type.dart';
import 'package:botko/core/providers/content_provider.dart';
import 'package:botko/core/providers/account_provider.dart';
import 'package:botko/ui/screens/content_editor_screen.dart';
import 'package:botko/ui/utils/content_type_helper.dart';

class ContentLibraryScreen extends StatefulWidget {
  const ContentLibraryScreen({super.key});

  @override
  State<ContentLibraryScreen> createState() => _ContentLibraryScreenState();
}

class _ContentLibraryScreenState extends State<ContentLibraryScreen> {
  ContentType? _selectedContentTypeFilter;

  // Filter content items based on selected filters
  List<ContentItem> _getFilteredContent(List<ContentItem> items) {
    if (_selectedContentTypeFilter == null) {
      return items;
    }

    return items.where((item) =>
    item.contentType == _selectedContentTypeFilter
    ).toList();
  }

  // Build content type filter chips
  Widget _buildContentTypeFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: const Text('All Types'),
              selected: _selectedContentTypeFilter == null,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedContentTypeFilter = null;
                  });
                }
              },
            ),
          ),
          ...ContentType.values.map((type) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(type.displayName),
                selected: _selectedContentTypeFilter == type,
                onSelected: (selected) {
                  setState(() {
                    _selectedContentTypeFilter = selected ? type : null;
                  });
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showContentTypeSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Consumer<AccountProvider>(
              builder: (context, accountProvider, _) {
                // Get connected platforms
                final connectedPlatforms = accountProvider.accounts
                    .map((account) => account.platform)
                    .toSet();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Choose Content Type',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: ContentType.values.length,
                        itemBuilder: (context, index) {
                          final type = ContentType.values[index];

                          // Check if we have connected accounts that support this type
                          final supportedPlatforms = connectedPlatforms
                              .where((platform) => type.isCompatibleWith(platform))
                              .toList();

                          final bool isUsable = supportedPlatforms.isNotEmpty;

                          return ListTile(
                            leading: ContentTypeHelper.getIcon(
                              type,
                              color: isUsable
                                  ? ContentTypeHelper.getColor(type)
                                  : Colors.grey,
                            ),
                            title: Text(type.displayName),
                            subtitle: Text(
                              isUsable
                                  ? ContentTypeHelper.getDescription(type)
                                  : 'No connected accounts support this type',
                              style: TextStyle(
                                color: isUsable ? null : Colors.grey,
                              ),
                            ),
                            enabled: isUsable,
                            onTap: isUsable ? () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ContentEditorScreen(
                                    contentType: type,
                                  ),
                                ),
                              );
                            } : null,
                            trailing: isUsable ? const Icon(Icons.arrow_forward_ios) : null,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Drafts'),
              Tab(text: 'Published'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),

          // Optionally show content type filters
          // Padding(
          //   padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          //   child: _buildContentTypeFilters(),
          // ),

          Expanded(
            child: TabBarView(
              children: [
                _ContentList(
                  status: 'draft',
                  emptyMessage: 'No drafts yet. Create your first content!',
                  filterContent: _getFilteredContent,
                ),
                _ContentList(
                  status: 'published',
                  emptyMessage: 'No published content yet.',
                  filterContent: _getFilteredContent,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  // Use the type selector instead of directly going to editor
                  _showContentTypeSelector();
                },
                icon: const Icon(Icons.add),
                label: const Text('Create New Content'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentList extends StatelessWidget {
  final String status;
  final String emptyMessage;
  final Function(List<ContentItem>) filterContent;

  const _ContentList({
    required this.status,
    required this.emptyMessage,
    required this.filterContent,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ContentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final allItems = provider.contentItems
            .where((item) => item.status == status)
            .toList();

        // Apply filtering
        final items = filterContent(allItems);

        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_alt_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withAlpha(128),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _ContentCard(item: item);
          },
        );
      },
    );
  }
}

class _ContentCard extends StatelessWidget {
  final ContentItem item;

  const _ContentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContentEditorScreen(contentItem: item),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (item.contentType != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ContentTypeHelper.getIcon(
                        item.contentType,
                        size: 16,
                        color: ContentTypeHelper.getColor(item.contentType),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContentEditorScreen(
                                contentItem: item,
                              ),
                            ),
                          );
                          break;
                        case 'delete':
                          _showDeleteDialog(context, item);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created: ${_formatDate(item.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    item.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(context, item.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'scheduled':
        return Colors.orange;
      case 'published':
        return Colors.green;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  void _showDeleteDialog(BuildContext context, ContentItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Provider.of<ContentProvider>(context, listen: false)
                  .deleteContent(item.id!);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}