import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/log_provider.dart';
import '../providers/tag_provider.dart';

class DeveloperUtils {
  static Future<void> createSampleData(BuildContext context) async {
    final logProvider = context.read<LogProvider>();
    final tagProvider = context.read<TagProvider>();
    
    // Create sample tags
    await tagProvider.createTag(name: 'Work', colorHex: '#2196F3');
    await tagProvider.createTag(name: 'Personal', colorHex: '#4CAF50');
    await tagProvider.createTag(name: 'Important', colorHex: '#FF5722');
    await tagProvider.createTag(name: 'Meeting', colorHex: '#9C27B0');
    await tagProvider.createTag(name: 'Ideas', colorHex: '#FF9800');
    
    // Create sample logs
    await logProvider.createLog(
      title: 'Team Meeting Notes',
      description: 'Discussed project roadmap and upcoming deadlines. Need to finalize the design specs by Friday.',
      tags: ['work', 'meeting'],
      reminder: DateTime.now().add(const Duration(hours: 2)),
    );
    
    await logProvider.createLog(
      title: 'Grocery Shopping',
      description: 'Buy milk, bread, eggs, and vegetables for the week.',
      tags: ['personal'],
    );
    
    await logProvider.createLog(
      title: 'App Development Ideas',
      description: 'New feature ideas: dark mode, export functionality, search improvements.',
      tags: ['work', 'ideas'],
      customDate: DateTime.now().subtract(const Duration(days: 1)),
    );
    
    await logProvider.createLog(
      title: 'Doctor Appointment',
      description: 'Annual check-up scheduled for next week.',
      tags: ['important', 'personal'],
      reminder: DateTime.now().add(const Duration(days: 7)),
    );
    
    await logProvider.createLog(
      title: 'Project Deadline',
      description: 'Final submission due tomorrow. Review all documents and code.',
      tags: ['work', 'important'],
      reminder: DateTime.now().add(const Duration(hours: 18)),
    );
  }
}
