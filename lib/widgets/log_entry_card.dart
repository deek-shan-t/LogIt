import 'package:flutter/material.dart';
import '../models/log_entry.dart';
import '../models/tag.dart';
import '../theme/app_theme.dart';
import 'tag_chip.dart';

class LogEntryCard extends StatelessWidget {
  final LogEntry logEntry;
  final List<Tag> availableTags;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isSelected;

  const LogEntryCard({
    super.key,
    required this.logEntry,
    required this.availableTags,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasReminder = logEntry.reminder != null;
    final isReminderPast = hasReminder && 
        logEntry.reminder!.isBefore(DateTime.now());
    
    // Get tags for this log entry
    final logTags = availableTags
        .where((tag) => logEntry.tags.contains(tag.id))
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg, 
        vertical: AppTheme.spacingSm,
      ),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: isSelected 
            ? const BorderSide(color: AppTheme.accentPrimary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and actions
              Row(
                children: [
                  Expanded(
                    child: Text(
                      logEntry.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasReminder) ...[
                    const SizedBox(width: 8),
                    Icon(
                      isReminderPast 
                          ? Icons.notification_important
                          : Icons.schedule,
                      size: 20,
                      color: isReminderPast 
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                  ],
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Description
              if (logEntry.description.isNotEmpty) ...[
                Text(
                  logEntry.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              
              // Tags
              if (logTags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: logTags.map((tag) => TagChip(
                    tag: tag,
                    size: TagChipSize.small,
                  )).toList(),
                ),
                const SizedBox(height: 12),
              ],
              
              // Footer with date and reminder info
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(logEntry.dateTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (hasReminder) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.alarm,
                      size: 16,
                      color: isReminderPast 
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatReminderTime(logEntry.reminder!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isReminderPast 
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final logDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (logDate == today) {
      return 'Today ${_formatTime(dateTime)}';
    } else if (logDate == yesterday) {
      return 'Yesterday ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatReminderTime(DateTime reminder) {
    final now = DateTime.now();
    final difference = reminder.difference(now);

    if (difference.isNegative) {
      final pastDuration = now.difference(reminder);
      if (pastDuration.inMinutes < 60) {
        return '${pastDuration.inMinutes}m ago';
      } else if (pastDuration.inHours < 24) {
        return '${pastDuration.inHours}h ago';
      } else {
        return '${pastDuration.inDays}d ago';
      }
    } else {
      if (difference.inMinutes < 60) {
        return 'in ${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return 'in ${difference.inHours}h';
      } else {
        return 'in ${difference.inDays}d';
      }
    }
  }
}
