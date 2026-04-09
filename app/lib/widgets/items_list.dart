import 'package:flutter/material.dart';
import '../models/game_data.dart';
import '../models/production_node.dart';
import '../theme/app_theme.dart';

class ItemsList extends StatelessWidget {
  final ProductionNode root;
  final GameData gameData;

  const ItemsList({super.key, required this.root, required this.gameData});

  @override
  Widget build(BuildContext context) {
    final items = root.flatItems();
    final sorted = items.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final entry = sorted[i];
        final name = gameData.itemName(entry.key);
        final rate = entry.value;
        final isRaw = gameData.defaultRecipeFor(entry.key) == null;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE7E5E4), width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    color: isRaw ? ficsitAmber : const Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Text(
                '${rate.toStringAsFixed(rate == rate.roundToDouble() ? 0 : 1)} /min',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
