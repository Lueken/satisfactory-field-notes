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
    final colors = AppColors.of(context);

    if (buildings.isEmpty) {
      return Center(
        child: Text(
          'Only raw resources needed.',
          style: TextStyle(fontSize: 13, color: colors.textTertiary),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        if (totalPower > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: ficsitAmber.withValues(alpha: 0.08),
              border: Border(
                bottom: BorderSide(color: colors.borderSecondary, width: 0.5),
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
        for (final b in buildings)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.borderSecondary, width: 0.5),
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
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (b.powerEach > 0)
                  Text(
                    '${_fmtPower(b.powerEach * b.count)} MW',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
