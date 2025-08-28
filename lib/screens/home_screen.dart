import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/log_provider.dart';
import '../providers/tag_provider.dart';
import '../widgets/log_entry_card.dart';
import '../models/log_entry.dart';
import 'add_log_screen.dart';
import 'edit_log_screen.dart';
import '../utils/developer_utils.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure we're showing today's data and both providers are initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LogProvider>().selectToday();
      // Ensure TagProvider is also refreshed on home screen load
      context.read<TagProvider>().loadTags();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logit'),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.science),
          //   onPressed: () => DeveloperUtils.createSampleData(context),
          //   tooltip: 'Create Sample Data',
          // ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<LogProvider>().initialize();
              context.read<TagProvider>().initialize();
            },
          ),
        ],
      ),
      body: Consumer2<LogProvider, TagProvider>(
        builder: (context, logProvider, tagProvider, child) {
          // Show loading indicator if TagProvider is still loading
          if (tagProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          final todayLogs = logProvider.getLogsForDate(DateTime.now());
          final upcomingReminders = logProvider.getLogsWithActiveReminders();
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                _buildWelcomeCard(context, logProvider, tagProvider),
                
                const SizedBox(height: 24),
                
                // Today's logs section
                _buildTodaySection(context, todayLogs, tagProvider),
                
                const SizedBox(height: 24),
                
                // Upcoming reminders section
                if (upcomingReminders.isNotEmpty) ...[
                  _buildRemindersSection(context, upcomingReminders, tagProvider),
                  const SizedBox(height: 24),
                ],
                
                // Quick stats section
                _buildStatsSection(context, logProvider, tagProvider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLogDialog(context),
        tooltip: 'Add New Log',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, LogProvider logProvider, TagProvider tagProvider) {
    final username = 'User'; // We can get this from PreferencesService later
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting, $username!',
              style: AppTheme.headerText.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              _formatDate(now),
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.secondaryTextColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickStat(
                  context,
                  'Today\'s Logs',
                  logProvider.getLogsForDate(now).length.toString(),
                  Icons.today,
                  AppTheme.accentPrimary,
                ),
                _buildQuickStat(
                  context,
                  'Total Logs',
                  logProvider.totalLogsCount.toString(),
                  Icons.article,
                  AppTheme.accentSecondary,
                ),
                _buildQuickStat(
                  context,
                  'Tags',
                  tagProvider.totalTagsCount.toString(),
                  Icons.label,
                  AppTheme.accentSuccess,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySection(BuildContext context, List<LogEntry> todayLogs, TagProvider tagProvider) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Logs',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (todayLogs.isNotEmpty)
              TextButton(
                onPressed: () {
                  // Navigate to logs screen with today filter
                  DefaultTabController.of(context)?.animateTo(1);
                },
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (todayLogs.isEmpty)
          _buildEmptyState(
            context,
            'No logs for today',
            'Start by creating your first log entry!',
            Icons.today,
          )
        else
          ...todayLogs.take(3).map((log) => LogEntryCard(
            logEntry: log,
            availableTags: tagProvider.tags,
            onTap: () => _showLogDetails(context, log),
            onEdit: () => _editLog(context, log),
            onDelete: () => _deleteLog(context, log),
          )),
      ],
    );
  }

  Widget _buildRemindersSection(BuildContext context, List<LogEntry> reminders, TagProvider tagProvider) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Reminders',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...reminders.take(2).map((log) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              Icons.schedule,
              color: theme.colorScheme.primary,
            ),
            title: Text(log.title),
            subtitle: Text(
              'Reminder: ${_formatReminderTime(log.reminder!)}',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () => _showLogDetails(context, log),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, LogProvider logProvider, TagProvider tagProvider) {
    final theme = Theme.of(context);
    final tagStats = logProvider.getTagUsageStats();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      'This Week',
                      _getLogsThisWeek(logProvider).toString(),
                      Icons.date_range,
                    ),
                    _buildStatItem(
                      context,
                      'With Reminders',
                      logProvider.logsWithReminders.toString(),
                      Icons.alarm,
                    ),
                    _buildStatItem(
                      context,
                      'Most Used Tag',
                      _getMostUsedTag(tagStats, tagProvider),
                      Icons.label,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStat(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, String subtitle, IconData icon) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatReminderTime(DateTime reminder) {
    final now = DateTime.now();
    final difference = reminder.difference(now);
    
    if (difference.inMinutes < 60) {
      return 'in ${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return 'in ${difference.inHours} hours';
    } else {
      return 'in ${difference.inDays} days';
    }
  }

  int _getLogsThisWeek(LogProvider logProvider) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return logProvider.logs.where((log) {
      return log.dateTime.isAfter(startOfWeek) && log.dateTime.isBefore(endOfWeek);
    }).length;
  }

  String _getMostUsedTag(Map<String, int> tagStats, TagProvider tagProvider) {
    if (tagStats.isEmpty) return 'None';
    
    final mostUsedTagId = tagStats.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final tag = tagProvider.tags.where((t) => t.id == mostUsedTagId).firstOrNull;
    return tag?.name ?? 'Unknown';
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
        builder: (context) => EditLogScreen(logEntry: log),
      ),
    ).then((result) {
      if (result == true) {
        // Log was updated, refresh the UI
        setState(() {});
      }
    });
  }

  void _showAddLogDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddLogScreen(isDialog: true),
    ).then((result) {
      if (result == true) {
        // Log was created, refresh the UI
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
