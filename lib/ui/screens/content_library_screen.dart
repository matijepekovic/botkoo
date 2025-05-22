// lib/ui/screens/content_library_screen.dart - Enhanced with bulk selection and delete
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
  bool _isGridView = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final List<ContentType> _contentTypeFilters = ContentType.values;

  // Selection state
  bool _isSelectionMode = false;
  final Set<int> _selectedItems = <int>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter content items based on selected filters and search query
  List<ContentItem> _getFilteredContent(List<ContentItem> items) {
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

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedItems.clear();
      }
    });
  }

  void _toggleItemSelection(int itemId) {
    setState(() {
      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
      } else {
        _selectedItems.add(itemId);
      }
    });
  }

  void _selectAllVisible(List<ContentItem> visibleItems) {
    setState(() {
      for (final item in visibleItems) {
        if (item.id != null) {
          _selectedItems.add(item.id!);
        }
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedItems.clear();
    });
  }

  void _showBulkDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Content'),
        content: Text('Are you sure you want to delete ${_selectedItems.length} selected items? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _performBulkDelete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _performBulkDelete() async {
    final provider = Provider.of<ContentProvider>(context, listen: false);
    final selectedIds = List<int>.from(_selectedItems);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Deleting content...'),
            ],
          ),
        ),
      ),
    );

    // Delete items one by one
    int deletedCount = 0;
    for (final id in selectedIds) {
      try {
        await provider.deleteContent(id);
        deletedCount++;
      } catch (e) {
        // Continue deleting other items even if one fails
        debugPrint('Failed to delete item $id: $e');
      }
    }

    // Close loading dialog
    if (mounted) Navigator.pop(context);

    // Clear selection and exit selection mode
    setState(() {
      _selectedItems.clear();
      _isSelectionMode = false;
    });

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted $deletedCount of ${selectedIds.length} items'),
          backgroundColor: deletedCount == selectedIds.length ? Colors.green : Colors.orange,
        ),
      );
    }
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

  Widget _buildContentTypeFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
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

  // Build the top action bar when in selection mode
  Widget _buildSelectionActionBar(List<ContentItem> filteredItems) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedItems.length} selected',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () => _selectAllVisible(filteredItems),
            child: const Text('Select All'),
          ),
          TextButton(
            onPressed: _clearSelection,
            child: const Text('Clear'),
          ),
          const Spacer(),
          IconButton(
            onPressed: _selectedItems.isNotEmpty ? _showBulkDeleteDialog : null,
            icon: FaIcon(
              FontAwesomeIcons.trash,
              color: _selectedItems.isNotEmpty ? Colors.red : Colors.grey,
            ),
            tooltip: 'Delete Selected',
          ),
          IconButton(
            onPressed: _toggleSelectionMode,
            icon: const FaIcon(FontAwesomeIcons.xmark),
            tooltip: 'Exit Selection',
          ),
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
          // Tabs and view toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
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
                IconButton(
                  icon: FaIcon(_isGridView ? FontAwesomeIcons.list : FontAwesomeIcons.tableList),
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                  tooltip: _isGridView ? 'List view' : 'Grid view',
                ),
                IconButton(
                  icon: FaIcon(
                    _isSelectionMode ? FontAwesomeIcons.squareCheck : FontAwesomeIcons.square,
                    color: _isSelectionMode ? Theme.of(context).colorScheme.primary : null,
                  ),
                  onPressed: _toggleSelectionMode,
                  tooltip: _isSelectionMode ? 'Exit Selection' : 'Select Multiple',
                ),
              ],
            ),
          ),

          // Search bar
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
                  isSelectionMode: _isSelectionMode,
                  selectedItems: _selectedItems,
                  onToggleSelection: _toggleItemSelection,
                  onSelectionActionBar: _buildSelectionActionBar,
                ),
                _ContentList(
                  status: 'published',
                  emptyMessage: 'No published content yet.',
                  filterContent: _getFilteredContent,
                  isGridView: _isGridView,
                  isSelectionMode: _isSelectionMode,
                  selectedItems: _selectedItems,
                  onToggleSelection: _toggleItemSelection,
                  onSelectionActionBar: _buildSelectionActionBar,
                ),
              ],
            ),
          ),

          // Create new content button
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
  final bool isSelectionMode;
  final Set<int> selectedItems;
  final Function(int) onToggleSelection;
  final Widget Function(List<ContentItem>) onSelectionActionBar;

  const _ContentList({
    required this.status,
    required this.emptyMessage,
    required this.filterContent,
    required this.isGridView,
    required this.isSelectionMode,
    required this.selectedItems,
    required this.onToggleSelection,
    required this.onSelectionActionBar,
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

        return Column(
          children: [
            // Selection action bar
            if (isSelectionMode && selectedItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: onSelectionActionBar(items),
              ),

            // Content grid/list
            Expanded(
              child: isGridView
                  ? GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _ContentGridItem(
                    item: item,
                    isSelectionMode: isSelectionMode,
                    isSelected: selectedItems.contains(item.id),
                    onToggleSelection: () => onToggleSelection(item.id!),
                  );
                },
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _ContentCard(
                    item: item,
                    isSelectionMode: isSelectionMode,
                    isSelected: selectedItems.contains(item.id),
                    onToggleSelection: () => onToggleSelection(item.id!),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ContentGridItem extends StatelessWidget {
  final ContentItem item;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onToggleSelection;

  const _ContentGridItem({
    required this.item,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isSelectionMode
            ? onToggleSelection
            : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContentEditorScreen(contentItem: item),
            ),
          );
        },
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Media preview or text preview
                Expanded(
                  child: item.mediaUrls.isNotEmpty && item.mediaUrls.first.isNotEmpty
                      ? _buildMediaPreview(item.mediaUrls.first)
                      : _buildTextPreview(),
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

            // Selection checkbox
            if (isSelectionMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(51),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggleSelection(),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      color: Colors.grey.withAlpha(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onToggleSelection;

  const _ContentCard({
    required this.item,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: isSelectionMode
            ? onToggleSelection
            : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContentEditorScreen(contentItem: item),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Selection checkbox
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggleSelection(),
                  ),
                ),

              // Content details
              Expanded(
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
                        if (!isSelectionMode)
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
                                    FaIcon(FontAwesomeIcons.penToSquare, size: 16),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    FaIcon(FontAwesomeIcons.trash, size: 16),
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