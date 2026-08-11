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

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> notes = [];
  List<LifeSphere> spheres = [];
  final TextEditingController searchController = TextEditingController();
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  NotesSort sort = NotesSort.updated;

  String search = "";

  String? selectedSphereId;

  @override
  void initState() {
    super.initState();
    loadNotes();
    loadSpheres();
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

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<Note> filteredNotes = notes.where((note) {
      final matchSearch =
          note.title.toLowerCase().contains(search) ||
          note.content.toLowerCase().contains(search);

      final matchSphere =
          selectedSphereId == null || note.sphereIds.contains(selectedSphereId);

      return matchSearch && matchSphere;
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Заметки"),

        actions: [
          IconButton(
            icon: const Icon(Icons.folder_copy_outlined),

            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FoldersScreen()),
              );
            },
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
                            notes.removeWhere((e) => e.id == note.id);

                            await NoteStorage.saveNotes(notes);

                            setState(() {});

                            return true;
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
                                },

                                onSphere: () {
                                  Navigator.pop(context);
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

                                  notes.removeWhere((e) => e.id == note.id);

                                  await NoteStorage.saveNotes(notes);

                                  loadNotes();
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
