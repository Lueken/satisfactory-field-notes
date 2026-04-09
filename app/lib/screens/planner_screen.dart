import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_data_service.dart';
import '../widgets/item_search.dart';
import '../theme/app_theme.dart';

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameData = ref.watch(gameDataProvider);

    return gameData.when(
      loading: () => const Center(child: CircularProgressIndicator(color: ficsitAmber)),
      error: (e, _) => Center(child: Text('Failed to load game data: $e')),
      data: (data) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PRODUCTION PLANNER',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF9CA3AF),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            ItemSearch(
              items: data.searchableItems,
              onSelected: (item) {
                // Phase 2: hook up planner engine
              },
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${data.items.length} items loaded',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.recipes.length} recipes indexed',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.recipesByProduct.length} producible items',
                      style: const TextStyle(fontSize: 14, color: ficsitAmber),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
