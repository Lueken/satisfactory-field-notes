import 'package:flutter/material.dart';
import '../models/production_node.dart';
import '../theme/app_theme.dart';

class BuildingsList extends StatelessWidget {
  final ProductionNode root;

  const BuildingsList({super.key, required this.root});

  @override
  Widget build(BuildContext context) {
    final buildings = root.buildingsList;

    if (buildings.isEmpty) {
      return const Center(
        child: Text(
          'Only raw resources needed.',
          style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: buildings.length,
      itemBuilder: (context, i) {
        final b = buildings[i];
        final count = b.count;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE7E5E4), width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ficsitAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'x${count.ceil()}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: ficsitAmber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                b.name,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
