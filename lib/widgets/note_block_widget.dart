import 'package:flutter/material.dart';
import '../models/note_block.dart';

class NoteBlockWidget extends StatelessWidget {
  final NoteBlock block;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onTapCheckbox;

  const NoteBlockWidget({
    super.key,
    required this.block,
    required this.controller,
    required this.onChanged,
    this.onTapCheckbox,
  });

  TextStyle get textStyle {
    TextDecoration? decoration;

    if (block.isUnderlined && block.isStruckThrough) {
      decoration = TextDecoration.combine([
        TextDecoration.underline,
        TextDecoration.lineThrough,
      ]);
    } else if (block.isUnderlined) {
      decoration = TextDecoration.underline;
    } else if (block.isStruckThrough) {
      decoration = TextDecoration.lineThrough;
    }

    double size = block.fontSize;

    if (block.type == NoteBlockType.heading1) {
      size = 30;
    }

    if (block.type == NoteBlockType.heading2) {
      size = 24;
    }

    return TextStyle(
      fontSize: size,
      color: Color(block.colorValue),
      fontWeight:
          block.isBold ||
              block.type == NoteBlockType.heading1 ||
              block.type == NoteBlockType.heading2
          ? FontWeight.bold
          : FontWeight.normal,
      fontStyle: block.isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: decoration,
      height: 1.45,
    );
  }

  Widget buildTextField() {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      style: textStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case NoteBlockType.checklist:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: block.isChecked,
              onChanged: (_) => onTapCheckbox?.call(),
            ),
            Expanded(child: buildTextField()),
          ],
        );

      case NoteBlockType.numbered:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                '1.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: buildTextField()),
          ],
        );

      case NoteBlockType.quote:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(width: 4, color: Color(0xFF8E8E93)),
            ),
          ),
          child: buildTextField(),
        );

      case NoteBlockType.code:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F1F3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: buildTextField(),
        );

      case NoteBlockType.divider:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(),
        );

      case NoteBlockType.image:
        return Container(
          height: 160,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.image_outlined, size: 40, color: Colors.grey),
        );

      case NoteBlockType.table:
        return Container(
          height: 100,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('Таблица'),
        );

      case NoteBlockType.drawing:
        return Container(
          height: 160,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.draw_outlined, size: 40, color: Colors.grey),
        );

      case NoteBlockType.audio:
        return Container(
          height: 60,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.play_circle_outline),
              SizedBox(width: 12),
              Text('Аудиозапись'),
            ],
          ),
        );

      case NoteBlockType.heading1:
      case NoteBlockType.heading2:
      case NoteBlockType.paragraph:
        return buildTextField();
    }
  }
}
