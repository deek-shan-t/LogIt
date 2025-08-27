import 'package:flutter/material.dart';
import '../models/tag.dart';
import '../theme/app_theme.dart';

class TagChip extends StatelessWidget {
  final Tag tag;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isSelected;
  final TagChipSize size;

  const TagChip({
    super.key,
    required this.tag,
    this.onTap,
    this.onDelete,
    this.isSelected = false,
    this.size = TagChipSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final tagColor = Color(int.parse('0xFF${tag.colorHex?.substring(1) ?? 'FF5722'}'));
    
    final chipSize = _getChipSize();
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: chipSize.horizontalPadding,
          vertical: chipSize.verticalPadding,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? tagColor 
              : tagColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(chipSize.borderRadius),
          border: Border.all(
            color: tagColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag.name,
              style: AppTheme.bodyText.copyWith(
                color: isSelected 
                    ? Colors.white 
                    : tagColor,
                fontSize: chipSize.fontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (onDelete != null) ...[
              SizedBox(width: chipSize.iconSpacing),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.close,
                  size: chipSize.iconSize,
                  color: isSelected 
                      ? Colors.white 
                      : tagColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _ChipSize _getChipSize() {
    switch (size) {
      case TagChipSize.small:
        return const _ChipSize(
          horizontalPadding: 8,
          verticalPadding: 4,
          borderRadius: 12,
          fontSize: 11,
          iconSize: 14,
          iconSpacing: 4,
        );
      case TagChipSize.medium:
        return const _ChipSize(
          horizontalPadding: 12,
          verticalPadding: 6,
          borderRadius: 16,
          fontSize: 13,
          iconSize: 16,
          iconSpacing: 6,
        );
      case TagChipSize.large:
        return const _ChipSize(
          horizontalPadding: 16,
          verticalPadding: 8,
          borderRadius: 20,
          fontSize: 15,
          iconSize: 18,
          iconSpacing: 8,
        );
    }
  }
}

enum TagChipSize { small, medium, large }

class _ChipSize {
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;
  final double fontSize;
  final double iconSize;
  final double iconSpacing;

  const _ChipSize({
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.borderRadius,
    required this.fontSize,
    required this.iconSize,
    required this.iconSpacing,
  });
}
