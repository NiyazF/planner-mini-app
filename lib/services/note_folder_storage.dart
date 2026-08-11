import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/note_folder.dart';

/// Stores user-created note folders.
///
/// The `all` folder is a virtual system folder: it is always present first in
/// the returned list and is never persisted as a user-editable item.
class NoteFolderStorage {
  static const String foldersKey = 'note_folders';
  static const String allFolderId = 'all';
  static const String allFolderName = 'Все';

  static NoteFolder get allFolder =>
      NoteFolder(id: allFolderId, name: allFolderName);

  static Future<List<NoteFolder>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawFolders = prefs.getString(foldersKey);

    if (rawFolders == null) {
      return [allFolder];
    }

    try {
      final decoded = jsonDecode(rawFolders);
      if (decoded is! List) {
        return [allFolder];
      }

      final folders = <NoteFolder>[];
      for (final item in decoded) {
        if (item is Map) {
          folders.add(NoteFolder.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      return _normalize(folders);
    } on FormatException {
      return [allFolder];
    } on TypeError {
      return [allFolder];
    }
  }

  static Future<void> save(Iterable<NoteFolder> folders) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedFolders = _normalize(folders);

    await prefs.setString(
      foldersKey,
      jsonEncode(normalizedFolders.map((folder) => folder.toJson()).toList()),
    );
  }

  static List<NoteFolder> _normalize(Iterable<NoteFolder> folders) {
    final seenIds = <String>{allFolderId};
    final normalizedFolders = <NoteFolder>[allFolder];

    for (final folder in folders) {
      final id = folder.id.trim();
      final name = folder.name.trim();

      if (id.isEmpty || id == allFolderId || name.isEmpty || !seenIds.add(id)) {
        continue;
      }

      normalizedFolders.add(NoteFolder(id: id, name: name));
    }

    return normalizedFolders;
  }
}
