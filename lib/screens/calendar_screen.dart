import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/log_provider.dart';
import '../theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar', style: AppTheme.titleText),
        backgroundColor: AppTheme.backgroundSecondary,
        actions: [
          TextButton(
            onPressed: _goToToday,
            child: Text('Today', style: AppTheme.bodyText.copyWith(color: AppTheme.accentPrimary)),
          ),
        ],
      ),
      body: Consumer<LogProvider>(
        builder: (context, logProvider, child) {
          return Column(
            children: [
              // Month navigation
              _buildMonthHeader(context),
              
              // Weekday headers
              _buildWeekdayHeaders(context),
              
              // Calendar grid
              Expanded(
                child: _buildCalendarGrid(context, logProvider),
              ),
              
              // Selected date info
              _buildSelectedDateInfo(context, logProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            _formatMonthYear(_currentMonth),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders(BuildContext context) {
    final theme = Theme.of(context);
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: weekdays.map((day) => Expanded(
          child: Center(
            child: Text(
              day,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context, LogProvider logProvider) {
    final daysInMonth = _getDaysInMonth(_currentMonth);
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final startingWeekday = firstDayOfMonth.weekday % 7; // Convert to 0-6 (Sun-Sat)
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: 42, // 6 weeks * 7 days
        itemBuilder: (context, index) {
          final dayOffset = index - startingWeekday;
          
          if (dayOffset < 0 || dayOffset >= daysInMonth) {
            // Empty cell for days outside current month
            return const SizedBox();
          }
          
          final day = dayOffset + 1;
          final date = DateTime(_currentMonth.year, _currentMonth.month, day);
          final logsForDay = logProvider.getLogsForDate(date);
          final isSelected = _isSameDay(date, _selectedDate);
          final isToday = _isSameDay(date, DateTime.now());
          
          return _buildCalendarDay(
            context,
            day: day,
            date: date,
            logCount: logsForDay.length,
            isSelected: isSelected,
            isToday: isToday,
            onTap: () => _selectDate(date, logProvider),
          );
        },
      ),
    );
  }

  Widget _buildCalendarDay(
    BuildContext context, {
    required int day,
    required DateTime date,
    required int logCount,
    required bool isSelected,
    required bool isToday,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    Color? backgroundColor;
    Color? textColor;
    Color? borderColor;
    
    if (isSelected) {
      backgroundColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
    } else if (isToday) {
      borderColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.primary;
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: borderColor != null ? Border.all(color: borderColor, width: 2) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                day.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: isSelected || isToday ? FontWeight.bold : null,
                ),
              ),
            ),
            if (logCount > 0)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getLogCountColor(logCount, theme),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      logCount > 9 ? '9+' : logCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDateInfo(BuildContext context, LogProvider logProvider) {
    final theme = Theme.of(context);
    final logsForSelectedDate = logProvider.getLogsForDate(_selectedDate);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatSelectedDate(_selectedDate),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (logsForSelectedDate.isNotEmpty)
                TextButton(
                  onPressed: () => _viewLogsForDate(context, logProvider),
                  child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (logsForSelectedDate.isEmpty)
            Text(
              'No logs for this date',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Text(
              '${logsForSelectedDate.length} log${logsForSelectedDate.length == 1 ? '' : 's'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          
          // Show preview of logs
          if (logsForSelectedDate.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...logsForSelectedDate.take(3).map((log) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• ${log.title}',
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )),
            if (logsForSelectedDate.length > 3)
              Text(
                '... and ${logsForSelectedDate.length - 3} more',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Color _getLogCountColor(int count, ThemeData theme) {
    if (count <= 2) return theme.colorScheme.primary;
    if (count <= 5) return Colors.orange;
    return Colors.red;
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _goToToday() {
    final today = DateTime.now();
    setState(() {
      _currentMonth = DateTime(today.year, today.month);
      _selectedDate = DateTime(today.year, today.month, today.day);
    });
  }

  void _selectDate(DateTime date, LogProvider logProvider) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _viewLogsForDate(BuildContext context, LogProvider logProvider) {
    // Set the selected date in the provider and navigate back to logs screen
    logProvider.selectDate(_selectedDate);
    Navigator.pop(context);
    
    // Switch to logs tab
    DefaultTabController.of(context)?.animateTo(1);
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatSelectedDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);
    
    if (selectedDay == today) {
      return 'Today, ${months[date.month - 1]} ${date.day}';
    } else if (selectedDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${months[date.month - 1]} ${date.day}';
    } else if (selectedDay == today.add(const Duration(days: 1))) {
      return 'Tomorrow, ${months[date.month - 1]} ${date.day}';
    } else {
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}
