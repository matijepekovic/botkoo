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
  SocialAccount? _selectedAccount;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isEditing = false;

  // Add these fields for platform selection
  List<String> _selectedPlatforms = [];
  String _contentType = 'text'; // Default to text

  // Content type detection based on content
  void _detectContentType() {
    if (_selectedContent != null) {
      // For now, simple detection
      if (_selectedContent!.mediaUrls.isNotEmpty) {
        // Check if media is video or image (you'll need to enhance this)
        _contentType = 'image'; // or 'video' or 'reel'
      } else {
        _contentType = 'text';
      }
    }
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
      _selectedAccount = scheduleProvider.getAccountForPost(widget.scheduledPost!.socialAccountId);

      final scheduledTime = widget.scheduledPost!.scheduledTime;
      _selectedDate = DateTime(scheduledTime.year, scheduledTime.month, scheduledTime.day);
      _selectedTime = TimeOfDay(hour: scheduledTime.hour, minute: scheduledTime.minute);

      // If editing, add the platform from existing post
      if (_selectedAccount != null) {
        _selectedPlatforms = [_selectedAccount!.platform];
      }
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

              // Platform Selector (new)
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
                  availablePlatforms: availablePlatforms, // Pass the available platforms
                );
              },
            ),
              const SizedBox(height: 16),

              // Account Dropdown
              _buildAccountDropdown(),
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

  Widget _buildAccountDropdown() {
    return Consumer<AccountProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.accounts.isEmpty) {
          return const Text(
            'No accounts connected. Connect an account first.',
            style: TextStyle(color: Colors.red),
          );
        }

        // Filter accounts based on selected platforms
        List<SocialAccount> availableAccounts = provider.accounts;
        if (_selectedPlatforms.isNotEmpty) {
          availableAccounts = provider.accounts
              .where((account) => _selectedPlatforms.contains(account.platform))
              .toList();
        }

        if (availableAccounts.isEmpty) {
          return const Text(
            'No accounts available for selected platforms. Please select different platforms or connect relevant accounts.',
            style: TextStyle(color: Colors.red),
          );
        }

        // Find selected account by ID if exists
        if (_isEditing && _selectedAccount != null && _selectedAccount!.id != null) {
          final accountId = _selectedAccount!.id;
          // Try to find the matching account in the provider's list
          final matchingAccount = availableAccounts
              .firstWhere((a) => a.id == accountId, orElse: () => _selectedAccount!);

          // If found a different instance but same ID, use that one
          if (matchingAccount != _selectedAccount && matchingAccount.id == accountId) {
            _selectedAccount = matchingAccount;
          }
        } else if (_selectedPlatforms.isNotEmpty && availableAccounts.isNotEmpty) {
          // Auto-select the first account for the first selected platform
          _selectedAccount = availableAccounts.first;
        }

        return DropdownButtonFormField<SocialAccount>(
          decoration: const InputDecoration(
            labelText: 'Account',
            border: OutlineInputBorder(),
          ),
          value: _selectedAccount,
          items: availableAccounts.map((account) {
            return DropdownMenuItem<SocialAccount>(
              value: account,
              child: Text('${account.platform} - ${account.username}'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedAccount = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Please select an account';
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

      // Validate account selection
      if (_selectedAccount == null || _selectedAccount!.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a valid account')),
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
          // For editing, update the single post with the selected account
          final updatedPost = ScheduledPost(
            id: widget.scheduledPost!.id,
            contentItemId: _selectedContent!.id!,
            socialAccountId: _selectedAccount!.id!,
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
            final accountsForPlatform = accountProvider.accounts
                .where((a) => a.platform == platform)
                .toList();

            if (accountsForPlatform.isNotEmpty) {
              // Use the first account for this platform
              final account = accountsForPlatform.first;

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