import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

// Run build_runner to generate TagAdapter
// Example: flutter pub run build_runner build
// colorHex should be a hex string like '#FF5722'

part 'tag.g.dart';

@HiveType(typeId: 1)
class Tag {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? colorHex;

  const Tag({
    required this.id,
    required this.name,
    this.colorHex,
  });

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as String,
      name: map['name'] as String,
      colorHex: map['colorHex'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorHex': colorHex,
    };
  }

  Tag copyWith({
    String? id,
    String? name,
    String? colorHex,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  // Convert hex string to Color object
  Color get color {
    if (colorHex == null || colorHex!.isEmpty) return Colors.grey;
    try {
      return Color(int.parse(colorHex!.replaceFirst('#', '0xff')));
    } catch (_) {
      return Colors.grey;
    }
  }

  // Validation
  bool get isValid => id.isNotEmpty && name.trim().isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag &&
        other.id == id &&
        other.name == name &&
        other.colorHex == colorHex;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ colorHex.hashCode;

  @override
  String toString() => 'Tag(id: $id, name: $name, colorHex: $colorHex)';
}