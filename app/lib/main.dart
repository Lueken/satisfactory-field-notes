import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/planner_screen.dart';
import 'screens/wiki_screen.dart';
import 'screens/session_screen.dart';
import 'screens/needs_screen.dart';
import 'screens/factories_screen.dart';
import 'screens/scratch_screen.dart';

void main() {
  runApp(const ProviderScope(child: FieldNotesApp()));
}

class FieldNotesApp extends StatelessWidget {
  const FieldNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FICSIT Field Notes',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  static const _screens = [
    SessionScreen(),
    NeedsScreen(),
    FactoriesScreen(),
    PlannerScreen(),
    WikiScreen(),
    ScratchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'FICSIT',
              style: TextStyle(
                fontSize: 10,
                color: ficsitAmber,
                letterSpacing: 3,
                fontFamily: 'ShareTechMono',
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Field Notes',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                fontFamily: 'ShareTechMono',
              ),
            ),
          ],
        ),
        toolbarHeight: 48,
      ),
      body: _screens[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        height: 64,
        indicatorColor: ficsitAmber.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Session'),
          NavigationDestination(icon: Icon(Icons.warning_amber_outlined), selectedIcon: Icon(Icons.warning_amber), label: 'Needs'),
          NavigationDestination(icon: Icon(Icons.factory_outlined), selectedIcon: Icon(Icons.factory), label: 'Factories'),
          NavigationDestination(icon: Icon(Icons.account_tree_outlined), selectedIcon: Icon(Icons.account_tree), label: 'Planner'),
          NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Wiki'),
          NavigationDestination(icon: Icon(Icons.edit_note_outlined), selectedIcon: Icon(Icons.edit_note), label: 'Scratch'),
        ],
      ),
    );
  }
}
