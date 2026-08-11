import 'package:flutter/material.dart';

class NoteToolbar extends StatelessWidget {
  final VoidCallback onSphere;
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onUnderline;
  final VoidCallback onStrike;
  final VoidCallback onColor;
  final VoidCallback onChecklist;
  final VoidCallback onNumbers;

  final bool boldActive;
  final bool italicActive;
  final bool underlineActive;
  final bool strikeActive;

  const NoteToolbar({
    super.key,
    required this.onSphere,
    required this.onBold,
    required this.onItalic,
    required this.onUnderline,
    required this.onStrike,
    required this.onColor,
    required this.onChecklist,
    required this.onNumbers,
    this.boldActive = false,
    this.italicActive = false,
    this.underlineActive = false,
    this.strikeActive = false,
  });

  Widget _button({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    bool active = false,
  }) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: active
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: null,
        splashRadius: 22,
        icon: Icon(
          icon,
          size: 21,
          color: active
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.10),
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _button(
                  context: context,
                  icon: Icons.blur_circular_outlined,
                  onPressed: onSphere,
                ),

                const SizedBox(width: 4),

                Container(
                  width: 1,
                  height: 25,
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.15),
                ),

                const SizedBox(width: 4),

                _button(
                  context: context,
                  icon: Icons.format_bold,
                  onPressed: onBold,
                  active: boldActive,
                ),

                _button(
                  context: context,
                  icon: Icons.format_italic,
                  onPressed: onItalic,
                  active: italicActive,
                ),

                _button(
                  context: context,
                  icon: Icons.format_underlined,
                  onPressed: onUnderline,
                  active: underlineActive,
                ),

                _button(
                  context: context,
                  icon: Icons.format_strikethrough,
                  onPressed: onStrike,
                  active: strikeActive,
                ),

                const SizedBox(width: 4),

                Container(
                  width: 1,
                  height: 25,
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.15),
                ),

                const SizedBox(width: 4),

                _button(
                  context: context,
                  icon: Icons.checklist_rounded,
                  onPressed: onChecklist,
                ),

                _button(
                  context: context,
                  icon: Icons.format_list_numbered_rounded,
                  onPressed: onNumbers,
                ),

                _button(
                  context: context,
                  icon: Icons.palette_outlined,
                  onPressed: onColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
