import 'package:flutter/material.dart';

import '../models/note_folder.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final List<NoteFolder> folders = [NoteFolder(id: "all", name: "Все")];

  void createFolder() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Новая папка"),

          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Название"),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Отмена"),
            ),

            FilledButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) return;

                setState(() {
                  folders.add(
                    NoteFolder(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: controller.text.trim(),
                    ),
                  );
                });

                Navigator.pop(context);
              },
              child: const Text("Создать"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Папки")),

      floatingActionButton: FloatingActionButton(
        onPressed: createFolder,
        child: const Icon(Icons.add),
      ),

      body: ListView.builder(
        itemCount: folders.length,
        itemBuilder: (context, index) {
          final folder = folders[index];

          return ListTile(
            leading: const Icon(Icons.folder_outlined),

            title: Text(folder.name),

            trailing: folder.id == "all"
                ? null
                : IconButton(
                    icon: const Icon(Icons.delete_outline),

                    onPressed: () {
                      setState(() {
                        folders.removeAt(index);
                      });
                    },
                  ),
          );
        },
      ),
    );
  }
}
