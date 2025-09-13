import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/tag_provider.dart';
import '../widgets/tag_chip.dart';
import '../widgets/edit_tag_dialog.dart';
import '../screens/add_log_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showEditTagDialog(BuildContext context, tag) {
    showDialog(
      context: context,
      builder: (context) => EditTagDialog(tag: tag),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: AppTheme.headerText,
          ),
        ),
        content,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTagSection() {
    return Consumer<TagProvider>(
      builder: (context, tagProvider, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.label, color: AppTheme.accentPrimary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Manage Tags',
                        style: AppTheme.bodyText,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddLogScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.add,
                        color: AppTheme.accentPrimary,
                      ),
                      tooltip: 'Add new tag',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (tagProvider.tags.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No tags created yet',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: tagProvider.tags.map((tag) {
                      return GestureDetector(
                        onTap: () => _showEditTagDialog(context, tag),
                        child: TagChip(
                          tag: tag,
                          isSelected: false,
                          onTap: () => _showEditTagDialog(context, tag),
                        ),
                      );
                    }).toList(),
                  ),
                if (tagProvider.tags.isNotEmpty)
                  const SizedBox(height: 8),
                if (tagProvider.tags.isNotEmpty)
                  Center(
                    child: Text(
                      'Tap any tag to edit',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTheme.headerText,
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: AppTheme.accentPrimary,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            // Tag Management Section
            _buildSection('Tag Management', _buildTagSection()),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}