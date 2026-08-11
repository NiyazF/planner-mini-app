import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/note.dart';

class NoteStorage {
  static const String notesKey = "notes";

  static Future<List<Note>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = prefs.getString(notesKey);

    if (jsonString == null) {
      return [];
    }

    final List decoded = jsonDecode(jsonString);

    return decoded.map((e) => Note.fromJson(e)).toList();
  }

  static Future<void> saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonList = notes.map((e) => e.toJson()).toList();

    await prefs.setString(notesKey, jsonEncode(jsonList));
  }
}
