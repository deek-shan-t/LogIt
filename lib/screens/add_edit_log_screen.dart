import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/log_entry.dart';
import '../models/tag.dart';
import '../providers/log_provider.dart';
import '../providers/tag_provider.dart';
import '../widgets/tag_chip.dart';

class AddEditLogScreen extends StatefulWidget {
  final LogEntry? logEntry; // null for add mode, existing entry for edit mode
  final bool isDialog; // true for dialog mode, false for full screen

  const AddEditLogScreen({
    super.key,
    this.logEntry,
    this.isDialog = false,
  });

  @override
  State<AddEditLogScreen> createState() => _AddEditLogScreenState();
}

class _AddEditLogScreenState extends State<AddEditLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  bool _hasReminder = false;
  DateTime? _reminderDate;
  TimeOfDay? _reminderTime;
  
  final Set<String> _selectedTagIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.logEntry != null) {
      // Edit mode - populate fields
      final log = widget.logEntry!;
      _titleController.text = log.title;
      _descriptionController.text = log.description;
      _selectedDate = DateTime(log.dateTime.year, log.dateTime.month, log.dateTime.day);
      _selectedTime = TimeOfDay(hour: log.dateTime.hour, minute: log.dateTime.minute);
      _selectedTagIds.addAll(log.tags);
      
      if (log.reminder != null) {
        _hasReminder = true;
        _reminderDate = DateTime(log.reminder!.year, log.reminder!.month, log.reminder!.day);
        _reminderTime = TimeOfDay(hour: log.reminder!.hour, minute: log.reminder!.minute);
      }
    } else {
      // Add mode - set defaults
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.logEntry != null;
    
    if (widget.isDialog) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
          child: _buildContent(context, theme, isEditing),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Log' : 'Add New Log'),
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(context),
            ),
        ],
      ),
      body: _buildContent(context, theme, isEditing),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, bool isEditing) {
    return Consumer2<LogProvider, TagProvider>(
      builder: (context, logProvider, tagProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isDialog) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Log' : 'Add New Log',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Title field
                _buildTitleField(theme),
                const SizedBox(height: 16),
                
                // Description field
                _buildDescriptionField(theme),
                const SizedBox(height: 16),
                
                // Date and time selection
                _buildDateTimeSection(theme),
                const SizedBox(height: 16),
                
                // Tags section
                _buildTagsSection(theme, tagProvider),
                const SizedBox(height: 16),
                
                // Reminder section
                _buildReminderSection(theme),
                const SizedBox(height: 24),
                
                // Action buttons
                _buildActionButtons(context, theme, isEditing, logProvider, tagProvider),
                
                if (widget.isDialog)
                  const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitleField(ThemeData theme) {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Title *',
        hintText: 'Enter log title',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.title),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Title is required';
        }
        if (value.trim().length < 3) {
          return 'Title must be at least 3 characters';
        }
        return null;
      },
      textCapitalization: TextCapitalization.sentences,
      maxLength: 100,
    );
  }

  Widget _buildDescriptionField(ThemeData theme) {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: 'Enter detailed description (optional)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.description),
        alignLabelWithHint: true,
      ),
      maxLines: 3,
      maxLength: 500,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildDateTimeSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date & Time',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(_formatDate(_selectedDate)),
                    subtitle: const Text('Date'),
                    onTap: () => _selectDate(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text(_selectedTime.format(context)),
                    subtitle: const Text('Time'),
                    onTap: () => _selectTime(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection(ThemeData theme, TagProvider tagProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tags',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: () => _showCreateTagDialog(context, tagProvider),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Tag'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (tagProvider.tags.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No tags available. Create your first tag!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tagProvider.tags.map((tag) {
                  final isSelected = _selectedTagIds.contains(tag.id);
                  return TagChip(
                    tag: tag,
                    isSelected: isSelected,
                    onTap: () => _toggleTag(tag.id),
                    size: TagChipSize.medium,
                  );
                }).toList(),
              ),
            if (_selectedTagIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${_selectedTagIds.length} tag${_selectedTagIds.length == 1 ? '' : 's'} selected',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reminder',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Switch(
                  value: _hasReminder,
                  onChanged: (value) {
                    setState(() {
                      _hasReminder = value;
                      if (value && _reminderDate == null) {
                        _reminderDate = _selectedDate;
                        _reminderTime = _selectedTime;
                      }
                    });
                  },
                ),
              ],
            ),
            if (_hasReminder) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      leading: const Icon(Icons.notification_important),
                      title: Text(_reminderDate != null ? _formatDate(_reminderDate!) : 'Select Date'),
                      subtitle: const Text('Reminder Date'),
                      onTap: () => _selectReminderDate(context),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      leading: const Icon(Icons.schedule),
                      title: Text(_reminderTime?.format(context) ?? 'Select Time'),
                      subtitle: const Text('Reminder Time'),
                      onTap: () => _selectReminderTime(context),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You\'ll receive a notification at the selected time',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme, bool isEditing, 
                           LogProvider logProvider, TagProvider tagProvider) {
    return Row(
      children: [
        if (!widget.isDialog)
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        if (!widget.isDialog) const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _saveLog(context, logProvider),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEditing ? 'Update Log' : 'Create Log'),
          ),
        ),
      ],
    );
  }

  void _toggleTag(String tagId) {
    setState(() {
      if (_selectedTagIds.contains(tagId)) {
        _selectedTagIds.remove(tagId);
      } else {
        _selectedTagIds.add(tagId);
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectReminderDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _reminderDate = picked;
      });
    }
  }

  Future<void> _selectReminderTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  Future<void> _saveLog(BuildContext context, LogProvider logProvider) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      
      DateTime? reminder;
      if (_hasReminder && _reminderDate != null && _reminderTime != null) {
        reminder = DateTime(
          _reminderDate!.year,
          _reminderDate!.month,
          _reminderDate!.day,
          _reminderTime!.hour,
          _reminderTime!.minute,
        );
        
        // Validate reminder is in the future
        if (reminder.isBefore(DateTime.now())) {
          _showErrorSnackBar(context, 'Reminder must be set for a future time');
          return;
        }
      }
      
      bool success;
      if (widget.logEntry != null) {
        // Update existing log
        final updatedLog = widget.logEntry!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dateTime: dateTime,
          tags: _selectedTagIds.toList(),
          reminder: reminder,
        );
        success = await logProvider.updateLog(updatedLog);
      } else {
        // Create new log
        success = await logProvider.createLog(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          tags: _selectedTagIds.toList(),
          reminder: reminder,
          customDate: dateTime,
        );
      }
      
      if (success) {
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
          _showSuccessSnackBar(
            context, 
            widget.logEntry != null ? 'Log updated successfully!' : 'Log created successfully!'
          );
        }
      } else {
        _showErrorSnackBar(context, logProvider.error ?? 'Failed to save log');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showCreateTagDialog(BuildContext context, TagProvider tagProvider) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const CreateTagDialog(),
    );
    
    if (result == true) {
      // Tag was created, refresh UI
      setState(() {});
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Log'),
        content: Text('Are you sure you want to delete "${widget.logEntry!.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      final logProvider = context.read<LogProvider>();
      final success = await logProvider.deleteLog(widget.logEntry!.id);
      
      if (success && mounted) {
        Navigator.pop(context, true);
        _showSuccessSnackBar(context, 'Log deleted successfully');
      }
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDay = DateTime(date.year, date.month, date.day);
    
    if (selectedDay == today) {
      return 'Today';
    } else if (selectedDay == yesterday) {
      return 'Yesterday';
    } else if (selectedDay == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Create Tag Dialog
class CreateTagDialog extends StatefulWidget {
  const CreateTagDialog({super.key});

  @override
  State<CreateTagDialog> createState() => _CreateTagDialogState();
}

class _CreateTagDialogState extends State<CreateTagDialog> {
  final _tagNameController = TextEditingController();
  String _selectedColor = '#2196F3';
  bool _isLoading = false;

  final List<String> _predefinedColors = [
    '#2196F3', '#4CAF50', '#FF9800', '#F44336', '#9C27B0',
    '#00BCD4', '#8BC34A', '#FFC107', '#E91E63', '#3F51B5',
    '#009688', '#CDDC39', '#FF5722', '#795548', '#607D8B',
  ];

  @override
  void dispose() {
    _tagNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('Create New Tag'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _tagNameController,
            decoration: const InputDecoration(
              labelText: 'Tag Name',
              hintText: 'Enter tag name',
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Text('Color', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _predefinedColors.map((color) {
              final isSelected = color == _selectedColor;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(int.parse('0xFF${color.substring(1)}')),
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected 
                        ? Border.all(color: Colors.black, width: 3)
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createTag,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createTag() async {
    final name = _tagNameController.text.trim();
    if (name.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final tagProvider = context.read<TagProvider>();
      final success = await tagProvider.createTag(
        name: name,
        colorHex: _selectedColor,
      );
      
      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
