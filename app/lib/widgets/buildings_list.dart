import 'package:flutter/material.dart';
import '../models/production_node.dart';
import '../theme/app_theme.dart';

String _fmtPower(double mw) =>
    mw == mw.roundToDouble() ? mw.toStringAsFixed(0) : mw.toStringAsFixed(1);

class BuildingsList extends StatelessWidget {
  final ProductionNode root;

  const BuildingsList({super.key, required this.root});

  @override
  Widget build(BuildContext context) {
    final buildings = root.buildingsList;
    final totalPower = root.totalTreePower;

    if (buildings.isEmpty) {
      return const Center(
        child: Text(
          'Only raw resources needed.',
          style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Total power header
        if (totalPower > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: ficsitAmber.withValues(alpha: 0.08),
              border: const Border(
                bottom: BorderSide(color: Color(0xFFE7E5E4), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, size: 18, color: ficsitAmber),
                const SizedBox(width: 6),
                Text(
                  '${_fmtPower(totalPower)} MW total',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ficsitAmber,
                  ),
                ),
              ],
            ),
          ),

        // Building rows
        for (final b in buildings)
          Container(
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
                    'x${b.count.ceil()}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: ficsitAmber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    b.name,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                if (b.powerEach > 0)
                  Text(
                    '${_fmtPower(b.powerEach * b.count)} MW',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
