import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_data.dart';
import '../services/game_data_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final gameData = ref.watch(gameDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Settings',
            style: TextStyle(fontSize: 16, fontFamily: 'ShareTechMono')),
        toolbarHeight: 48,
      ),
      body: gameData.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: ficsitAmber)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final alternates = data.recipes.values
              .where((r) => r.alternate && r.inMachine && !r.forBuilding)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

          final filtered = _search.isEmpty
              ? alternates
              : alternates
                  .where((r) =>
                      r.name.toLowerCase().contains(_search.toLowerCase()))
                  .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionLabel('GAME TIER'),
              const SizedBox(height: 8),
              _TierSelector(
                label: 'Belt tier',
                value: settings.beltTier,
                options: const [1, 2, 3, 4, 5, 6],
                labels: const ['Mk.1 (60)', 'Mk.2 (120)', 'Mk.3 (270)', 'Mk.4 (480)', 'Mk.5 (780)', 'Mk.6 (1200)'],
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setBeltTier(v),
              ),
              const SizedBox(height: 10),
              _TierSelector(
                label: 'Miner tier',
                value: settings.minerTier,
                options: const [1, 2, 3],
                labels: const ['Mk.1', 'Mk.2', 'Mk.3'],
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setMinerTier(v),
              ),

              const SizedBox(height: 24),
              _SectionLabel('MODIFIERS'),
              const SizedBox(height: 8),
              _ToggleRow(
                label: 'Overclocking',
                subtitle: 'Allow overclock adjustments',
                value: settings.overclockingEnabled,
                onChanged: (v) => ref
                    .read(settingsProvider.notifier)
                    .setOverclocking(v),
              ),
              const SizedBox(height: 8),
              _ToggleRow(
                label: 'Somersloop',
                subtitle: '2x production, higher power',
                value: settings.somersloopEnabled,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setSomersloop(v),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  _SectionLabel('ALTERNATE RECIPES'),
                  const SizedBox(width: 8),
                  Text(
                    '${settings.unlockedAlternates.length} / ${alternates.length}',
                    style: const TextStyle(
                        fontSize: 11, color: ficsitAmber, letterSpacing: 1),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Search bar
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _search = val),
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search alternates...',
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                  prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),

              // Select all / clear buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ref
                          .read(settingsProvider.notifier)
                          .setAllAlternates(
                              alternates.map((r) => r.className).toSet()),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(
                            color: Color(0xFFE7E5E4), width: 0.5),
                      ),
                      child: const Text('Unlock all',
                          style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'ShareTechMono',
                              color: Color(0xFF6B7280))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ref
                          .read(settingsProvider.notifier)
                          .setAllAlternates({}),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(
                            color: Color(0xFFE7E5E4), width: 0.5),
                      ),
                      child: const Text('Clear all',
                          style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'ShareTechMono',
                              color: Color(0xFF6B7280))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Alternate recipes list
              for (final recipe in filtered)
                _AlternateRow(
                  recipe: recipe,
                  checked: settings.unlockedAlternates.contains(recipe.className),
                  onTap: () => ref
                      .read(settingsProvider.notifier)
                      .toggleAlternate(recipe.className),
                ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF9CA3AF),
          letterSpacing: 1.5,
        ),
      );
}

class _TierSelector extends StatelessWidget {
  final String label;
  final int value;
  final List<int> options;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  const _TierSelector({
    required this.label,
    required this.value,
    required this.options,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Text(label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A))),
        ),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<int>(
            initialValue: value,
            isDense: true,
            decoration: const InputDecoration(isDense: true),
            items: [
              for (var i = 0; i < options.length; i++)
                DropdownMenuItem(value: options[i], child: Text(labels[i])),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF1A1A1A))),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9CA3AF))),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: ficsitAmber,
        ),
      ],
    );
  }
}

class _AlternateRow extends StatelessWidget {
  final GameRecipe recipe;
  final bool checked;
  final VoidCallback onTap;

  const _AlternateRow({
    required this.recipe,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Clean up the name: "Alternate: Pure Iron Ingot" -> "Pure Iron Ingot"
    final cleanName = recipe.name.replaceFirst(RegExp(r'^Alternate:\s*'), '');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Checkbox(
              value: checked,
              onChanged: (_) => onTap(),
              activeColor: ficsitAmber,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cleanName,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF1A1A1A))),
                  Text(
                    recipe.products.map((p) => p.item.replaceAll('Desc_', '').replaceAll('_C', '')).join(', '),
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
