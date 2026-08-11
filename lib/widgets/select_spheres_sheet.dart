import 'package:flutter/material.dart';
import '../models/life_sphere.dart';
import '../services/life_sphere_storage.dart';
import 'create_sphere_sheet.dart';

class SelectSpheresSheet extends StatefulWidget {
  final List<String> selected;

  const SelectSpheresSheet({super.key, required this.selected});

  @override
  State<SelectSpheresSheet> createState() => _SelectSpheresSheetState();
}

class _SelectSpheresSheetState extends State<SelectSpheresSheet> {
  List<LifeSphere> spheres = [];

  late List<String> selectedIds;

  @override
  void initState() {
    super.initState();

    selectedIds = List.from(widget.selected);

    load();
  }

  Future<void> load() async {
    final loadedSpheres = await LifeSphereStorage.load();

    if (!mounted) return;

    setState(() {
      spheres = loadedSpheres;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xffF7F7FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),

        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Сферы жизни",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 20),

              ...spheres.map(buildSphere),

              const SizedBox(height: 12),

              FilledButton.icon(
                onPressed: () async {
                  final sphere = await showModalBottomSheet<LifeSphere>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const CreateSphereSheet(),
                  );

                  if (sphere != null) {
                    spheres.add(sphere);

                    await LifeSphereStorage.save(spheres);

                    setState(() {});
                  }
                },

                icon: const Icon(Icons.add),

                label: const Text("Создать сферу"),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,

                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context, selectedIds);
                  },

                  child: const Text("Готово"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSphere(LifeSphere sphere) {
    final selected = selectedIds.contains(sphere.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),

      child: InkWell(
        borderRadius: BorderRadius.circular(18),

        onTap: () {
          setState(() {
            if (selected) {
              selectedIds.remove(sphere.id);
            } else {
              selectedIds.add(sphere.id);
            }
          });
        },

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),

          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(18),

            border: Border.all(
              color: selected ? Color(sphere.color) : Colors.transparent,
              width: 2,
            ),
          ),

          child: Row(
            children: [
              Text(sphere.emoji, style: const TextStyle(fontSize: 24)),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  sphere.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              AnimatedContainer(
                duration: const Duration(milliseconds: 180),

                width: 26,
                height: 26,

                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? Color(sphere.color) : Colors.grey.shade300,
                ),

                child: selected
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
