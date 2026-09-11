// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'emoji_picker_sheet.dart';
import '../models/life_sphere.dart';

class CreateSphereSheet extends StatefulWidget {
  final LifeSphere? sphere;

  const CreateSphereSheet({super.key, this.sphere});

  @override
  State<CreateSphereSheet> createState() => _CreateSphereSheetState();
}

class _CreateSphereSheetState extends State<CreateSphereSheet> {
  final controller = TextEditingController();

  String emoji = "😊";

  int color = Colors.blue.value;

  final colors = [
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.green,
    Colors.teal,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.brown,
  ];

  final emojis = [
    "❤️",
    "💰",
    "💼",
    "🏃",
    "📚",
    "🏡",
    "🎮",
    "✈️",
    "🎵",
    "🍔",
    "🚗",
    "🐶",
    "⭐",
    "😊",
    "🌙",
    "🔥",
  ];
  @override
  void initState() {
    super.initState();

    if (widget.sphere != null) {
      controller.text = widget.sphere!.name;
      emoji = widget.sphere!.emoji;
      color = widget.sphere!.color;
    }
    controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              Text(
                widget.sphere == null ? "Новая сфера" : "Редактировать сферу",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 25),

              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: "Название"),
              ),

              const SizedBox(height: 25),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Эмодзи",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: GestureDetector(
                  onTap: () async {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) {
                        return EmojiPickerSheet(
                          onSelected: (value) {
                            setState(() {
                              emoji = value;
                            });
                          },
                        );
                      },
                    );
                  },

                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),

                    width: 90,
                    height: 90,

                    alignment: Alignment.center,

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),

                    child: Text(emoji, style: const TextStyle(fontSize: 46)),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Цвет",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 35),

              const Divider(),

              const SizedBox(height: 25),

              const Text(
                "Предпросмотр",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Color(color),

                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),

                    const SizedBox(width: 18),

                    Expanded(
                      child: Text(
                        controller.text.isEmpty
                            ? "Название сферы"
                            : controller.text,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: colors.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),

                  itemBuilder: (context, index) {
                    final c = colors[index];

                    final selected = c.value == color;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          color = c.value;
                        });
                      },

                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),

                        width: selected ? 62 : 54,
                        height: selected ? 62 : 54,

                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(18),

                          boxShadow: [
                            BoxShadow(
                              color: c.withOpacity(.35),
                              blurRadius: selected ? 18 : 8,
                              offset: const Offset(0, 6),
                            ),
                          ],

                          border: Border.all(
                            color: selected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                        ),

                        child: selected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 35),

              SizedBox(
                width: double.infinity,

                child: FilledButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;

                    Navigator.pop(
                      context,
                      LifeSphere(
                        id:
                            widget.sphere?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        name: controller.text.trim(),
                        emoji: emoji,
                        color: color,
                      ),
                    );
                  },

                  child: Text(widget.sphere == null ? "Создать" : "Сохранить"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
