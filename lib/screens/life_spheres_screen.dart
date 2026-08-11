import 'package:flutter/material.dart';

import '../models/life_sphere.dart';
import '../services/life_sphere_storage.dart';
import '../widgets/create_sphere_sheet.dart';

class LifeSpheresScreen extends StatefulWidget {
  const LifeSpheresScreen({super.key});

  @override
  State<LifeSpheresScreen> createState() => _LifeSpheresScreenState();
}

class _LifeSpheresScreenState extends State<LifeSpheresScreen> {
  List<LifeSphere> spheres = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    spheres = await LifeSphereStorage.load();

    setState(() {});
  }

  Future<void> addSphere() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Сферы жизни")),

      floatingActionButton: FloatingActionButton(
        onPressed: addSphere,
        child: const Icon(Icons.add),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(18),

        itemCount: spheres.length,

        itemBuilder: (context, index) {
          final sphere = spheres[index];

          return Dismissible(
            key: ValueKey(sphere.id),

            background: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.only(left: 20),

              alignment: Alignment.centerLeft,

              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(18),
              ),

              child: const Row(
                children: [
                  Icon(Icons.edit, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    "Изменить",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            secondaryBackground: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.only(right: 20),

              alignment: Alignment.centerRight,

              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(18),
              ),

              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Удалить",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.delete, color: Colors.white),
                ],
              ),
            ),

            confirmDismiss: (direction) async {
              if (direction == DismissDirection.endToStart) {
                spheres.removeAt(index);

                await LifeSphereStorage.save(spheres);

                setState(() {});

                return true;
              }

              if (direction == DismissDirection.startToEnd) {
                // позже откроем редактирование

                final edited = await showModalBottomSheet<LifeSphere>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => CreateSphereSheet(sphere: sphere),
                );

                if (edited != null) {
                  spheres[index] = edited;

                  await LifeSphereStorage.save(spheres);

                  setState(() {});
                }

                return false;
              }

              return false;
            },

            child: Card(
              margin: const EdgeInsets.only(bottom: 14),

              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(sphere.color),

                  child: Text(
                    sphere.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),

                title: Text(
                  sphere.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
