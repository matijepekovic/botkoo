import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:botko/core/models/scheduled_post.dart';
import 'package:botko/core/providers/schedule_provider.dart';
import 'package:botko/ui/screens/post_scheduler_dialog.dart';

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
    // Remove the listener when the widget is disposed
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    scheduleProvider.removeListener(_scheduleProviderListener);
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
                    Icon(
                      Icons.calendar_today,
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
                  icon: const Icon(Icons.arrow_back),
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
                  icon: const Icon(Icons.arrow_forward),
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
                  contentItem.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_circle, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          account.username,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.public, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          account.platform,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16),
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

  Widget _buildScheduleButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            _showScheduleDialog();
          },
          icon: const Icon(Icons.add),
          label: const Text('Schedule New Post'),
        ),
      ),
    );
  }

  void _showScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => const PostSchedulerDialog(),
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