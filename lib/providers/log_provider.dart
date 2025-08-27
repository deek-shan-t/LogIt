import 'package:flutter/foundation.dart';
import '../models/log_entry.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';

enum LogFilter {
  all,
  withReminders,
  withoutReminders,
  today,
  thisWeek,
  thisMonth,
}

enum LogSortBy {
  dateCreated,
  title,
  reminderTime,
}

enum SortOrder {
  ascending,
  descending,
}

class LogProvider extends ChangeNotifier {
  // Core data
  List<LogEntry> _logs = [];
  List<LogEntry> _filteredLogs = [];
  
  // UI state
  bool _isLoading = false;
  String? _error;
  
  // Date state
  DateTime _selectedDate = DateTime.now();
  
  // Filter and search state
  String _searchQuery = '';
  LogFilter _activeFilter = LogFilter.all;
  final List<String> _selectedTags = [];
  
  // Sorting state
  LogSortBy _sortBy = LogSortBy.dateCreated;
  SortOrder _sortOrder = SortOrder.descending;
  
  // Selection state
  final Set<String> _selectedLogIds = {};
  
  // Notification tracking
  final Map<String, int> _notificationIds = {};
  int _nextNotificationId = 1000;

  // Getters
  List<LogEntry> get logs => List.unmodifiable(_logs);
  List<LogEntry> get filteredLogs => List.unmodifiable(_filteredLogs);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isEmpty => _logs.isEmpty;
  
  DateTime get selectedDate => _selectedDate;
  String get searchQuery => _searchQuery;
  LogFilter get activeFilter => _activeFilter;
  List<String> get selectedTags => List.unmodifiable(_selectedTags);
  
  LogSortBy get sortBy => _sortBy;
  SortOrder get sortOrder => _sortOrder;
  
  Set<String> get selectedLogIds => Set.unmodifiable(_selectedLogIds);
  bool get hasSelection => _selectedLogIds.isNotEmpty;
  int get selectionCount => _selectedLogIds.length;
  
  // Statistics
  int get totalLogsCount => _logs.length;
  int get filteredLogsCount => _filteredLogs.length;
  int get logsWithReminders => _logs.where((log) => log.reminder != null).length;

  // Initialize the provider
  Future<void> initialize() async {
    await loadLogs();
  }

  // CRUD Operations
  Future<void> loadLogs() async {
    try {
      _setLoading(true);
      _clearError();
      
      final logs = await HiveService.getAllLogEntries();
      _logs = logs;
      _applyFiltersAndSort();
      
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to load logs: $e');
    }
  }

  Future<bool> createLog({
    required String title,
    String? description,
    List<String>? tags,
    DateTime? reminder,
    DateTime? customDate,
  }) async {
    try {
      _clearError();
      
      if (title.trim().isEmpty) {
        _setError('Title cannot be empty');
        return false;
      }
      
      final log = LogEntry(
        id: _generateId(),
        title: title.trim(),
        description: description?.trim() ?? '',
        dateTime: customDate ?? DateTime.now(),
        tags: tags ?? [],
        reminder: reminder,
      );
      
      await HiveService.addLogEntry(log);
      
      // Schedule reminder if needed
      if (reminder != null) {
        await _scheduleReminder(log);
      }
      
      _logs.add(log);
      _applyFiltersAndSort();
      
      return true;
    } catch (e) {
      _setError('Failed to create log: $e');
      return false;
    }
  }

  Future<bool> updateLog(LogEntry updatedLog) async {
    try {
      _clearError();
      
      if (updatedLog.title.trim().isEmpty) {
        _setError('Title cannot be empty');
        return false;
      }
      
      // Find the original log to handle reminder changes
      final originalLog = _logs.firstWhere(
        (log) => log.id == updatedLog.id,
        orElse: () => throw Exception('Log not found'),
      );
      
      await HiveService.updateLogEntry(updatedLog);
      
      // Handle reminder changes
      if (originalLog.reminder != updatedLog.reminder) {
        // Cancel old reminder if it existed
        if (originalLog.reminder != null) {
          await _cancelReminder(originalLog);
        }
        
        // Schedule new reminder if needed
        if (updatedLog.reminder != null) {
          await _scheduleReminder(updatedLog);
        }
      }
      
      // Update the log in the list
      final index = _logs.indexWhere((log) => log.id == updatedLog.id);
      if (index != -1) {
        _logs[index] = updatedLog;
        _applyFiltersAndSort();
      }
      
      return true;
    } catch (e) {
      _setError('Failed to update log: $e');
      return false;
    }
  }

  Future<bool> deleteLog(String logId) async {
    try {
      _clearError();
      
      // Find the log to cancel any reminders
      final log = _logs.firstWhere(
        (log) => log.id == logId,
        orElse: () => throw Exception('Log not found'),
      );
      
      if (log.reminder != null) {
        await _cancelReminder(log);
      }
      
      await HiveService.deleteLogEntry(logId);
      
      _logs.removeWhere((log) => log.id == logId);
      _selectedLogIds.remove(logId);
      _applyFiltersAndSort();
      
      return true;
    } catch (e) {
      _setError('Failed to delete log: $e');
      return false;
    }
  }

  Future<bool> deleteSelectedLogs() async {
    if (_selectedLogIds.isEmpty) return false;
    
    try {
      _clearError();
      
      final logsToDelete = _logs.where((log) => _selectedLogIds.contains(log.id)).toList();
      
      // Cancel reminders for logs that have them
      for (final log in logsToDelete) {
        if (log.reminder != null) {
          await _cancelReminder(log);
        }
      }
      
      // Delete from Hive
      await HiveService.deleteLogEntries(List.from(_selectedLogIds));
      
      // Remove from local list
      _logs.removeWhere((log) => _selectedLogIds.contains(log.id));
      _selectedLogIds.clear();
      _applyFiltersAndSort();
      
      return true;
    } catch (e) {
      _setError('Failed to delete selected logs: $e');
      return false;
    }
  }

  // Date management
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    _applyFiltersAndSort();
  }

  void selectDate(DateTime date) {
    setSelectedDate(date);
  }

  void clearSelectedDate() {
    _selectedDate = DateTime.now();
    _applyFiltersAndSort();
  }

  void selectToday() {
    _selectedDate = DateTime.now();
    _applyFiltersAndSort();
  }

  void selectYesterday() {
    _selectedDate = DateTime.now().subtract(const Duration(days: 1));
    _applyFiltersAndSort();
  }

  void selectTomorrow() {
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _applyFiltersAndSort();
  }

  List<LogEntry> getLogsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _logs.where((log) =>
      log.dateTime.isAfter(startOfDay) && log.dateTime.isBefore(endOfDay)
    ).toList();
  }

  List<LogEntry> getLogsForDateRange(DateTime startDate, DateTime endDate) {
    return _logs.where((log) =>
      log.dateTime.isAfter(startDate.subtract(const Duration(days: 1))) &&
      log.dateTime.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
  }

  // Search and filter
  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFiltersAndSort();
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFiltersAndSort();
  }

  void setActiveFilter(LogFilter filter) {
    _activeFilter = filter;
    _applyFiltersAndSort();
  }

  void addSelectedTag(String tag) {
    if (!_selectedTags.contains(tag)) {
      _selectedTags.add(tag);
      _applyFiltersAndSort();
    }
  }

  void removeSelectedTag(String tag) {
    _selectedTags.remove(tag);
    _applyFiltersAndSort();
  }

  void clearSelectedTags() {
    _selectedTags.clear();
    _applyFiltersAndSort();
  }

  void clearAllFilters() {
    _searchQuery = '';
    _activeFilter = LogFilter.all;
    _selectedTags.clear();
    _applyFiltersAndSort();
  }

  // Sorting
  void setSortBy(LogSortBy sortBy, {SortOrder? order}) {
    _sortBy = sortBy;
    if (order != null) {
      _sortOrder = order;
    }
    _applyFiltersAndSort();
  }

  void toggleSortOrder() {
    _sortOrder = _sortOrder == SortOrder.ascending 
        ? SortOrder.descending 
        : SortOrder.ascending;
    _applyFiltersAndSort();
  }

  // Selection
  void selectLog(String logId) {
    _selectedLogIds.add(logId);
    notifyListeners();
  }

  void deselectLog(String logId) {
    _selectedLogIds.remove(logId);
    notifyListeners();
  }

  void toggleLogSelection(String logId) {
    if (_selectedLogIds.contains(logId)) {
      _selectedLogIds.remove(logId);
    } else {
      _selectedLogIds.add(logId);
    }
    notifyListeners();
  }

  void selectAllVisible() {
    _selectedLogIds.addAll(_filteredLogs.map((log) => log.id));
    notifyListeners();
  }

  void deselectAll() {
    _selectedLogIds.clear();
    notifyListeners();
  }

  bool isLogSelected(String logId) {
    return _selectedLogIds.contains(logId);
  }

  // Reminder management
  Future<void> _scheduleReminder(LogEntry log) async {
    if (log.reminder == null) return;
    
    try {
      await NotificationService.init();
      await NotificationService.requestPermissions();
      
      final notificationId = _getNextNotificationId();
      _notificationIds[log.id] = notificationId;
      
      await NotificationService.scheduleNotification(
        id: notificationId,
        title: 'Log Reminder',
        body: log.title,
        scheduledTime: log.reminder!,
      );
    } catch (e) {
      debugPrint('Failed to schedule reminder for log ${log.id}: $e');
    }
  }

  Future<void> _cancelReminder(LogEntry log) async {
    final notificationId = _notificationIds[log.id];
    if (notificationId != null) {
      try {
        await NotificationService.cancelNotification(notificationId);
        _notificationIds.remove(log.id);
      } catch (e) {
        debugPrint('Failed to cancel reminder for log ${log.id}: $e');
      }
    }
  }

  Future<void> updateLogReminder(String logId, DateTime? newReminder) async {
    final log = _logs.firstWhere(
      (log) => log.id == logId,
      orElse: () => throw Exception('Log not found'),
    );
    
    final updatedLog = log.copyWith(reminder: newReminder);
    await updateLog(updatedLog);
  }

  List<LogEntry> getLogsWithActiveReminders() {
    final now = DateTime.now();
    return _logs.where((log) => 
      log.reminder != null && log.reminder!.isAfter(now)
    ).toList();
  }

  List<LogEntry> getOverdueReminders() {
    final now = DateTime.now();
    return _logs.where((log) => 
      log.reminder != null && log.reminder!.isBefore(now)
    ).toList();
  }

  // Utility methods
  LogEntry? getLogById(String id) {
    try {
      return _logs.firstWhere((log) => log.id == id);
    } catch (e) {
      return null;
    }
  }

  List<String> getAllTags() {
    final tagSet = <String>{};
    for (final log in _logs) {
      tagSet.addAll(log.tags);
    }
    return tagSet.toList()..sort();
  }

  Map<String, int> getTagUsageStats() {
    final tagCounts = <String, int>{};
    for (final log in _logs) {
      for (final tag in log.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    return tagCounts;
  }

  // Private helper methods
  void _applyFiltersAndSort() {
    _filteredLogs = List.from(_logs);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredLogs = _filteredLogs.where((log) =>
        log.title.toLowerCase().contains(_searchQuery) ||
        log.description.toLowerCase().contains(_searchQuery) ||
        log.tags.any((tag) => tag.toLowerCase().contains(_searchQuery))
      ).toList();
    }
    
    // Apply tag filter
    if (_selectedTags.isNotEmpty) {
      _filteredLogs = _filteredLogs.where((log) =>
        _selectedTags.every((tag) => log.tags.contains(tag))
      ).toList();
    }
    
    // Apply category filter
    switch (_activeFilter) {
      case LogFilter.withReminders:
        _filteredLogs = _filteredLogs.where((log) => log.reminder != null).toList();
        break;
      case LogFilter.withoutReminders:
        _filteredLogs = _filteredLogs.where((log) => log.reminder == null).toList();
        break;
      case LogFilter.today:
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        _filteredLogs = _filteredLogs.where((log) =>
          log.dateTime.isAfter(startOfDay) && log.dateTime.isBefore(endOfDay)
        ).toList();
        break;
      case LogFilter.thisWeek:
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        _filteredLogs = _filteredLogs.where((log) =>
          log.dateTime.isAfter(startOfWeekDay)
        ).toList();
        break;
      case LogFilter.thisMonth:
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        _filteredLogs = _filteredLogs.where((log) =>
          log.dateTime.isAfter(startOfMonth)
        ).toList();
        break;
      case LogFilter.all:
        // No additional filtering
        break;
    }
    
    // Apply sorting
    _filteredLogs.sort((a, b) {
      int comparison;
      
      switch (_sortBy) {
        case LogSortBy.title:
          comparison = a.title.compareTo(b.title);
          break;
        case LogSortBy.reminderTime:
          if (a.reminder == null && b.reminder == null) {
            comparison = 0;
          } else if (a.reminder == null) {
            comparison = 1; // Null reminders go to the end
          } else if (b.reminder == null) {
            comparison = -1;
          } else {
            comparison = a.reminder!.compareTo(b.reminder!);
          }
          break;
        case LogSortBy.dateCreated:
          comparison = a.dateTime.compareTo(b.dateTime);
          break;
      }
      
      return _sortOrder == SortOrder.ascending ? comparison : -comparison;
    });
    
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'log_$timestamp';
  }

  int _getNextNotificationId() {
    return _nextNotificationId++;
  }

  // Cleanup
  @override
  Future<void> dispose() async {
    // Cancel all active reminders
    final activeReminders = getLogsWithActiveReminders();
    for (final log in activeReminders) {
      await _cancelReminder(log);
    }
    
    _logs.clear();
    _filteredLogs.clear();
    _selectedLogIds.clear();
    _notificationIds.clear();
    
    super.dispose();
  }
}
