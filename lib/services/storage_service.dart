import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/task_category.dart';

class StorageService {
  static Future<void> saveTasks(Map<String, List<Task>> tasks) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonMap = tasks.map(
      (key, value) =>
          MapEntry(key, value.map((task) => task.toJson()).toList()),
    );

    await prefs.setString("tasks", jsonEncode(jsonMap));
  }

  static Future<Map<String, List<Task>>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();

    final json = prefs.getString("tasks");

    if (json == null) {
      return {};
    }

    final decoded = jsonDecode(json);

    return decoded.map<String, List<Task>>(
      (key, value) => MapEntry(
        key,
        (value as List).map((item) => Task.fromJson(item)).toList(),
      ),
    );
  }

  static const defaultCategories = [
    TaskCategory(name: 'Личное', colorValue: 0xFF5E5CE6),
    TaskCategory(name: 'Работа', colorValue: 0xFFFF9F0A),
    TaskCategory(name: 'Учёба', colorValue: 0xFF30D158),
    TaskCategory(name: 'Покупки', colorValue: 0xFFFF375F),
  ];

  static Future<List<TaskCategory>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('categories');
    if (json == null) return defaultCategories;
    return (jsonDecode(json) as List)
        .map((item) => TaskCategory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveCategories(List<TaskCategory> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'categories',
      jsonEncode(categories.map((category) => category.toJson()).toList()),
    );
  }

  static Future<bool> loadNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notificationsEnabled') ?? true;
  }

  static Future<void> saveNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
  }
}
