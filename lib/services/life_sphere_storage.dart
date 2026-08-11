import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/life_sphere.dart';

class LifeSphereStorage {
  static const _key = "life_spheres";

  static Future<List<LifeSphere>> load() async {
    final prefs = await SharedPreferences.getInstance();

    final json = prefs.getString(_key);

    if (json == null) {
      return [
        LifeSphere(
          id: "health",
          name: "Здоровье",
          emoji: "❤️",
          color: 0xFFE74C3C,
        ),
        LifeSphere(id: "work", name: "Работа", emoji: "💼", color: 0xFF3498DB),
        LifeSphere(
          id: "finance",
          name: "Финансы",
          emoji: "💰",
          color: 0xFFF1C40F,
        ),
      ];
    }

    final decoded = jsonDecode(json);

    return (decoded as List).map((e) => LifeSphere.fromJson(e)).toList();
  }

  static Future<void> save(List<LifeSphere> list) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _key,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }
}
