import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/note_block.dart';
import '../services/note_storage.dart';
import '../widgets/note_toolbar.dart';
import '../widgets/select_spheres_sheet.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  const NoteEditorScreen({super.key, this.note});
  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController titleController;
  final List<TextEditingController> blockControllers = [];
  List<NoteBlock> blocks = [];
  List<String> selectedSphereIds = [];
  NoteBlockType currentBlockType = NoteBlockType.paragraph;
  bool isBold = false;
  bool isItalic = false;
  bool isUnderline = false;
  bool isStrike = false;
  int selectedColor = 0xFF16161A;
  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note?.title ?? "");
    selectedSphereIds = List<String>.from(widget.note?.sphereIds ?? []);
    if (widget.note != null && widget.note!.blocks.isNotEmpty) {
      blocks = widget.note!.blocks.map((block) => block.copyWith()).toList();
    } else {
      blocks = [
        NoteBlock(id: DateTime.now().microsecondsSinceEpoch.toString()),
      ];
    }
    _createControllers();
  }

  void _createControllers() {
    for (final controller in blockControllers) {
      controller.dispose();
    }
    blockControllers.clear();
    for (final block in blocks) {
      final controller = TextEditingController(text: block.text);
      controller.addListener(() {
        final index = blockControllers.indexOf(controller);
        if (index != -1 && index < blocks.length) {
          blocks[index].text = controller.text;
        }
      });
      blockControllers.add(controller);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    for (final controller in blockControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> saveNote() async {
    final now = DateTime.now();
    final preparedBlocks = <NoteBlock>[];
    for (var i = 0; i < blocks.length; i++) {
      preparedBlocks.add(blocks[i].copyWith(text: blockControllers[i].text));
    }
    final plainText = preparedBlocks
        .map((block) => block.text)
        .where((text) => text.trim().isNotEmpty)
        .join('\n');
    final notes = await NoteStorage.loadNotes();
    final note = Note(
      id: widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      content: plainText,
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
      folderId: widget.note?.folderId ?? "all",
      sphereIds: List<String>.from(selectedSphereIds),
      blocks: preparedBlocks,
    );
    if (widget.note == null) {
      notes.add(note);
    } else {
      final index = notes.indexWhere((item) => item.id == widget.note!.id);
      if (index != -1) {
        notes[index] = note;
      }
    }
    await NoteStorage.saveNotes(notes);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void updateCurrentBlockStyle() {
    if (blocks.isEmpty) return;
    final index = blockControllers.length - 1;
    if (index < 0 || index >= blocks.length) return;
    setState(() {
      blocks[index] = blocks[index].copyWith(
        isBold: isBold,
        isItalic: isItalic,
        isUnderlined: isUnderline,
        isStruckThrough: isStrike,
        colorValue: selectedColor,
        type: currentBlockType,
      );
    });
  }

  Future<void> selectSpheres() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SelectSpheresSheet(selected: selectedSphereIds);
      },
    );
    if (result != null) {
      setState(() {
        selectedSphereIds = result;
      });
    }
  }

  Future<void> selectColor() async {
    const colors = [
      0xFF16161A,
      0xFFFF3B30,
      0xFF007AFF,
      0xFFFF9500,
      0xFF34C759,
      0xFFAF52DE,
      0xFFFF2D55,
    ];
    final result = await showModalBottomSheet<int>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: colors.map((color) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context, color);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: color == selectedColor
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
    if (result != null) {
      setState(() {
        selectedColor = result;
      });
      updateCurrentBlockStyle();
    }
  }

  void toggleBold() {
    setState(() {
      isBold = !isBold;
    });
    updateCurrentBlockStyle();
  }

  void toggleItalic() {
    setState(() {
      isItalic = !isItalic;
    });
    updateCurrentBlockStyle();
  }

  void toggleUnderline() {
    setState(() {
      isUnderline = !isUnderline;
    });
    updateCurrentBlockStyle();
  }

  void toggleStrike() {
    setState(() {
      isStrike = !isStrike;
    });
    updateCurrentBlockStyle();
  }

  void setChecklist() {
    setState(() {
      currentBlockType = NoteBlockType.checklist;
    });
    updateCurrentBlockStyle();
  }

  void setNumbered() {
    setState(() {
      currentBlockType = NoteBlockType.numbered;
    });
    updateCurrentBlockStyle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Заметка"),
        actions: [
          FilledButton(onPressed: saveNote, child: const Text("Готово")),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
              decoration: const InputDecoration(
                hintText: "Название",
                border: InputBorder.none,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: blocks.length,
                itemBuilder: (context, index) {
                  final block = blocks[index];
                  final style = TextStyle(
                    fontSize: 18,
                    color: Color(block.colorValue),
                    fontWeight: block.isBold
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontStyle: block.isItalic
                        ? FontStyle.italic
                        : FontStyle.normal,
                    decoration: TextDecoration.combine([
                      if (block.isUnderlined) TextDecoration.underline,
                      if (block.isStruckThrough) TextDecoration.lineThrough,
                    ]),
                  );
                  Widget field = TextField(
                    controller: blockControllers[index],
                    style: style,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: index == 0
                          ? "Начните писать..."
                          : "Продолжить...",
                      border: InputBorder.none,
                    ),
                  );
                  if (block.type == NoteBlockType.checklist) {
                    field = Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: block.isChecked,
                          onChanged: (value) {
                            setState(() {
                              blocks[index] = block.copyWith(
                                isChecked: value ?? false,
                              );
                            });
                          },
                        ),
                        Expanded(child: field),
                      ],
                    );
                  }
                  if (block.type == NoteBlockType.numbered) {
                    field = Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 12, right: 8),
                          child: Text(
                            "${index + 1}.",
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        Expanded(child: field),
                      ],
                    );
                  }
                  return field;
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NoteToolbar(
        onSphere: selectSpheres,
        onBold: toggleBold,
        onItalic: toggleItalic,
        onUnderline: toggleUnderline,
        onStrike: toggleStrike,
        onChecklist: setChecklist,
        onNumbers: setNumbered,
        onColor: selectColor,
        boldActive: isBold,
        italicActive: isItalic,
        underlineActive: isUnderline,
        strikeActive: isStrike,
      ),
    );
  }
}
