import 'package:flutter/material.dart';

class NoteActionsSheet extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onFolder;
  final VoidCallback onSphere;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const NoteActionsSheet({
    super.key,
    required this.onEdit,
    required this.onFolder,
    required this.onSphere,
    required this.onDuplicate,
    required this.onDelete,
  });

  Widget item(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 15, bottom: 20),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 20),

            item(Icons.edit_outlined, "Редактировать", onEdit),

            item(Icons.folder_copy_outlined, "Переместить в группу", onFolder),

            item(Icons.blur_circular, "Изменить сферу", onSphere),

            item(Icons.copy_outlined, "Создать копию", onDuplicate),

            const Divider(),

            item(Icons.delete_outline, "Удалить", onDelete, color: Colors.red),
          ],
        ),
      ),
    );
  }
}
