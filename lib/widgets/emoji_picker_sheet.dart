import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class EmojiPickerSheet extends StatelessWidget {
  final Function(String) onSelected;

  const EmojiPickerSheet({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 420,
        child: EmojiPicker(
          onEmojiSelected: (_, emoji) {
            onSelected(emoji.emoji);
            Navigator.pop(context);
          },
          config: const Config(height: 420, checkPlatformCompatibility: true),
        ),
      ),
    );
  }
}
