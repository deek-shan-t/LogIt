import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/log_provider.dart';
import '../providers/tag_provider.dart';
import '../widgets/log_entry_card.dart';
import '../widgets/tag_chip.dart';
import '../models/log_entry.dart';
import 'calendar_screen.dart';
import 'add_edit_log_screen.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Logs'),
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _openCalendar(context),
            tooltip: 'Calendar View',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
        ],
      ),
      body: Consumer2<LogProvider, TagProvider>(
        builder: (context, logProvider, tagProvider, child) {
          return Column(
            children: [
              // Filters section
              _buildFiltersSection(context, logProvider, tagProvider),
              
              // Logs list
              Expanded(
                child: _buildLogsList(context, logProvider, tagProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFiltersSection(BuildContext context, LogProvider logProvider, TagProvider tagProvider) {
    final theme = Theme.of(context);
    final hasActiveFilters = logProvider.selectedTags.isNotEmpty || 
                            logProvider.activeFilter != LogFilter.all ||
                            logProvider.searchQuery.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search logs...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        logProvider.clearSearch();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) => logProvider.setSearchQuery(value),
          ),
          
          const SizedBox(height: 12),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Date filter
                _buildFilterChip(
                  context,
                  label: _getDateFilterLabel(logProvider),
                  isSelected: logProvider.selectedDate != null,
                  onTap: () => _showDatePicker(context, logProvider),
                  icon: Icons.calendar_today,
                ),
                
                const SizedBox(width: 8),
                
                // Log filter
                _buildFilterChip(
                  context,
                  label: _getLogFilterLabel(logProvider.activeFilter),
                  isSelected: logProvider.activeFilter != LogFilter.all,
                  onTap: () => _showLogFilterOptions(context, logProvider),
                  icon: Icons.filter_list,
                ),
                
                const SizedBox(width: 8),
                
                // Tag filters
                ...tagProvider.tags.map((tag) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TagChip(
                    tag: tag,
                    isSelected: logProvider.selectedTags.contains(tag.id),
                    onTap: () {
                      if (logProvider.selectedTags.contains(tag.id)) {
                        logProvider.removeSelectedTag(tag.id);
                      } else {
                        logProvider.addSelectedTag(tag.id);
                      }
                    },
                    size: TagChipSize.small,
                  ),
                )),
                
                // Clear filters
                if (hasActiveFilters)
                  _buildFilterChip(
                    context,
                    label: 'Clear All',
                    isSelected: false,
                    onTap: () => _clearAllFilters(logProvider),
                    icon: Icons.clear,
                    isDestructive: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(BuildContext context, LogProvider logProvider, TagProvider tagProvider) {
    final logs = logProvider.filteredLogs;
    
    if (logProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (logs.isEmpty) {
      return _buildEmptyState(context, logProvider);
    }
    
    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return LogEntryCard(
          logEntry: log,
          availableTags: tagProvider.tags,
          onTap: () => _showLogDetails(context, log),
          onEdit: () => _editLog(context, log),
          onDelete: () => _deleteLog(context, log),
        );
      },
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.primary;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, LogProvider logProvider) {
    final theme = Theme.of(context);
    final hasFilters = logProvider.selectedTags.isNotEmpty || 
                     logProvider.activeFilter != LogFilter.all ||
                     logProvider.searchQuery.isNotEmpty;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.search_off : Icons.article_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No logs match your filters' : 'No logs yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters 
                  ? 'Try adjusting your search or filters'
                  : 'Create your first log entry to get started!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _clearAllFilters(logProvider),
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDateFilterLabel(LogProvider logProvider) {
    if (logProvider.selectedDate == null) return 'All Dates';
    
    final selected = logProvider.selectedDate!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(selected.year, selected.month, selected.day);
    
    if (selectedDate == today) return 'Today';
    if (selectedDate == today.subtract(const Duration(days: 1))) return 'Yesterday';
    
    return '${selected.day}/${selected.month}/${selected.year}';
  }

  String _getLogFilterLabel(LogFilter filter) {
    switch (filter) {
      case LogFilter.all:
        return 'All Logs';
      case LogFilter.withReminders:
        return 'With Reminders';
      case LogFilter.withoutReminders:
        return 'No Reminders';
      case LogFilter.today:
        return 'Today';
      case LogFilter.thisWeek:
        return 'This Week';
      case LogFilter.thisMonth:
        return 'This Month';
    }
  }

  void _openCalendar(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CalendarScreen(),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    // Focus the search field
    FocusScope.of(context).requestFocus();
  }

  void _showDatePicker(BuildContext context, LogProvider logProvider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: logProvider.selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      logProvider.selectDate(picked);
    }
  }

  void _showLogFilterOptions(BuildContext context, LogProvider logProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Logs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...LogFilter.values.map((filter) => ListTile(
              title: Text(_getLogFilterLabel(filter)),
              leading: Radio<LogFilter>(
                value: filter,
                groupValue: logProvider.activeFilter,
                onChanged: (value) {
                  if (value != null) {
                    logProvider.setActiveFilter(value);
                    Navigator.pop(context);
                  }
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _clearAllFilters(LogProvider logProvider) {
    _searchController.clear();
    logProvider.clearSearch();
    logProvider.clearSelectedTags();
    logProvider.setActiveFilter(LogFilter.all);
    logProvider.clearSelectedDate();
  }

  void _showLogDetails(BuildContext context, LogEntry log) {
    // TODO: Navigate to log detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View details for: ${log.title}')),
    );
  }

  void _editLog(BuildContext context, LogEntry log) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditLogScreen(logEntry: log),
      ),
    ).then((result) {
      if (result == true) {
        // Log was updated, refresh the UI
        setState(() {});
      }
    });
  }

  void _deleteLog(BuildContext context, LogEntry log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Log'),
        content: Text('Are you sure you want to delete "${log.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<LogProvider>().deleteLog(log.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Log deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
