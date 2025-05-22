// lib/ui/screens/content_library_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:botko/core/models/content_item.dart';
import 'package:botko/core/models/content_type.dart';
import 'package:botko/core/providers/content_provider.dart';
import 'package:botko/core/providers/account_provider.dart';
import 'package:botko/ui/screens/content_editor_screen.dart';
import 'package:botko/ui/utils/content_type_helper.dart';
import 'package:botko/core/services/media_service.dart';

class ContentLibraryScreen extends StatefulWidget {
  const ContentLibraryScreen({super.key});

  @override
  State<ContentLibraryScreen> createState() => _ContentLibraryScreenState();
}

class _ContentLibraryScreenState extends State<ContentLibraryScreen> {
  ContentType? _selectedContentTypeFilter;
  bool _isGridView = true; // Default to grid view
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final List<ContentType> _contentTypeFilters = ContentType.values;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter content items based on selected filters and search query
  List<ContentItem> _getFilteredContent(List<ContentItem> items) {
    // Start with filtering by status (handled in _ContentList)

    // Filter by content type if selected
    if (_selectedContentTypeFilter != null) {
      items = items.where((item) =>
      item.contentType == _selectedContentTypeFilter
      ).toList();
    }

    // Filter by search query if not empty
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      items = items.where((item) =>
      item.title.toLowerCase().contains(query) ||
          item.content.toLowerCase().contains(query)
      ).toList();
    }

    return items;
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
                            trailing: isUsable ? const FaIcon(FontAwesomeIcons.angleRight) : null,
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

  // Build content type filters
  Widget _buildContentTypeFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // All types filter
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              avatar: const FaIcon(FontAwesomeIcons.check, size: 12),
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
          // Individual content type filters
          ..._contentTypeFilters.map((type) => Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              avatar: ContentTypeHelper.getIcon(
                type,
                size: 16,
                color: _selectedContentTypeFilter == type
                    ? Colors.white
                    : ContentTypeHelper.getColor(type),
              ),
              label: Text(type.displayName),
              selected: _selectedContentTypeFilter == type,
              onSelected: (selected) {
                setState(() {
                  _selectedContentTypeFilter = selected ? type : null;
                });
              },
            ),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Tabs and view toggle MOVED TO TOP
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                // Tabs
                Expanded(
                  child: TabBar(
                    tabs: const [
                      Tab(text: 'Drafts'),
                      Tab(text: 'Published'),
                    ],
                    labelColor: Theme.of(context).colorScheme.primary,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                  ),
                ),

                // Grid/List toggle - NOW USING FONTAWESOME
                IconButton(
                  icon: FaIcon(_isGridView ? FontAwesomeIcons.list : FontAwesomeIcons.tableList),
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                  tooltip: _isGridView ? 'List view' : 'Grid view',
                ),
              ],
            ),
          ),

          // Search bar MOVED BELOW TABS - FIXED ICON CENTERING
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search content',
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                prefixIcon: const Align(
                  widthFactor: 1.0,
                  heightFactor: 1.0,
                  child: FaIcon(
                    FontAwesomeIcons.magnifyingGlass,
                    size: 16,
                  ),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const FaIcon(FontAwesomeIcons.xmark, size: 16),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Content type filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: _buildContentTypeFilters(),
          ),

          // Content list/grid
          Expanded(
            child: TabBarView(
              children: [
                _ContentList(
                  status: 'draft',
                  emptyMessage: 'No drafts yet. Create your first content!',
                  filterContent: _getFilteredContent,
                  isGridView: _isGridView,
                ),
                _ContentList(
                  status: 'published',
                  emptyMessage: 'No published content yet.',
                  filterContent: _getFilteredContent,
                  isGridView: _isGridView,
                ),
              ],
            ),
          ),

          // Create new content button - USING FONTAWESOME
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  _showContentTypeSelector();
                },
                icon: const FaIcon(FontAwesomeIcons.plus),
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
  final bool isGridView;

  const _ContentList({
    required this.status,
    required this.emptyMessage,
    required this.filterContent,
    required this.isGridView,
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
                  FaIcon(
                    FontAwesomeIcons.noteSticky,
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

        // Build grid or list view based on selection
        if (isGridView) {
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, // 4x4 grid
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _ContentGridItem(item: item);
            },
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _ContentCard(item: item);
            },
          );
        }
      },
    );
  }
}

class _ContentGridItem extends StatelessWidget {
  final ContentItem item;

  const _ContentGridItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContentEditorScreen(contentItem: item),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media preview or text preview - REPLACE THIS SECTION
            Expanded(
              child: item.mediaUrls.isNotEmpty && item.mediaUrls.first.isNotEmpty
                  ? _buildMediaPreview(item.mediaUrls.first)
                  : _buildTextPreview(), // Actually call the method here
            ),

            // Item details
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(context, item.status).withAlpha(50),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(context, item.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const Spacer(),
                      ContentTypeHelper.getIcon(
                        item.contentType,
                        size: 14,
                        color: ContentTypeHelper.getColor(item.contentType),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Text preview method for text-only content
  Widget _buildTextPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      color: Colors.grey.withAlpha(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Show text content with ellipsis
          Expanded(
            child: Center(
              child: Text(
                item.content,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildMediaPreview(String path) {
    final mediaService = MediaService();

    try {
      if (mediaService.isImageFile(path)) {
        return Image.file(
          File(path),
          fit: BoxFit.cover,
          height: double.infinity,
          width: double.infinity,
          errorBuilder: (_, __, ___) => const FaIcon(FontAwesomeIcons.image),
        );
      } else if (mediaService.isVideoFile(path)) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: FaIcon(FontAwesomeIcons.play, color: Colors.white),
          ),
        );
      } else {
        return const FaIcon(FontAwesomeIcons.file);
      }
    } catch (e) {
      return const FaIcon(FontAwesomeIcons.circleExclamation);
    }
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
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const FaIcon(FontAwesomeIcons.penToSquare, size: 16),
                            const SizedBox(width: 8),
                            const Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const FaIcon(FontAwesomeIcons.trash, size: 16),
                            const SizedBox(width: 8),
                            const Text('Delete'),
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

              // Media preview (if available)
              if (item.mediaUrls.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: _buildMediaPreview(item.mediaUrls.first),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item.mediaUrls.length} media ${item.mediaUrls.length > 1 ? 'files' : 'file'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
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

  Widget _buildMediaPreview(String path) {
    final mediaService = MediaService();

    try {
      if (mediaService.isImageFile(path)) {
        return Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const FaIcon(FontAwesomeIcons.image),
        );
      } else if (mediaService.isVideoFile(path)) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: FaIcon(FontAwesomeIcons.play, color: Colors.white),
          ),
        );
      } else {
        return const FaIcon(FontAwesomeIcons.file);
      }
    } catch (e) {
      return const FaIcon(FontAwesomeIcons.circleExclamation);
    }
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