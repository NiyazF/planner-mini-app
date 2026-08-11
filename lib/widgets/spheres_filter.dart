import 'package:flutter/material.dart';
import '../models/life_sphere.dart';

class SpheresFilter extends StatelessWidget {
  final List<LifeSphere> spheres;
  final String? selectedId;
  final Function(String?) onChanged;

  const SpheresFilter({
    super.key,
    required this.spheres,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: [
          FilterChip(
            label: const Text("Все"),
            selected: selectedId == null,
            onSelected: (_) => onChanged(null),
          ),

          const SizedBox(width: 10),

          ...spheres.map(
            (sphere) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: FilterChip(
                avatar: Text(sphere.emoji),

                label: Text(sphere.name),

                selected: selectedId == sphere.id,

                selectedColor: Color(sphere.color).withOpacity(.15),

                onSelected: (_) {
                  if (selectedId == sphere.id) {
                    onChanged(null);
                  } else {
                    onChanged(sphere.id);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
