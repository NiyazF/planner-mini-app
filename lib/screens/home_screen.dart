import 'package:flutter/material.dart';
import 'calendar_screen.dart';
import 'notes_screen.dart';
import 'supplement_tracker_button.dart';

void openSupplementTracker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const SupplementTrackerSheet(),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final screens = const [CalendarScreen(), NotesScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          // Если нажата 3-я иконка ("Прием") — открываем таблицу поверх экрана
          if (index == 2) {
            openSupplementTracker(context);
            return; // Выходим, чтобы не менять currentIndex
          }

          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: "Календарь",
          ),
          NavigationDestination(
            icon: Icon(Icons.note_alt_outlined),
            label: "Заметки",
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_rtl_rounded),
            label: "Прием",
          ),
        ],
      ),
    );
  }
}
