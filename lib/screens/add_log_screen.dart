import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/log_provider.dart';
import '../providers/tag_provider.dart';
import '../widgets/tag_chip.dart';
import '../theme/app_theme.dart';

class AddLogScreen extends StatefulWidget {
  final bool isDialog; // true for dialog mode, false for full screen

  const AddLogScreen({
    super.key,
    this.isDialog = false,
  });

  @override
  State<AddLogScreen> createState() => _AddLogScreenState();
}

class _AddLogScreenState extends State<AddLogScreen> {
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
    // Set defaults for add mode
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDialog) {
      return Dialog(
        backgroundColor: AppTheme.backgroundSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
          child: _buildContent(context),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add New Log',
          style: AppTheme.titleText,
        ),
        backgroundColor: AppTheme.backgroundSecondary,
      ),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Consumer2<LogProvider, TagProvider>(
      builder: (context, logProvider, tagProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
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
                        'Add New Log',
                        style: AppTheme.titleText.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppTheme.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                ],
                
                _buildTitleField(),
                const SizedBox(height: AppTheme.spacingLg),
                
                _buildDescriptionField(),
                const SizedBox(height: AppTheme.spacingLg),
                
                _buildDateTimeSection(),
                const SizedBox(height: AppTheme.spacingLg),
                
                _buildTagsSection(tagProvider),
                const SizedBox(height: AppTheme.spacingLg),
                
                _buildReminderSection(),
                const SizedBox(height: AppTheme.spacingXxl),
                
                _buildActionButtons(context, logProvider, tagProvider),
                
                if (widget.isDialog)
                  const SizedBox(height: AppTheme.spacingLg),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      style: AppTheme.bodyText,
      decoration: InputDecoration(
        labelText: 'Title *',
        labelStyle: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
        hintText: 'Enter log title',
        hintStyle: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.backgroundTertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(Icons.title, color: AppTheme.textSecondary),
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

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      style: AppTheme.bodyText,
      decoration: InputDecoration(
        labelText: 'Description',
        labelStyle: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
        hintText: 'Enter detailed description (optional)',
        hintStyle: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.backgroundTertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(Icons.description, color: AppTheme.textSecondary),
        alignLabelWithHint: true,
      ),
      maxLines: 3,
      maxLength: 500,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildDateTimeSection() {
    return Card(
      color: AppTheme.backgroundSecondary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(color: AppTheme.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date & Time', style: AppTheme.titleText),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: Icon(Icons.calendar_today, color: AppTheme.accentPrimary),
                    title: Text(_formatDate(_selectedDate), style: AppTheme.bodyText),
                    subtitle: Text('Date', style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary)),
                    onTap: () => _selectDate(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    leading: Icon(Icons.access_time, color: AppTheme.accentPrimary),
                    title: Text(_selectedTime.format(context), style: AppTheme.bodyText),
                    subtitle: Text('Time', style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary)),
                    onTap: () => _selectTime(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection(TagProvider tagProvider) {
    return Card(
      color: AppTheme.backgroundSecondary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(color: AppTheme.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tags', style: AppTheme.titleText),
                TextButton.icon(
                  onPressed: () => _showCreateTagDialog(context, tagProvider),
                  icon: Icon(Icons.add, size: 16, color: AppTheme.accentPrimary),
                  label: Text('New Tag', style: AppTheme.bodyText.copyWith(color: AppTheme.accentPrimary)),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            if (tagProvider.tags.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                child: Text(
                  'No tags available. Create your first tag!',
                  style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
                ),
              )
            else
              Wrap(
                spacing: AppTheme.spacingSm,
                runSpacing: AppTheme.spacingSm,
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
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                '${_selectedTagIds.length} tag${_selectedTagIds.length == 1 ? '' : 's'} selected',
                style: AppTheme.bodyText.copyWith(color: AppTheme.accentPrimary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSection() {
    return Card(
      color: AppTheme.backgroundSecondary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(color: AppTheme.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Reminder', style: AppTheme.titleText),
                Switch(
                  value: _hasReminder,
                  activeColor: AppTheme.accentPrimary,
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
              const SizedBox(height: AppTheme.spacingMd),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      leading: Icon(Icons.notification_important, color: AppTheme.accentPrimary),
                      title: Text(
                        _reminderDate != null ? _formatDate(_reminderDate!) : 'Select Date',
                        style: AppTheme.bodyText,
                      ),
                      subtitle: Text('Reminder Date', style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary)),
                      onTap: () => _selectReminderDate(context),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      leading: Icon(Icons.schedule, color: AppTheme.accentPrimary),
                      title: Text(
                        _reminderTime?.format(context) ?? 'Select Time',
                        style: AppTheme.bodyText,
                      ),
                      subtitle: Text('Reminder Time', style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary)),
                      onTap: () => _selectReminderTime(context),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: AppTheme.accentPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppTheme.accentPrimary),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Text(
                        'You\'ll receive a notification at the selected time',
                        style: AppTheme.bodyText.copyWith(color: AppTheme.accentPrimary),
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

  Widget _buildActionButtons(BuildContext context, LogProvider logProvider, TagProvider tagProvider) {
    return Row(
      children: [
        if (!widget.isDialog)
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: BorderSide(color: AppTheme.border),
              ),
              child: const Text('Cancel'),
            ),
          ),
        if (!widget.isDialog) const SizedBox(width: AppTheme.spacingLg),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _saveLog(context, logProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPrimary,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Create Log'),
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
        
        if (reminder.isBefore(DateTime.now())) {
          _showErrorSnackBar(context, 'Reminder must be set for a future time');
          return;
        }
      }
      
      final success = await logProvider.createLog(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: _selectedTagIds.toList(),
        reminder: reminder,
        customDate: dateTime,
      );
      
      if (success) {
        if (mounted) {
          Navigator.pop(context, true);
          _showSuccessSnackBar(context, 'Log created successfully!');
        }
      } else {
        _showErrorSnackBar(context, logProvider.error ?? 'Failed to create log');
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
      setState(() {});
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTheme.bodyText),
        backgroundColor: AppTheme.accentSuccess,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTheme.bodyText),
        backgroundColor: AppTheme.accentError,
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
    return AlertDialog(
      backgroundColor: AppTheme.backgroundSecondary,
      title: Text('Create New Tag', style: AppTheme.titleText),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _tagNameController,
            style: AppTheme.bodyText,
            decoration: InputDecoration(
              labelText: 'Tag Name',
              labelStyle: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
              hintText: 'Enter tag name',
              hintStyle: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.backgroundTertiary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text('Color', style: AppTheme.titleText),
          const SizedBox(height: AppTheme.spacingSm),
          Wrap(
            spacing: AppTheme.spacingSm,
            runSpacing: AppTheme.spacingSm,
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
                        ? Border.all(color: AppTheme.textPrimary, width: 3)
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
          style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createTag,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentPrimary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
