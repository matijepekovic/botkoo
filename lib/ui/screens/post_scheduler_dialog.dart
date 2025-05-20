// lib/ui/screens/post_scheduler_dialog.dart - Modified to remove account dropdown
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:botko/core/models/content_item.dart';
import 'package:botko/core/models/social_account.dart';
import 'package:botko/core/models/scheduled_post.dart';
import 'package:botko/core/providers/content_provider.dart';
import 'package:botko/core/providers/account_provider.dart';
import 'package:botko/core/providers/schedule_provider.dart';
import 'package:botko/ui/widgets/platform_selector.dart';

class PostSchedulerDialog extends StatefulWidget {
  final ScheduledPost? scheduledPost;
  final DateTime? initialDate;

  const PostSchedulerDialog({super.key, this.scheduledPost, this.initialDate});

  @override
  State<PostSchedulerDialog> createState() => _PostSchedulerDialogState();
}

class _PostSchedulerDialogState extends State<PostSchedulerDialog> {
  final _formKey = GlobalKey<FormState>();
  ContentItem? _selectedContent;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isEditing = false;

  // Platform selection fields
  List<String> _selectedPlatforms = [];
  String _contentType = 'text'; // Default to text

  // Content type detection based on content
  void _detectContentType() {
    if (_selectedContent != null) {
      if (_selectedContent!.mediaUrls.isNotEmpty) {
        // Check file extensions or content type if available
        final String mediaUrl = _selectedContent!.mediaUrls.first;
        if (mediaUrl.endsWith('.mp4') || mediaUrl.endsWith('.mov')) {
          // Check video duration if possible
          _contentType = _isShortVideo(mediaUrl) ? 'reel' : 'video';
        } else if (mediaUrl.endsWith('.jpg') || mediaUrl.endsWith('.png') || mediaUrl.endsWith('.jpeg')) {
          _contentType = 'image';
        }
      } else {
        _contentType = 'text';
      }
    }
  }
  bool _isShortVideo(String url) {
    // In a real implementation, you would check the video duration
    // For now, we'll return a placeholder
    return true; // Assume short video for TikTok and Reels
  }

  // Platform toggle handler
  void _togglePlatform(String platform) {
    setState(() {
      if (_selectedPlatforms.contains(platform)) {
        _selectedPlatforms.remove(platform);
      } else {
        _selectedPlatforms.add(platform);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _isEditing = widget.scheduledPost != null;

    if (_isEditing) {
      final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
      _selectedContent = scheduleProvider.getContentForPost(widget.scheduledPost!.contentItemId);

      // If editing, get the platform from the existing post
      final account = scheduleProvider.getAccountForPost(widget.scheduledPost!.socialAccountId);
      if (account != null) {
        _selectedPlatforms = [account.platform];
      }

      final scheduledTime = widget.scheduledPost!.scheduledTime;
      _selectedDate = DateTime(scheduledTime.year, scheduledTime.month, scheduledTime.day);
      _selectedTime = TimeOfDay(hour: scheduledTime.hour, minute: scheduledTime.minute);
    } else {
      // Use the initialDate if provided, otherwise use today's date
      _selectedDate = widget.initialDate ?? DateTime.now();
      _selectedTime = TimeOfDay.now();
    }

    // Detect content type based on selected content
    _detectContentType();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Scheduled Post' : 'Schedule New Post'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Content Dropdown
              _buildContentDropdown(),
              const SizedBox(height: 16),

              // Platform Selector (now the primary account selection method)
              Consumer<AccountProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Check if user has accounts for each platform
                  final availablePlatforms = {
                    'twitter': provider.accounts.any((a) => a.platform == 'twitter'),
                    'facebook': provider.accounts.any((a) => a.platform == 'facebook'),
                    'instagram': provider.accounts.any((a) => a.platform == 'instagram'),
                    'linkedin': provider.accounts.any((a) => a.platform == 'linkedin'),
                    'tiktok': provider.accounts.any((a) => a.platform == 'tiktok'),
                    'threads': provider.accounts.any((a) => a.platform == 'threads'),
                    'youtube': provider.accounts.any((a) => a.platform == 'youtube'),
                  };

                  // Only show platform selector if at least one platform has accounts
                  if (!availablePlatforms.values.any((has) => has)) {
                    return const Text(
                      'No accounts connected. Connect an account first.',
                      style: TextStyle(color: Colors.red),
                    );
                  }

                  return PlatformSelector(
                    selectedPlatforms: _selectedPlatforms,
                    onToggle: _togglePlatform,
                    contentType: _contentType,
                    availablePlatforms: availablePlatforms,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Date Picker
              _buildDatePicker(),
              const SizedBox(height: 16),

              // Time Picker
              _buildTimePicker(),
              const SizedBox(height: 16),

              // Error message
              Consumer<ScheduleProvider>(
                builder: (context, provider, _) {
                  if (provider.error != null) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.red.withAlpha(50),
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
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        Consumer<ScheduleProvider>(
          builder: (context, provider, _) {
            return FilledButton(
              onPressed: provider.isLoading ? null : _schedulePost,
              child: provider.isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(_isEditing ? 'Update' : 'Schedule'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContentDropdown() {
    return Consumer<ContentProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Get available content items (drafts and published)
        final availableContent = provider.contentItems
            .where((item) => item.status == 'draft' || item.status == 'published')
            .toList();

        if (availableContent.isEmpty) {
          return const Text(
            'No content available. Create content first.',
            style: TextStyle(color: Colors.red),
          );
        }

        // Find selected content by ID if exists
        if (_isEditing && _selectedContent != null && _selectedContent!.id != null) {
          final contentId = _selectedContent!.id;
          // Try to find the matching content in the provider's list
          final matchingContent = availableContent
              .firstWhere((c) => c.id == contentId, orElse: () => _selectedContent!);

          // If found a different instance but same ID, use that one
          if (matchingContent != _selectedContent && matchingContent.id == contentId) {
            _selectedContent = matchingContent;
          }
        }

        return DropdownButtonFormField<ContentItem>(
          decoration: const InputDecoration(
            labelText: 'Content',
            border: OutlineInputBorder(),
          ),
          value: _selectedContent,
          items: availableContent.map((content) {
            return DropdownMenuItem<ContentItem>(
              value: content,
              child: Text(
                content.title,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedContent = value;
              // Update content type when content changes
              _detectContentType();
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Please select content to schedule';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _pickDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            ),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: _pickTime,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Time',
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
            ),
            const Icon(Icons.access_time),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  // Fix for unused import with explicit type declaration

  void _schedulePost() async {
    if (_formKey.currentState!.validate()) {
      // Validate content selection
      if (_selectedContent == null || _selectedContent!.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select valid content to schedule')),
        );
        return;
      }

      // Validate platform selection
      if (_selectedPlatforms.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one platform to post to')),
        );
        return;
      }

      final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
      final accountProvider = Provider.of<AccountProvider>(context, listen: false);

      // Create DateTime from selected date and time
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Check if date is in the past
      if (scheduledDateTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot schedule post in the past')),
        );
        return;
      }

      try {
        if (_isEditing && widget.scheduledPost != null) {
          // For editing, get the account for the selected platform
          final List<SocialAccount> accountsForPlatform = accountProvider.accounts
              .where((a) => _selectedPlatforms.contains(a.platform))
              .toList();

          if (accountsForPlatform.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No account available for selected platform')),
            );
            return;
          }

          // Use the first account for this platform
          final SocialAccount account = accountsForPlatform.first;

          // Update the post with the selected account
          final updatedPost = ScheduledPost(
            id: widget.scheduledPost!.id,
            contentItemId: _selectedContent!.id!,
            socialAccountId: account.id!,
            scheduledTime: scheduledDateTime,
            status: widget.scheduledPost!.status,
          );

          await scheduleProvider.updateScheduledPost(updatedPost);

          if (mounted && scheduleProvider.error == null) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Post schedule updated successfully')),
            );
          }
        } else {
          // For new posts, create a post for each selected platform
          int successCount = 0;

          for (final platform in _selectedPlatforms) {
            // Find an account for this platform
            final List<SocialAccount> accountsForPlatform = accountProvider.accounts
                .where((a) => a.platform == platform)
                .toList();

            if (accountsForPlatform.isNotEmpty) {
              // Use the first account for this platform
              final SocialAccount account = accountsForPlatform.first;

              await scheduleProvider.schedulePost(
                contentItemId: _selectedContent!.id!,
                socialAccountId: account.id!,
                scheduledTime: scheduledDateTime,
              );

              successCount++;
            }
          }

          if (mounted && scheduleProvider.error == null) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Post scheduled to $successCount platform${successCount == 1 ? '' : 's'} successfully'
                ),
              ),
            );
          }
        }
      } catch (e) {
        // Show error message if scheduling fails
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error scheduling post: ${e.toString()}')),
          );
        }
      }
    }
  }
}