import 'package:flutter/foundation.dart';
import '../models/log_entry.dart';
import '../services/hive_service.dart';

enum LogFilter {
  all,
  withReminders,
  withoutReminders,
  today,
  thisWeek,
  thisMonth,
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
  
  // Statistics (only used ones)
  int get totalLogsCount => _logs.length;
  int get filteredLogsCount => _filteredLogs.length;
  // Backward compatibility getter used by some screens
  int get logsWithReminders => _logs.where((l) => l.reminder != null).length;

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
      
      // Add to local list instead of reloading everything
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
      final originalLogIndex = _logs.indexWhere((log) => log.id == updatedLog.id);
      if (originalLogIndex == -1) {
        throw Exception('Log not found');
      }
      
      final originalLog = _logs[originalLogIndex];
      
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
      
      // Update local list instead of reloading everything
      _logs[originalLogIndex] = updatedLog;
      _applyFiltersAndSort();
      
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
      final logIndex = _logs.indexWhere((log) => log.id == logId);
      if (logIndex == -1) {
        throw Exception('Log not found');
      }
      
      final log = _logs[logIndex];
      
      if (log.reminder != null) {
        await _cancelReminder(log);
      }
      
      await HiveService.deleteLogEntry(logId);
      
      // Remove from local list instead of reloading everything
      _logs.removeAt(logIndex);
      _applyFiltersAndSort();
      
      return true;
    } catch (e) {
      _setError('Failed to delete log: $e');
      return false;
    }
  }

  Future<bool> deleteSelectedLogs() async {
    // This method is not used in the UI, but keeping for potential future use
    return false;
  }

  // Date management
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    _applyFiltersAndSort();
  }

  void selectToday() => setSelectedDate(DateTime.now());
  // Backwards-compatible alias (used by existing screens)
  void selectDate(DateTime date) => setSelectedDate(date);

  List<LogEntry> getLogsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _logs.where((log) =>
      log.dateTime.isAfter(startOfDay) && log.dateTime.isBefore(endOfDay)
    ).toList();
  }

  // Search and filter
  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
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
    if (_selectedTags.remove(tag)) {
      _applyFiltersAndSort();
    }
  }

  void clearAllFilters() {
    _searchQuery = '';
    _activeFilter = LogFilter.all;
    _selectedTags.clear();
    _applyFiltersAndSort();
  }

  // Individual clear methods for backward compatibility
  void clearSearch() {
    _searchQuery = '';
    _applyFiltersAndSort();
  }

  void clearSelectedTags() {
    _selectedTags.clear();
    _applyFiltersAndSort();
  }

  void clearSelectedDate() {
    _selectedDate = DateTime.now();
    _applyFiltersAndSort();
  }

  // Reminder management - removed notification functionality
  Future<void> _scheduleReminder(LogEntry log) async {
    // Notification functionality removed
    return;
  }

  Future<void> _cancelReminder(LogEntry log) async {
    // Notification functionality removed
    return;
  }

  List<LogEntry> getLogsWithActiveReminders() {
    final now = DateTime.now();
    return _logs.where((log) => 
      log.reminder != null && log.reminder!.isAfter(now)
    ).toList();
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

  void _applyFiltersAndSort() {
    _filteredLogs = List.from(_logs);
    
    _applySearchFilter();
    _applyTagFilter();
    _applyCategoryFilter();
    
    // Simple date-based sorting (newest first)
    _filteredLogs.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    
    notifyListeners();
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) return;
    
    _filteredLogs = _filteredLogs.where((log) =>
      log.title.toLowerCase().contains(_searchQuery) ||
      log.description.toLowerCase().contains(_searchQuery) ||
      log.tags.any((tag) => tag.toLowerCase().contains(_searchQuery))
    ).toList();
  }

  void _applyTagFilter() {
    if (_selectedTags.isEmpty) return;
    
    _filteredLogs = _filteredLogs.where((log) =>
      _selectedTags.every((tag) => log.tags.contains(tag))
    ).toList();
  }

  void _applyCategoryFilter() {
    switch (_activeFilter) {
      case LogFilter.withReminders:
        _filteredLogs = _filteredLogs.where((log) => log.reminder != null).toList();
        break;
      case LogFilter.withoutReminders:
        _filteredLogs = _filteredLogs.where((log) => log.reminder == null).toList();
        break;
      case LogFilter.today:
        _filteredLogs = _getLogsForDay(DateTime.now());
        break;
      case LogFilter.thisWeek:
        _filteredLogs = _getLogsForCurrentWeek();
        break;
      case LogFilter.thisMonth:
        _filteredLogs = _getLogsForCurrentMonth();
        break;
      case LogFilter.all:
        // No additional filtering
        break;
    }
  }

  List<LogEntry> _getLogsForDay(DateTime day) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _filteredLogs.where((log) =>
      log.dateTime.isAfter(startOfDay) && log.dateTime.isBefore(endOfDay)
    ).toList();
  }

  List<LogEntry> _getLogsForCurrentWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return _filteredLogs.where((log) => log.dateTime.isAfter(startOfWeekDay)).toList();
  }

  List<LogEntry> _getLogsForCurrentMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _filteredLogs.where((log) => log.dateTime.isAfter(startOfMonth)).toList();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() => _error = null;

  String _generateId() => 'log_${DateTime.now().millisecondsSinceEpoch}';

  int _getNextNotificationId() => _nextNotificationId++;

  @override
  Future<void> dispose() async {
    // Cancel all active reminders
    final activeReminders = getLogsWithActiveReminders();
    for (final log in activeReminders) {
      await _cancelReminder(log);
    }
    
    _logs.clear();
    _filteredLogs.clear();
    _notificationIds.clear();
    
    super.dispose();
  }
}
