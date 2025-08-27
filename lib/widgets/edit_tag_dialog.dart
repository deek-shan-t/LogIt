import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tag.dart';
import '../providers/tag_provider.dart';
import '../theme/app_theme.dart';

class EditTagDialog extends StatefulWidget {
  final Tag tag;

  const EditTagDialog({
    super.key,
    required this.tag,
  });

  @override
  State<EditTagDialog> createState() => _EditTagDialogState();
}

class _EditTagDialogState extends State<EditTagDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedColor = '#2196F3';
  bool _isLoading = false;

  final List<String> _predefinedColors = [
    '#2196F3', '#4CAF50', '#FF9800', '#F44336', '#9C27B0',
    '#00BCD4', '#8BC34A', '#FFC107', '#E91E63', '#3F51B5',
    '#009688', '#CDDC39', '#FF5722', '#795548', '#607D8B',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.tag.name;
    _selectedColor = widget.tag.colorHex ?? '#2196F3';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.backgroundSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Tag',
                      style: AppTheme.titleText.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingLg),
                
                // Tag Name Field
                TextFormField(
                  controller: _nameController,
                  style: AppTheme.bodyText,
                  decoration: InputDecoration(
                    labelText: 'Tag Name *',
                    labelStyle: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
                    hintText: 'Enter tag name',
                    hintStyle: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.backgroundTertiary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.label, color: AppTheme.textSecondary),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Tag name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Tag name must be at least 2 characters';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                
                // Color Selection
                Text('Color', style: AppTheme.titleText),
                const SizedBox(height: AppTheme.spacingMd),
                _buildColorPicker(),
                const SizedBox(height: AppTheme.spacingXxl),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: BorderSide(color: AppTheme.border),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateTag,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentPrimary,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Update'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: AppTheme.spacingSm,
      runSpacing: AppTheme.spacingSm,
      children: _predefinedColors.map((color) {
        final isSelected = color == _selectedColor;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(int.parse('0xFF${color.substring(1)}')),
              borderRadius: BorderRadius.circular(20),
              border: isSelected 
                  ? Border.all(color: AppTheme.textPrimary, width: 3)
                  : Border.all(color: AppTheme.border, width: 1),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Future<void> _updateTag() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final updatedTag = widget.tag.copyWith(
        name: _nameController.text.trim(),
        colorHex: _selectedColor,
      );
      
      final tagProvider = context.read<TagProvider>();
      final success = await tagProvider.updateTag(updatedTag);
      
      if (success && mounted) {
        Navigator.pop(context, true);
        _showSuccessSnackBar('Tag updated successfully!');
      } else if (mounted) {
        _showErrorSnackBar(tagProvider.error ?? 'Failed to update tag');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('An error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTheme.bodyText),
        backgroundColor: AppTheme.accentSuccess,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTheme.bodyText),
        backgroundColor: AppTheme.accentError,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
