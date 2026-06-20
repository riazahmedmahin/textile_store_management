import 'package:flutter/material.dart';

class AppSection {
  final int? id;
  final String name;
  final int colorValue;
  final String icon;
  final DateTime createdAt;

  AppSection({
    this.id,
    required this.name,
    required this.colorValue,
    required this.icon,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Color get color => Color(colorValue);

  AppSection copyWith({
    int? id,
    String? name,
    int? colorValue,
    String? icon,
    DateTime? createdAt,
  }) {
    return AppSection(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color_value': colorValue,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppSection.fromMap(Map<String, dynamic> map) {
    return AppSection(
      id: map['id'] as int?,
      name: map['name'] as String,
      colorValue: map['color_value'] as int,
      icon: map['icon'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
