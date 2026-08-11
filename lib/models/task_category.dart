import 'package:flutter/material.dart';

class TaskCategory {
  final String name;
  final int colorValue;

  const TaskCategory({required this.name, required this.colorValue});

  Color get color => Color(colorValue);

  factory TaskCategory.fromJson(Map<String, dynamic> json) => TaskCategory(
        name: json['name'] as String,
        colorValue: json['color'] as int,
      );

  Map<String, dynamic> toJson() => {'name': name, 'color': colorValue};
}
