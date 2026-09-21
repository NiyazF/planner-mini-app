import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/note_storage.dart';
import 'note_editor_screen.dart';
import 'folders_screen.dart';
import '../widgets/note_card.dart';
import '../widgets/sort_notes_sheet.dart';
import '../models/life_sphere.dart';
import '../services/life_sphere_storage.dart';
import '../widgets/spheres_filter.dart';
import '../widgets/note_actions_sheet.dart';
import '../models/note_folder.dart';
import '../services/note_folder_storage.dart';
import '../widgets/move_note_to_folder_sheet.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> notes = [];
  List<LifeSphere> spheres = [];
  List<NoteFolder> folders = [];
  final TextEditingController searchController = TextEditingController();
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  NotesSort sort = NotesSort.updated;

  String search = "";

  String? selectedSphereId;
  String selectedFolderId = NoteFolderStorage.allFolderId;

  @override
  void initState() {
    super.initState();
    loadNotes();
    loadSpheres();
    loadFolders();
    searchController.addListener(() {
      setState(() {
        search = searchController.text.toLowerCase();
      });
    });
  }

  Future<void> loadSpheres() async {
    spheres = await LifeSphereStorage.load();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadFolders() async {
    final loadedFolders = await NoteFolderStorage.load();
    if (!mounted) return;
    setState(() {
      folders = loadedFolders;
      if (!folders.any((folder) => folder.id == selectedFolderId)) {
        selectedFolderId = NoteFolderStorage.allFolderId;
      }
    });
  }

  Future<void> loadNotes() async {
    notes = await NoteStorage.loadNotes();

    switch (sort) {
      case NotesSort.updated:
        notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;

      case NotesSort.created:
        notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;

      case NotesSort.title:
        notes.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    if (mounted) setState(() {});
  }

  Future<void> _moveNote(Note note) async {
    final folder = await showModalBottomSheet<NoteFolder>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => MoveNoteToFolderSheet(selectedFolderId: note.folderId),
    );
    if (folder == null) return;

    final index = notes.indexWhere((item) => item.id == note.id);
    if (index == -1) return;
    final updated = note.copyWith(
      folderId: folder.id,
      updatedAt: DateTime.now(),
    );
    setState(() => notes[index] = updated);
    await NoteStorage.saveNotes(notes);
    await loadFolders();
  }

  Future<void> _deleteNote(Note note) async {
    notes.removeWhere((item) => item.id == note.id);
    await NoteStorage.saveNotes(notes);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<Note> filteredNotes = notes.where((note) {
      final matchSearch =
          note.title.toLowerCase().contains(search) ||
          note.plainText.toLowerCase().contains(search);

      final matchSphere =
          selectedSphereId == null || note.sphereIds.contains(selectedSphereId);

      final matchFolder =
          selectedFolderId == NoteFolderStorage.allFolderId ||
          note.folderId == selectedFolderId;

      return matchSearch && matchSphere && matchFolder;
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Заметки"),

        actions: [
          PopupMenuButton<String>(
            tooltip: 'Выбрать группу',
            icon: const Icon(Icons.folder_open_outlined),
            initialValue: selectedFolderId,
            onSelected: (id) async {
              if (id == 'manage_folders') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FoldersScreen()),
                );
                loadFolders();
              } else {
                setState(() => selectedFolderId = id);
              }
            },
            itemBuilder: (_) => [
              ...folders.map(
                (folder) => PopupMenuItem<String>(
                  value: folder.id,
                  child: Row(
                    children: [
                      Icon(
                        folder.id == NoteFolderStorage.allFolderId
                            ? Icons.folder_special_outlined
                            : Icons.folder_outlined,
                      ),
                      const SizedBox(width: 10),
                      Text(folder.name),
                    ],
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'manage_folders',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined),
                    SizedBox(width: 10),
                    Text('Управление группами'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.sort),

            onPressed: () {
              showModalBottomSheet(
                context: context,

                builder: (_) => SortNotesSheet(
                  current: sort,

                  onSelected: (value) {
                    setState(() {
                      sort = value;
                    });

                    loadNotes();
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),

            child: TextField(
              controller: searchController,

              decoration: InputDecoration(
                hintText: "Поиск",

                prefixIcon: const Icon(Icons.search),

                filled: true,

                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SpheresFilter(
            spheres: spheres,
            selectedId: selectedSphereId,

            onChanged: (id) {
              setState(() {
                selectedSphereId = id;
              });
            },
          ),

          const SizedBox(height: 10),
          Expanded(
            child: filteredNotes.isEmpty
                ? const Center(
                    child: Text(
                      "Ничего не найдено",
                      style: TextStyle(fontSize: 22),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredNotes.length,

                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];

                      return Dismissible(
                        key: ValueKey(note.id),

                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 24),
                          color: Colors.orange,
                          child: const Icon(
                            Icons.folder_copy_outlined,
                            color: Colors.white,
                          ),
                        ),

                        secondaryBackground: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),

                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            await _deleteNote(note);
                            return true;
                          }
                          if (direction == DismissDirection.startToEnd) {
                            await _moveNote(note);
                          }
                          return false;
                        },

                        child: NoteCard(
                          note: note,

                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NoteEditorScreen(note: note),
                              ),
                            );

                            if (result == true) {
                              loadNotes();
                            }
                          },
                          onLongPress: () {
                            showModalBottomSheet(
                              context: context,

                              builder: (_) => NoteActionsSheet(
                                onEdit: () {
                                  Navigator.pop(context);

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          NoteEditorScreen(note: note),
                                    ),
                                  ).then((_) => loadNotes());
                                },

                                onFolder: () {
                                  Navigator.pop(context);
                                  _moveNote(note);
                                },

                                onSphere: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          NoteEditorScreen(note: note),
                                    ),
                                  ).then((_) => loadNotes());
                                },

                                onDuplicate: () async {
                                  Navigator.pop(context);

                                  notes.add(
                                    note.copyWith(
                                      id: DateTime.now().millisecondsSinceEpoch
                                          .toString(),
                                      createdAt: DateTime.now(),
                                      updatedAt: DateTime.now(),
                                    ),
                                  );

                                  await NoteStorage.saveNotes(notes);

                                  loadNotes();
                                },

                                onDelete: () async {
                                  Navigator.pop(context);

                                  await _deleteNote(note);
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),

        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NoteEditorScreen()),
          );

          loadNotes();
        },
      ),
    );
  }
}
