import 'package:flutter/material.dart';
import '../models/wiki_result.dart';
import '../theme/app_theme.dart';

class RecipeCard extends StatelessWidget {
  final WikiRecipe recipe;
  final bool compact;

  const RecipeCard({super.key, required this.recipe, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    if (compact) return _buildCompact(colors);

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              'Recipe',
              if (recipe.building != null) '— ${recipe.building}',
              if (recipe.time != null) '· ${recipe.time}',
            ].join(' '),
            style: TextStyle(
              fontSize: 11,
              color: colors.textTertiary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          if (recipe.inputs.isNotEmpty) ...[
            Text('INPUTS',
                style: TextStyle(
                    fontSize: 11,
                    color: colors.textTertiary,
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            for (final inp in recipe.inputs)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${inp.amount} × ${inp.name}',
                        style: TextStyle(
                            fontSize: 14, color: colors.textPrimary)),
                    if (inp.perMin.isNotEmpty)
                      Text(inp.perMin,
                          style: TextStyle(
                              fontSize: 12, color: colors.textTertiary)),
                  ],
                ),
              ),
            const SizedBox(height: 10),
          ],
          if (recipe.outputs.isNotEmpty) ...[
            Text('OUTPUTS',
                style: TextStyle(
                    fontSize: 11,
                    color: colors.textTertiary,
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            for (final out in recipe.outputs)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${out.amount} × ${out.name}',
                        style: const TextStyle(
                            fontSize: 14, color: ficsitAmber)),
                    if (out.perMin.isNotEmpty)
                      Text(out.perMin,
                          style: TextStyle(
                              fontSize: 12, color: colors.textTertiary)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompact(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(recipe.name.isNotEmpty ? recipe.name : 'Alternate',
              style: TextStyle(fontSize: 13, color: colors.textPrimary)),
          if (recipe.inputs.isNotEmpty)
            Text(
              recipe.inputs.map((i) => '${i.amount} × ${i.name}').join(', '),
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          if (recipe.outputs.isNotEmpty)
            Text(
              '→ ${recipe.outputs.map((o) => '${o.amount} × ${o.name}').join(', ')}',
              style: const TextStyle(fontSize: 12, color: ficsitAmber),
            ),
          if (recipe.building != null)
            Text(
              '${recipe.building}${recipe.time != null ? ' · ${recipe.time}' : ''}',
              style: TextStyle(fontSize: 11, color: colors.textTertiary),
            ),
        ],
      ),
    );
  }
}
