import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_data.dart';
import '../services/game_data_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class AlternatesScreen extends ConsumerStatefulWidget {
  const AlternatesScreen({super.key});

  @override
  ConsumerState<AlternatesScreen> createState() => _AlternatesScreenState();
}

class _AlternatesScreenState extends ConsumerState<AlternatesScreen> {
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
        title: const Text('Alternate Recipes',
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

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Check the alternates you have unlocked. The planner will use them as default recipes when simpler.',
                            style: TextStyle(
                                fontSize: 12,
                                color: colors.textTertiary,
                                height: 1.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${settings.unlockedAlternates.length} / ${alternates.length}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: ficsitAmber,
                              fontFamily: 'ShareTechMono',
                              letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _search = val),
                      style:
                          TextStyle(fontSize: 14, color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search alternates...',
                        hintStyle: TextStyle(color: colors.textTertiary),
                        prefixIcon: Icon(Icons.search,
                            size: 18, color: colors.textTertiary),
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
                                .setAllAlternates(alternates
                                    .map((r) => r.className)
                                    .toSet()),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
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
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final recipe = filtered[i];
                    return _AlternateRow(
                      recipe: recipe,
                      checked: settings.unlockedAlternates
                          .contains(recipe.className),
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .toggleAlternate(recipe.className),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
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
