import 'dart:convert';
import 'dart:js_interop';
import 'package:http/http.dart' as http;
import '../models/task.dart';

@JS('getTelegramUserId')
external JSString? _jsGetTelegramUserId();

class TelegramReminderService {
  static const String workerUrl =
      'https://calendar-reminders.kuku2004yandex-ru.workers.dev';

  // Опционально: твой личный Telegram ID для тестов в обычном браузере
  static const String? fallbackChatId = null;

  static String? get currentChatId {
    try {
      final tgId = _jsGetTelegramUserId()?.toDart;
      if (tgId != null && tgId.isNotEmpty) return tgId;
    } catch (_) {}
    return fallbackChatId;
  }

  static Future<void> scheduleTaskReminder(Task task) async {
    if (!task.reminder || task.date == null || task.time == null) return;

    final chatId = currentChatId;
    if (chatId == null) return;

    final parts = task.time!.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    final remindDateTime = DateTime(
      task.date!.year,
      task.date!.month,
      task.date!.day,
      hour,
      minute,
    );

    // Если время уже в прошлом — не ставим будильник
    if (remindDateTime.isBefore(DateTime.now())) return;

    try {
      await http.post(
        Uri.parse('$workerUrl/schedule'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': task.id,
          'chatId': chatId,
          'title': task.title,
          'category': task.category,
          'remindAtMs': remindDateTime.millisecondsSinceEpoch,
        }),
      );
    } catch (_) {}
  }

  static Future<void> cancelTaskReminder(String taskId) async {
    try {
      await http.delete(Uri.parse('$workerUrl/cancel?id=$taskId'));
    } catch (_) {}
  }
}
