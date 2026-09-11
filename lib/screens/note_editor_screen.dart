import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final List<FocusNode> blockFocusNodes = [];

  List<NoteBlock> blocks = [];
  List<String> selectedSphereIds = [];

  int activeBlockIndex = 0;
  final List<List<NoteBlock>> _undoStack = [];
  final List<List<NoteBlock>> _redoStack = [];

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

  // ------------------------------------------------------------
  // CONTROLLERS
  // ------------------------------------------------------------

  void _createControllers() {
    for (final controller in blockControllers) {
      controller.dispose();
    }

    for (final node in blockFocusNodes) {
      node.dispose();
    }

    blockControllers.clear();
    blockFocusNodes.clear();

    for (var i = 0; i < blocks.length; i++) {
      final controller = TextEditingController(text: blocks[i].text);

      final focusNode = FocusNode();

      controller.addListener(() {
        final index = blockControllers.indexOf(controller);

        if (index >= 0 && index < blocks.length) {
          blocks[index].text = controller.text;
        }
      });

      focusNode.addListener(() {
        if (focusNode.hasFocus) {
          activeBlockIndex = i;
        }
      });

      blockControllers.add(controller);
      blockFocusNodes.add(focusNode);
    }
  }

  @override
  void dispose() {
    titleController.dispose();

    for (final controller in blockControllers) {
      controller.dispose();
    }

    for (final node in blockFocusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  void _saveUndoState() {
    _undoStack.add(blocks.map((block) => block.copyWith()).toList());
    _redoStack.clear();

    // Не позволяем истории бесконечно расти.
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0);
    }
  }

  void _undo() {
    if (_undoStack.isEmpty) return;

    setState(() {
      _redoStack.add(blocks.map((block) => block.copyWith()).toList());
      blocks = _undoStack
          .removeLast()
          .map((block) => block.copyWith())
          .toList();

      if (blocks.isEmpty) {
        blocks.add(
          NoteBlock(id: DateTime.now().microsecondsSinceEpoch.toString()),
        );
      }

      activeBlockIndex = activeBlockIndex.clamp(0, blocks.length - 1);

      _createControllers();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (activeBlockIndex < blockFocusNodes.length) {
        blockFocusNodes[activeBlockIndex].requestFocus();
      }
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;

    setState(() {
      _undoStack.add(blocks.map((block) => block.copyWith()).toList());
      blocks = _redoStack
          .removeLast()
          .map((block) => block.copyWith())
          .toList();
      activeBlockIndex = activeBlockIndex.clamp(0, blocks.length - 1);
      _createControllers();
    });
  }
  // ------------------------------------------------------------
  // SAVE
  // ------------------------------------------------------------

  Future<void> saveNote() async {
    final now = DateTime.now();

    final preparedBlocks = <NoteBlock>[];

    for (var i = 0; i < blocks.length; i++) {
      preparedBlocks.add(blocks[i].copyWith(text: blockControllers[i].text));
    }

    // Убираем полностью пустые блоки,
    // но оставляем хотя бы один блок.
    final nonEmptyBlocks = preparedBlocks
        .where((block) => block.text.trim().isNotEmpty)
        .toList();

    if (nonEmptyBlocks.isEmpty) {
      nonEmptyBlocks.add(
        NoteBlock(id: DateTime.now().microsecondsSinceEpoch.toString()),
      );
    }

    final plainText = nonEmptyBlocks
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
      blocks: nonEmptyBlocks,
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

  // ------------------------------------------------------------
  // BLOCKS
  // ------------------------------------------------------------

  void _handleBackspace(int index) {
    if (index <= 0) return;
    _saveUndoState();

    final controller = blockControllers[index];

    // Если блок пустой — просто удаляем его.
    if (controller.text.isEmpty) {
      final previousText = blockControllers[index - 1].text;

      setState(() {
        blocks.removeAt(index);
        activeBlockIndex = index - 1;
        _createControllers();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final previousController = blockControllers[activeBlockIndex];

        previousController.selection = TextSelection.collapsed(
          offset: previousText.length,
        );

        blockFocusNodes[activeBlockIndex].requestFocus();
      });

      return;
    }

    // Если текст есть — объединяем текущий блок с предыдущим.
    final previousController = blockControllers[index - 1];

    final previousText = previousController.text;
    final currentText = controller.text;

    final previousBlock = blocks[index - 1];

    setState(() {
      blocks[index - 1] = previousBlock.copyWith(
        text: previousText + currentText,
      );

      blocks.removeAt(index);

      activeBlockIndex = index - 1;

      _createControllers();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final previousController = blockControllers[activeBlockIndex];

      previousController.selection = TextSelection.collapsed(
        offset: previousText.length,
      );

      blockFocusNodes[activeBlockIndex].requestFocus();
    });
  }

  // ------------------------------------------------------------
  // SELECTION
  // ------------------------------------------------------------

  TextSelection _selectionForActiveBlock() {
    if (blocks.isEmpty) {
      return const TextSelection.collapsed(offset: 0);
    }

    final index = activeBlockIndex;

    if (index < 0 || index >= blockControllers.length) {
      return const TextSelection.collapsed(offset: 0);
    }

    return blockControllers[index].selection;
  }

  bool get hasSelection {
    final selection = _selectionForActiveBlock();

    return selection.start != selection.end;
  }

  // ------------------------------------------------------------
  // FORMAT SELECTED TEXT
  // ------------------------------------------------------------

  void _formatSelection({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strike,
    int? color,
    String? fontFamily,
  }) {
    if (blocks.isEmpty) return;
    _saveUndoState();

    final index = activeBlockIndex;

    if (index < 0 || index >= blocks.length) return;

    final controller = blockControllers[index];
    final selection = controller.selection;

    // Если ничего не выделено —
    // меняем формат текущего блока целиком.
    if (selection.start == selection.end) {
      setState(() {
        blocks[index] = blocks[index].copyWith(
          isBold: bold,
          isItalic: italic,
          isUnderlined: underline,
          isStruckThrough: strike,
          colorValue: color,
          fontFamily: fontFamily,
        );
      });

      return;
    }

    final start = selection.start;
    final end = selection.end;

    final text = controller.text;

    final before = text.substring(0, start);
    final selected = text.substring(start, end);
    final after = text.substring(end);

    final original = blocks[index];

    final newBlocks = <NoteBlock>[];

    if (before.isNotEmpty) {
      newBlocks.add(
        original.copyWith(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          text: before,
        ),
      );
    }

    newBlocks.add(
      original.copyWith(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: selected,
        isBold: bold ?? original.isBold,
        isItalic: italic ?? original.isItalic,
        isUnderlined: underline ?? original.isUnderlined,
        isStruckThrough: strike ?? original.isStruckThrough,
        colorValue: color ?? original.colorValue,
        fontFamily: fontFamily ?? original.fontFamily,
      ),
    );

    if (after.isNotEmpty) {
      newBlocks.add(
        original.copyWith(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          text: after,
        ),
      );
    }

    setState(() {
      blocks.removeAt(index);
      blocks.insertAll(index, newBlocks);

      activeBlockIndex = index + (before.isNotEmpty ? 1 : 0);

      _createControllers();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (activeBlockIndex >= blockControllers.length) {
        return;
      }

      final selectedController = blockControllers[activeBlockIndex];

      selectedController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: selected.length,
      );

      blockFocusNodes[activeBlockIndex].requestFocus();
    });
  }

  // ------------------------------------------------------------
  // FORMAT BUTTONS
  // ------------------------------------------------------------

  void toggleBold() {
    final current = blocks[activeBlockIndex];

    _formatSelection(bold: !current.isBold);
  }

  void toggleItalic() {
    final current = blocks[activeBlockIndex];

    _formatSelection(italic: !current.isItalic);
  }

  void toggleUnderline() {
    final current = blocks[activeBlockIndex];

    _formatSelection(underline: !current.isUnderlined);
  }

  void toggleStrike() {
    final current = blocks[activeBlockIndex];

    _formatSelection(strike: !current.isStruckThrough);
  }

  // ------------------------------------------------------------
  // CHECKLIST
  // ------------------------------------------------------------

  void setChecklist() {
    if (blocks.isEmpty) return;

    _saveUndoState();

    final index = activeBlockIndex;

    final current = blocks[index];

    setState(() {
      blocks[index] = current.copyWith(
        type: current.type == NoteBlockType.checklist
            ? NoteBlockType.paragraph
            : NoteBlockType.checklist,
      );
    });
  }

  // ------------------------------------------------------------
  // NUMBERED LIST
  // ------------------------------------------------------------

  void setNumbered() {
    if (blocks.isEmpty) return;
    _saveUndoState();

    final index = activeBlockIndex;

    final current = blocks[index];

    setState(() {
      blocks[index] = current.copyWith(
        type: current.type == NoteBlockType.numbered
            ? NoteBlockType.paragraph
            : NoteBlockType.numbered,
      );
    });
  }

  // ------------------------------------------------------------
  // SPHERES
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // COLORS
  // ------------------------------------------------------------

  Future<void> selectColor() async {
    const colors = [
      0xFF16161A, // black
      0xFFFF3B30, // red
      0xFF007AFF, // blue
      0xFFFF9500, // orange
      0xFF34C759, // green
      0xFFAF52DE, // purple
      0xFFFF2D55, // pink
    ];

    final currentColor = blocks[activeBlockIndex].colorValue;

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
                      border: color == currentColor
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
      _formatSelection(color: result);
    }
  }

  Future<void> selectFont() async {
    const fonts = <String, String>{
      'sans': 'Обычный',
      'serif': 'С засечками',
      'monospace': 'Моноширинный',
    };
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Шрифт',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...fonts.entries.map(
                (entry) => ListTile(
                  title: Text(
                    entry.value,
                    style: TextStyle(
                      fontFamily: entry.key == 'sans' ? null : entry.key,
                    ),
                  ),
                  trailing: blocks[activeBlockIndex].fontFamily == entry.key
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, entry.key),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null) _formatSelection(fontFamily: result);
  }

  // ------------------------------------------------------------
  // STYLE
  // ------------------------------------------------------------

  TextStyle _blockStyle(NoteBlock block) {
    final decorations = <TextDecoration>[];

    if (block.isUnderlined) {
      decorations.add(TextDecoration.underline);
    }

    if (block.isStruckThrough) {
      decorations.add(TextDecoration.lineThrough);
    }

    return TextStyle(
      fontSize: 18,
      fontFamily: block.fontFamily == 'sans' ? null : block.fontFamily,
      color: Color(block.colorValue),
      fontWeight: block.isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: block.isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: decorations.isEmpty
          ? TextDecoration.none
          : TextDecoration.combine(decorations),
    );
  }

  // ------------------------------------------------------------
  // BLOCK UI
  // ------------------------------------------------------------

  Widget _buildBlock(BuildContext context, NoteBlock block, int index) {
    final field = Focus(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }

        if (event.logicalKey == LogicalKeyboardKey.backspace) {
          final controller = blockControllers[index];
          final selection = controller.selection;

          // Обрабатываем Backspace только когда курсор
          // стоит в самом начале блока.
          if (selection.isCollapsed && selection.baseOffset == 0) {
            // Первый блок удалять нельзя.
            if (index == 0) {
              return KeyEventResult.ignored;
            }

            // Если текущий блок пустой —
            // просто удаляем его.
            if (controller.text.isEmpty) {
              _handleBackspace(index);
              return KeyEventResult.handled;
            }

            // Если текст есть, объединяем его с предыдущим.
            final previousController = blockControllers[index - 1];

            final previousText = previousController.text;
            final currentText = controller.text;

            final previousBlock = blocks[index - 1];

            final newText = previousText + currentText;
            _saveUndoState();

            setState(() {
              blocks[index - 1] = previousBlock.copyWith(text: newText);

              blocks.removeAt(index);

              activeBlockIndex = index - 1;

              _createControllers();
            });

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              final controller = blockControllers[activeBlockIndex];

              controller.selection = TextSelection.collapsed(
                offset: previousText.length,
              );

              blockFocusNodes[activeBlockIndex].requestFocus();
            });

            return KeyEventResult.handled;
          }
        }

        if (event.logicalKey != LogicalKeyboardKey.enter) {
          return KeyEventResult.ignored;
        }

        final controller = blockControllers[index];
        final selection = controller.selection;

        // Если текст выделен — позволяем TextField
        // обработать обычный Enter.
        if (!selection.isCollapsed) {
          return KeyEventResult.ignored;
        }

        final cursor = selection.baseOffset;

        // Пустой пункт списка + Enter = выход из списка.
        if (controller.text.trim().isEmpty &&
            block.type != NoteBlockType.paragraph) {
          final newBlock = NoteBlock(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
          );

          setState(() {
            blocks[index] = block.copyWith(
              type: NoteBlockType.paragraph,
              isChecked: false,
              text: '',
            );

            blocks.insert(index + 1, newBlock);

            activeBlockIndex = index + 1;

            _createControllers();
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            blockFocusNodes[activeBlockIndex].requestFocus();
          });

          return KeyEventResult.handled;
        }

        // Разделяем текст по позиции курсора.
        final textBefore = controller.text.substring(0, cursor);
        final textAfter = controller.text.substring(cursor);

        final currentType = block.type;

        final newBlockType = currentType;

        // Создаём новый блок с тем же форматированием.
        final newBlock = block.copyWith(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          text: textAfter,
          type: newBlockType,
          isChecked: false,
        );

        setState(() {
          blocks[index] = block.copyWith(text: textBefore);

          blocks.insert(index + 1, newBlock);

          activeBlockIndex = index + 1;

          _createControllers();
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          if (activeBlockIndex >= blockControllers.length) {
            return;
          }

          final newController = blockControllers[activeBlockIndex];

          newController.selection = const TextSelection.collapsed(offset: 0);

          blockFocusNodes[activeBlockIndex].requestFocus();
        });

        return KeyEventResult.handled;
      },
      child: TextField(
        controller: blockControllers[index],
        focusNode: blockFocusNodes[index],
        style: _blockStyle(block),
        maxLines: null,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(
          hintText: index == 0 ? "Начните писать..." : null,
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
        ),
        onTap: () {
          activeBlockIndex = index;
        },
        onChanged: (_) {
          activeBlockIndex = index;
        },
      ),
    );

    if (block.type == NoteBlockType.checklist) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: block.isChecked,
            onChanged: (value) {
              setState(() {
                blocks[index] = block.copyWith(isChecked: value ?? false);
              });
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: field,
            ),
          ),
        ],
      );
    }

    if (block.type == NoteBlockType.numbered) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 9, right: 8),
            child: Text(
              "${_numberForBlock(index)}.",
              style: const TextStyle(fontSize: 18),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: field,
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: field,
    );
  }

  int _numberForBlock(int index) {
    var number = 1;

    for (var i = index - 1; i >= 0; i--) {
      if (blocks[i].type != NoteBlockType.numbered) {
        break;
      }

      number++;
    }

    return number;
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final activeBlock = blocks.isEmpty ? null : blocks[activeBlockIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Заметка"),
        actions: [
          IconButton(
            tooltip: "Отменить",
            onPressed: _undoStack.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo_rounded),
          ),

          const SizedBox(width: 4),

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
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: blocks.length,
                itemBuilder: (context, index) {
                  return _buildBlock(context, blocks[index], index);
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
        onFont: selectFont,
        onUndo: _undo,
        onRedo: _redo,

        boldActive: activeBlock?.isBold ?? false,
        italicActive: activeBlock?.isItalic ?? false,
        underlineActive: activeBlock?.isUnderlined ?? false,
        strikeActive: activeBlock?.isStruckThrough ?? false,
        undoAvailable: _undoStack.isNotEmpty,
        redoAvailable: _redoStack.isNotEmpty,
      ),
    );
  }
}
