import 'package:flutter/material.dart';

import '../models/note.dart';
import '../models/life_sphere.dart';
import '../services/life_sphere_storage.dart';

class NoteCard extends StatefulWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  List<LifeSphere> spheres = [];

  @override
  void initState() {
    super.initState();
    loadSpheres();
  }

  Future<void> loadSpheres() async {
    spheres = await LifeSphereStorage.load();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;

    final noteSpheres = spheres
        .where((sphere) => note.sphereIds.contains(sphere.id))
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title.isEmpty ? "Без названия" : note.title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              if (note.content.isNotEmpty)
                Text(
                  note.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Icon(Icons.schedule, color: Colors.grey.shade500, size: 18),

                  const SizedBox(width: 6),

                  Text(
                    "${note.updatedAt.day.toString().padLeft(2, '0')}.${note.updatedAt.month.toString().padLeft(2, '0')}.${note.updatedAt.year}",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const Spacer(),
                ],
              ),
              if (noteSpheres.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: noteSpheres.map((sphere) {
                    final color = Color(sphere.color);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${sphere.emoji} ${sphere.name}',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
