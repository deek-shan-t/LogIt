import 'package:hive/hive.dart';

// Run build_runner to generate LogEntryAdapter
// Example: flutter pub run build_runner build

part 'log_entry.g.dart';

@HiveType(typeId: 0)
class LogEntry {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final DateTime dateTime;

  @HiveField(4)
  final List<String> tags;

  @HiveField(5)
  final DateTime? reminder;

  const LogEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.tags,
    this.reminder,
  });

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      tags: List<String>.from(map['tags'] as List),
      reminder: map['reminder'] != null
          ? DateTime.parse(map['reminder'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'tags': tags,
      'reminder': reminder?.toIso8601String(),
    };
  }

  LogEntry copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    List<String>? tags,
    DateTime? reminder,
  }) {
    return LogEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      tags: tags ?? List.from(this.tags),
      reminder: reminder ?? this.reminder,
    );
  }

  // Helper methods
  bool get hasReminder => reminder != null;
  bool get hasTags => tags.isNotEmpty;
  bool get isValid => id.isNotEmpty && title.trim().isNotEmpty;
  
  // Check if reminder is in the future
  bool get isReminderActive => hasReminder && reminder!.isAfter(DateTime.now());

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LogEntry &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.dateTime == dateTime &&
        _listEquals(other.tags, tags) &&
        other.reminder == reminder;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        dateTime.hashCode ^
        tags.hashCode ^
        reminder.hashCode;
  }

  @override
  String toString() {
    return 'LogEntry(id: $id, title: $title, dateTime: $dateTime, tags: ${tags.length})';
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}