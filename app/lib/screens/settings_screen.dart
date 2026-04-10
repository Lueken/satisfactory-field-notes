import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final colors = AppColors.of(context);

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
              _SectionLabel('APPEARANCE'),
              const SizedBox(height: 8),
              _ToggleRow(
                label: 'Dark mode',
                subtitle: 'Easier on pioneer eyes at night',
                value: settings.darkMode,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  ref.read(settingsProvider.notifier).setDarkMode(v);
                },
              ),

              const SizedBox(height: 24),
              _SectionLabel('MODIFIERS'),
              const SizedBox(height: 8),
              _ToggleRow(
                label: 'Overclocking',
                subtitle: 'Allow overclock adjustments',
                value: settings.overclockingEnabled,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  ref
                      .read(settingsProvider.notifier)
                      .setOverclocking(v);
                },
              ),
              const SizedBox(height: 8),
              _ToggleRow(
                label: 'Somersloop',
                subtitle: '2x production, higher power',
                value: settings.somersloopEnabled,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  ref.read(settingsProvider.notifier).setSomersloop(v);
                },
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

              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _search = val),
                style: TextStyle(fontSize: 14, color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search alternates...',
                  hintStyle: TextStyle(color: colors.textTertiary),
                  prefixIcon:
                      Icon(Icons.search, size: 18, color: colors.textTertiary),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),

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
                        side: BorderSide(
                            color: colors.borderSecondary, width: 0.5),
                      ),
                      child: Text('Unlock all',
                          style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'ShareTechMono',
                              color: colors.textSecondary)),
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
                        side: BorderSide(
                            color: colors.borderSecondary, width: 0.5),
                      ),
                      child: Text('Clear all',
                          style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'ShareTechMono',
                              color: colors.textSecondary)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

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
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: colors.textTertiary,
        letterSpacing: 1.5,
      ),
    );
  }
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
    final colors = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Text(label,
              style: TextStyle(fontSize: 14, color: colors.textPrimary)),
        ),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<int>(
            initialValue: value,
            isDense: true,
            decoration: const InputDecoration(isDense: true),
            style: TextStyle(fontSize: 14, color: colors.textPrimary, fontFamily: 'ShareTechMono'),
            dropdownColor: colors.bgSecondary,
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
    final colors = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      TextStyle(fontSize: 14, color: colors.textPrimary)),
              Text(subtitle,
                  style:
                      TextStyle(fontSize: 12, color: colors.textTertiary)),
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
    final cleanName = recipe.name.replaceFirst(RegExp(r'^Alternate:\s*'), '');
    final colors = AppColors.of(context);

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
                      style: TextStyle(
                          fontSize: 13, color: colors.textPrimary)),
                  Text(
                    recipe.products
                        .map((p) => p.item
                            .replaceAll('Desc_', '')
                            .replaceAll('_C', ''))
                        .join(', '),
                    style:
                        TextStyle(fontSize: 11, color: colors.textTertiary),
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
