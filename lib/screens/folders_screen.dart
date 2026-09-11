import 'package:flutter/material.dart';

import '../models/note_folder.dart';
import '../services/note_folder_storage.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  List<NoteFolder> _folders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final folders = await NoteFolderStorage.load();
    if (!mounted) return;
    setState(() {
      _folders = folders;
      _loading = false;
    });
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Новая группа'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
          decoration: const InputDecoration(hintText: 'Например, Работа'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Создать'),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmedName = name?.trim() ?? '';
    if (trimmedName.isEmpty) return;

    if (_folders.any(
      (folder) => folder.name.toLowerCase() == trimmedName.toLowerCase(),
    )) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Такая группа уже есть')));
      }
      return;
    }

    final folder = NoteFolder(
      id: 'folder_${DateTime.now().microsecondsSinceEpoch}',
      name: trimmedName,
    );
    final updated = [..._folders, folder];
    await NoteFolderStorage.save(updated);
    if (!mounted) return;
    setState(() => _folders = updated);
  }

  Future<void> _deleteFolder(NoteFolder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить группу?'),
        content: Text('Заметки из «${folder.name}» останутся в разделе «Все».'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final updated = _folders.where((item) => item.id != folder.id).toList();
    await NoteFolderStorage.save(updated);
    if (!mounted) return;
    setState(() => _folders = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Группы заметок')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createFolder,
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('Группа'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: _folders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final folder = _folders[index];
                final isAll = folder.id == NoteFolderStorage.allFolderId;
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(
                      isAll
                          ? Icons.folder_special_outlined
                          : Icons.folder_outlined,
                    ),
                    title: Text(
                      folder.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: isAll ? const Text('Все заметки') : null,
                    trailing: isAll
                        ? null
                        : IconButton(
                            tooltip: 'Удалить группу',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteFolder(folder),
                          ),
                  ),
                );
              },
            ),
    );
  }
}
