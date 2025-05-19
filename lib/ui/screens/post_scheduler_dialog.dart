import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:botko/core/models/content_item.dart';
import 'package:botko/core/models/social_account.dart';
import 'package:botko/core/models/scheduled_post.dart';
import 'package:botko/core/providers/content_provider.dart';
import 'package:botko/core/providers/account_provider.dart';
import 'package:botko/core/providers/schedule_provider.dart';

class PostSchedulerDialog extends StatefulWidget {
  final ScheduledPost? scheduledPost;

  const PostSchedulerDialog({super.key, this.scheduledPost});

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
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
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

        return DropdownButtonFormField<SocialAccount>(
          decoration: const InputDecoration(
            labelText: 'Account',
            border: OutlineInputBorder(),
          ),
          value: _selectedAccount,
          items: provider.accounts.map((account) {
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
      // Add explicit null checks for both selectedContent and selectedAccount
      if (_selectedContent == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select content to schedule')),
        );
        return;
      }

      if (_selectedAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an account')),
        );
        return;
      }

      // Check for null IDs specifically
      if (_selectedContent!.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected content has no ID. Try saving it again.')),
        );
        return;
      }

      if (_selectedAccount!.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected account has no ID. Try connecting it again.')),
        );
        return;
      }

      final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);

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
          final updatedPost = ScheduledPost(
            id: widget.scheduledPost!.id,
            contentItemId: _selectedContent!.id!,
            socialAccountId: _selectedAccount!.id!,
            scheduledTime: scheduledDateTime,
            status: widget.scheduledPost!.status,
          );

          await scheduleProvider.updateScheduledPost(updatedPost);
        } else {
          await scheduleProvider.schedulePost(
            contentItemId: _selectedContent!.id!,
            socialAccountId: _selectedAccount!.id!,
            scheduledTime: scheduledDateTime,
          );
        }

        if (mounted && scheduleProvider.error == null) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Post schedule updated successfully'
                    : 'Post scheduled successfully',
              ),
            ),
          );
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