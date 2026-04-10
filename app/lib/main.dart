import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'screens/planner_screen.dart';
import 'screens/wiki_screen.dart';
import 'screens/session_screen.dart';
import 'screens/needs_screen.dart';
import 'screens/factories_screen.dart';
import 'screens/scratch_screen.dart';
import 'screens/settings_screen.dart';

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
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _checking = true;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    _tryAutoSignIn();
  }

  Future<void> _tryAutoSignIn() async {
    final auth = ref.read(authServiceProvider);
    final ok = await auth.signInSilently();
    if (ok) {
      ref.read(notesProvider.notifier).reload();
    }
    setState(() {
      _signedIn = ok;
      _checking = false;
    });
  }

  Future<void> _signIn() async {
    setState(() => _checking = true);
    final auth = ref.read(authServiceProvider);
    final ok = await auth.signIn();
    if (ok) {
      ref.read(notesProvider.notifier).reload();
    }
    setState(() {
      _signedIn = ok;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: ficsitAmber)),
      );
    }

    if (!_signedIn) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'FICSIT',
                  style: TextStyle(
                    fontSize: 14,
                    color: ficsitAmber,
                    letterSpacing: 4,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Field Notes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _signIn,
                    icon: const Icon(Icons.login, size: 18),
                    label: const Text('Sign in with Google',
                        style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 15)),
                    style: FilledButton.styleFrom(
                      backgroundColor: ficsitAmber,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const AppShell();
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
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
    final auth = ref.read(authServiceProvider);

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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            color: const Color(0xFF6B7280),
            tooltip: 'Game settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 16),
          if (auth.isSignedIn)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: const Icon(Icons.logout, size: 18),
                color: const Color(0xFF9CA3AF),
                tooltip: 'Sign out',
                onPressed: () => _confirmLogout(context, auth),
              ),
            ),
        ],
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

  Future<void> _confirmLogout(BuildContext context, AuthService auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Sign out?',
            style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 16)),
        content: const Text(
          'Your notes are synced to the cloud. You can sign back in anytime.',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: ficsitAmber),
            child: const Text('Sign out',
                style: TextStyle(fontSize: 13, fontFamily: 'ShareTechMono')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (_) => false,
        );
      }
    }
  }
}
