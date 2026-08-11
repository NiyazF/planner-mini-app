import 'package:flutter/material.dart';

enum NotesSort { updated, created, title }

class SortNotesSheet extends StatelessWidget {
  final NotesSort current;
  final Function(NotesSort) onSelected;

  const SortNotesSheet({
    super.key,
    required this.current,
    required this.onSelected,
  });

  Widget tile(
    BuildContext context,
    NotesSort value,
    IconData icon,
    String text,
  ) {
    return ListTile(
      leading: Icon(icon),

      title: Text(text),

      trailing: current == value
          ? const Icon(Icons.check_circle, color: Colors.indigo)
          : null,

      onTap: () {
        onSelected(value);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 25),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Text(
              "Сортировка",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            tile(context, NotesSort.updated, Icons.update, "По дате изменения"),

            tile(
              context,
              NotesSort.created,
              Icons.calendar_today,
              "По дате создания",
            ),

            tile(context, NotesSort.title, Icons.sort_by_alpha, "По названию"),
          ],
        ),
      ),
    );
  }
}
