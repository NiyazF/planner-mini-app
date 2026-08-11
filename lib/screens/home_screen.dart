import 'package:flutter/material.dart';
import 'calendar_screen.dart';
import 'notes_screen.dart';

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
        ],
      ),
    );
  }
}
