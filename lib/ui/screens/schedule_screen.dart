// lib/ui/screens/schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:botko/core/models/scheduled_post.dart';
import 'package:botko/core/providers/schedule_provider.dart';
import 'package:botko/ui/screens/post_scheduler_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Store posts for the selected day to avoid recalculation
  List<ScheduledPost> _postsForSelectedDay = [];

  // Pagination properties
  static const int _postsPerPage = 5;
  int _currentPage = 0;

  // Helper methods for platform display
  Widget _getPlatformIcon(String platform, {double size = 16, Color? color}) {
    switch (platform.toLowerCase()) {
      case 'twitter':
        return FaIcon(FontAwesomeIcons.xTwitter, size: size, color: color ?? Colors.black);
      case 'facebook':
        return FaIcon(FontAwesomeIcons.facebook, size: size, color: color ?? const Color(0xFF1877F2));
      case 'instagram':
        return FaIcon(FontAwesomeIcons.instagram, size: size, color: color ?? const Color(0xFFE1306C));
      case 'linkedin':
        return FaIcon(FontAwesomeIcons.linkedin, size: size, color: color ?? const Color(0xFF0077B5));
      case 'tiktok':
        return FaIcon(FontAwesomeIcons.tiktok, size: size, color: color ?? Colors.black);
      case 'threads':
        return FaIcon(FontAwesomeIcons.at, size: size, color: color ?? Colors.black);
      case 'youtube':
        return FaIcon(FontAwesomeIcons.youtube, size: size, color: color ?? const Color(0xFFFF0000));
      default:
        return FaIcon(FontAwesomeIcons.globe, size: size, color: color ?? Colors.grey);
    }
  }

  String _getPlatformDisplayName(String platform) {
    switch (platform.toLowerCase()) {
      case 'twitter':
        return 'X';
      default:
        return platform.substring(0, 1).toUpperCase() + platform.substring(1);
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    // Initialize the posts for the selected day after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePostsForSelectedDay();
    });

    // Add listener to update posts when the provider changes
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    scheduleProvider.addListener(_scheduleProviderListener);
  }

  @override
  void dispose() {
    // Store provider locally before calling super.dispose()
    ScheduleProvider? scheduleProvider;
    try {
      scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    } catch (e) {
      // Provider might already be unavailable, that's okay
    }

    // Only remove listener if we successfully got the provider
    if (scheduleProvider != null) {
      scheduleProvider.removeListener(_scheduleProviderListener);
    }

    super.dispose();
  }

  // Update stored posts when the provider changes
  void _scheduleProviderListener() {
    if (mounted && _selectedDay != null) {
      final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
      if (!scheduleProvider.isLoading) {
        setState(() {
          _postsForSelectedDay = scheduleProvider.getPostsForDay(_selectedDay!);
        });
      }
    }
  }

  // Update the stored posts for the selected day
  void _updatePostsForSelectedDay() {
    if (_selectedDay != null) {
      final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
      setState(() {
        _postsForSelectedDay = scheduleProvider.getPostsForDay(_selectedDay!);
      });
    }
  }

  // Reset pagination to the first page
  void _resetPagination() {
    setState(() {
      _currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCalendar(),
        const SizedBox(height: 16),
        _buildScheduledPosts(),
        const SizedBox(height: 16),
        _buildScheduleButton(),
      ],
    );
  }

  Widget _buildCalendar() {
    return Consumer<ScheduleProvider>(
      builder: (context, scheduleProvider, _) {
        return TableCalendar(
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
              // Update the posts when a new day is selected
              _postsForSelectedDay = scheduleProvider.getPostsForDay(selectedDay);
              _resetPagination(); // Reset to first page when new day is selected
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          eventLoader: (day) {
            return scheduleProvider.getPostsForDay(day);
          },
          calendarStyle: CalendarStyle(
            markersMaxCount: 3,
            markerDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildScheduledPosts() {
    return Expanded(
      child: Consumer<ScheduleProvider>(
        builder: (context, scheduleProvider, _) {
          if (scheduleProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Use the stored posts instead of recalculating
          if (_postsForSelectedDay.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.calendarDay,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary.withAlpha(128),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No posts scheduled for ${_formatDate(_selectedDay!)}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          // Use the paginated posts list instead of showing all posts
          return _buildPaginatedPostsList();
        },
      ),
    );
  }

  // Build the paginated posts list
  Widget _buildPaginatedPostsList() {
    // Calculate total pages
    final int totalPages = (_postsForSelectedDay.length / _postsPerPage).ceil();

    // Calculate the posts for the current page
    final int startIndex = _currentPage * _postsPerPage;
    final int endIndex = (startIndex + _postsPerPage > _postsForSelectedDay.length)
        ? _postsForSelectedDay.length
        : startIndex + _postsPerPage;

    final List<ScheduledPost> postsForCurrentPage =
    _postsForSelectedDay.sublist(startIndex, endIndex);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: postsForCurrentPage.length,
            itemBuilder: (context, index) {
              return _buildScheduledPostCard(postsForCurrentPage[index]);
            },
          ),
        ),

        // Only show pagination controls if we have more than one page
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Previous page button
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.angleLeft),
                  onPressed: _currentPage > 0
                      ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                      : null,
                ),

                // Page indicator
                Text('${_currentPage + 1} / $totalPages'),

                // Next page button
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.angleRight),
                  onPressed: _currentPage < totalPages - 1
                      ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildScheduledPostCard(ScheduledPost post) {
    return Consumer<ScheduleProvider>(
      builder: (context, scheduleProvider, _) {
        final contentItem = scheduleProvider.getContentForPost(post.contentItemId);
        final account = scheduleProvider.getAccountForPost(post.socialAccountId);

        if (contentItem == null || account == null) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        contentItem.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Status indicator - wrapped in Flexible to prevent overflow
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(post.status).withAlpha(51), // 0.2 opacity = ~51 alpha
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          post.status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(post.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showScheduleEditDialog(post);
                            break;
                          case 'delete':
                            _confirmDeleteScheduledPost(post);
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
                  contentItem.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // Display failure reason if post failed
                if (post.status == 'failed' && post.failureReason != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(26), // 0.1 opacity = ~26 alpha
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.circleExclamation, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Error: ${post.failureReason}',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Add Publish Now button for pending or failed posts
                if (post.status != 'published')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton.icon(
                      onPressed: scheduleProvider.isLoading
                          ? null
                          : () => _publishNow(post.id!),
                      icon: const FaIcon(FontAwesomeIcons.paperPlane, size: 16),
                      label: const Text('Publish Now'),
                    ),
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.user, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          account.username,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        _getPlatformIcon(account.platform, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _getPlatformDisplayName(account.platform),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.clock, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(post.scheduledTime),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Get color based on post status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'published':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Method to publish a post immediately
  Future<void> _publishNow(int postId) async {
    final provider = Provider.of<ScheduleProvider>(context, listen: false);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Publishing post...'),
              ],
            ),
          ),
        );
      },
    );

    // Try to publish
    final success = await provider.publishNow(postId);

    // Close loading dialog
    if (mounted) Navigator.of(context).pop();

    // Show result
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Post published successfully!'
                : 'Failed to publish post. Check details and try again.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }

    // Update posts list
    _updatePostsForSelectedDay();
  }

  Widget _buildScheduleButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            _showScheduleDialog();
          },
          icon: const FaIcon(FontAwesomeIcons.plus),
          label: const Text('Schedule New Post'),
        ),
      ),
    );
  }

  void _showScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => PostSchedulerDialog(
        initialDate: _selectedDay, // Pass the selected day
      ),
    ).then((_) {
      // Update posts after the dialog is closed
      _updatePostsForSelectedDay();
    });
  }

  void _showScheduleEditDialog(ScheduledPost post) {
    showDialog(
      context: context,
      builder: (context) => PostSchedulerDialog(scheduledPost: post),
    ).then((_) {
      // Update posts after the dialog is closed
      _updatePostsForSelectedDay();
    });
  }

  void _confirmDeleteScheduledPost(ScheduledPost post) {
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    final contentItem = scheduleProvider.getContentForPost(post.contentItemId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scheduled Post'),
        content: Text('Are you sure you want to delete the scheduled post${contentItem != null ? ' for "${contentItem.title}"' : ''}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              scheduleProvider.deleteScheduledPost(post.id!).then((_) {
                // Update posts after deletion
                _updatePostsForSelectedDay();
              });
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}