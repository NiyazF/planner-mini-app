import 'package:flutter/material.dart';

import '../models/note_folder.dart';
import '../services/note_folder_storage.dart';

/// Lets the user select an existing note folder or create one for the note.
///
/// The selected folder is returned through [Navigator.pop].
class MoveNoteToFolderSheet extends StatefulWidget {
  final String? selectedFolderId;

  const MoveNoteToFolderSheet({super.key, this.selectedFolderId});

  @override
  State<MoveNoteToFolderSheet> createState() =>
      _MoveNoteToFolderSheetState();
}

class _MoveNoteToFolderSheetState extends State<MoveNoteToFolderSheet> {
  final _folderNameController = TextEditingController();

  List<NoteFolder> _folders = [];
  bool _isLoading = true;
  bool _isCreating = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  @override
  void dispose() {
    _folderNameController.dispose();
    super.dispose();
  }

  Future<void> _loadFolders() async {
    final folders = await NoteFolderStorage.load();
    if (!mounted) return;

    setState(() {
      _folders = folders;
      _isLoading = false;
    });
  }

  Future<void> _createFolder() async {
    final name = _folderNameController.text.trim();
    if (name.isEmpty || _isSaving) return;

    for (final folder in _folders) {
      if (folder.name.toLowerCase() == name.toLowerCase()) {
        Navigator.pop(context, folder);
        return;
      }
    }

    final newFolder = NoteFolder(
      id: 'folder_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
    );

    setState(() => _isSaving = true);
    try {
      await NoteFolderStorage.save([..._folders, newFolder]);
      if (!mounted) return;
      Navigator.pop(context, newFolder);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить группу')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Переместить в группу',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: 'Закрыть',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(),
              )
            else ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _folders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final folder = _folders[index];
                    final selected = folder.id == widget.selectedFolderId;

                    return Card(
                      margin: EdgeInsets.zero,
                      color: selected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: ListTile(
                        leading: Icon(
                          folder.id == NoteFolderStorage.allFolderId
                              ? Icons.folder_special_outlined
                              : Icons.folder_outlined,
                        ),
                        title: Text(
                          folder.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: folder.id == NoteFolderStorage.allFolderId
                            ? const Text('Все заметки')
                            : null,
                        trailing: selected
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(context, folder),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (_isCreating) ...[
                TextField(
                  controller: _folderNameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _createFolder(),
                  decoration: const InputDecoration(
                    hintText: 'Название новой группы',
                    prefixIcon: Icon(Icons.create_new_folder_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              setState(() {
                                _isCreating = false;
                                _folderNameController.clear();
                              });
                            },
                      child: const Text('Отмена'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _isSaving ? null : _createFolder,
                      child: Text(_isSaving ? 'Сохраняем...' : 'Создать'),
                    ),
                  ],
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _isCreating = true),
                    icon: const Icon(Icons.add),
                    label: const Text('Создать группу'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
