import 'package:flutter/material.dart';
import 'budget_screen.dart';
import 'calendar_screen.dart';
import 'dashboard_screen.dart';
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
  final GlobalKey<DashboardScreenState> _dashboardKey =
      GlobalKey<DashboardScreenState>();

  void _selectTab(int index) {
    // 5-я иконка ("Прием") открывает шторку поверх текущего экрана
    if (index == 4) {
      openSupplementTracker(context);
      return;
    }

    setState(() {
      currentIndex = index;
    });

    // Обновляем данные при каждом возврате на главный экран
    if (index == 0) {
      _dashboardKey.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        key: _dashboardKey,
        onOpenBudget: () => _selectTab(3),
        onOpenCalendar: () => _selectTab(1),
        onOpenNotes: () => _selectTab(2),
      ),
      const CalendarScreen(),
      const NotesScreen(),
      const BudgetScreen(),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: "Главная",
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: "Календарь",
          ),
          NavigationDestination(
            icon: Icon(Icons.note_alt_outlined),
            selectedIcon: Icon(Icons.note_alt),
            label: "Заметки",
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: "Бюджет",
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
