import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/log_entry.dart';
import '../models/tag.dart';

class HiveService {
  static const String logEntryBoxName = 'log_entries';
  static const String tagBoxName = 'tags';

  static bool _initialized = false;

  // Initialization
  static Future<void> init() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    Hive.registerAdapter(LogEntryAdapter());
    Hive.registerAdapter(TagAdapter());
    _initialized = true;
  }

  // Open boxes
  static Future<Box<LogEntry>> openLogEntryBox() async {
    await init();
    return await Hive.openBox<LogEntry>(logEntryBoxName);
  }

  static Future<Box<Tag>> openTagBox() async {
    await init();
    return await Hive.openBox<Tag>(tagBoxName);
  }

  // CRUD for LogEntry
  static Future<void> addLogEntry(LogEntry entry) async {
    if (!entry.isValid) throw Exception('Invalid LogEntry');
    final box = await openLogEntryBox();
    await box.put(entry.id, entry);
  }

  static Future<LogEntry?> getLogEntry(String id) async {
    final box = await openLogEntryBox();
    return box.get(id);
  }

  static Future<List<LogEntry>> getAllLogEntries() async {
    final box = await openLogEntryBox();
    return box.values.toList();
  }

  static Future<void> updateLogEntry(LogEntry entry) async {
    if (!entry.isValid) throw Exception('Invalid LogEntry');
    final box = await openLogEntryBox();
    if (!box.containsKey(entry.id)) throw Exception('LogEntry not found');
    await box.put(entry.id, entry);
  }

  static Future<void> deleteLogEntry(String id) async {
    final box = await openLogEntryBox();
    await box.delete(id);
  }

  // Batch operations for LogEntry
  static Future<void> addLogEntries(List<LogEntry> entries) async {
    final box = await openLogEntryBox();
    final Map<String, LogEntry> validEntries = {
      for (var e in entries)
        if (e.isValid) e.id: e
    };
    await box.putAll(validEntries);
  }

  static Future<void> deleteLogEntries(List<String> ids) async {
    final box = await openLogEntryBox();
    await box.deleteAll(ids);
  }

  // CRUD for Tag
  static Future<void> addTag(Tag tag) async {
    if (!tag.isValid) throw Exception('Invalid Tag');
    final box = await openTagBox();
    await box.put(tag.id, tag);
  }

  static Future<Tag?> getTag(String id) async {
    final box = await openTagBox();
    return box.get(id);
  }

  static Future<List<Tag>> getAllTags() async {
    final box = await openTagBox();
    return box.values.toList();
  }

  static Future<void> updateTag(Tag tag) async {
    if (!tag.isValid) throw Exception('Invalid Tag');
    final box = await openTagBox();
    if (!box.containsKey(tag.id)) throw Exception('Tag not found');
    await box.put(tag.id, tag);
  }

  static Future<void> deleteTag(String id) async {
    final box = await openTagBox();
    await box.delete(id);
  }

  // Batch operations for Tag
  static Future<void> addTags(List<Tag> tags) async {
    final box = await openTagBox();
    final Map<String, Tag> validTags = {
      for (var t in tags)
        if (t.isValid) t.id: t
    };
    await box.putAll(validTags);
  }

  static Future<void> deleteTags(List<String> ids) async {
    final box = await openTagBox();
    await box.deleteAll(ids);
  }

  // Close all boxes
  static Future<void> closeAll() async {
    await Hive.close();
    _initialized = false;
  }
}
