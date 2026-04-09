import 'package:flutter/material.dart';
import '../models/wiki_result.dart';
import '../theme/app_theme.dart';

class RecipeCard extends StatelessWidget {
  final WikiRecipe recipe;
  final bool compact;

  const RecipeCard({super.key, required this.recipe, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F4),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            [
              'Recipe',
              if (recipe.building != null) '— ${recipe.building}',
              if (recipe.time != null) '· ${recipe.time}',
            ].join(' '),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),

          // Inputs
          if (recipe.inputs.isNotEmpty) ...[
            const Text('INPUTS',
                style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            for (final inp in recipe.inputs)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${inp.amount} × ${inp.name}',
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF1A1A1A))),
                    if (inp.perMin.isNotEmpty)
                      Text(inp.perMin,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
            const SizedBox(height: 10),
          ],

          // Outputs
          if (recipe.outputs.isNotEmpty) ...[
            const Text('OUTPUTS',
                style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
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
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompact() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(recipe.name.isNotEmpty ? recipe.name : 'Alternate',
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF1A1A1A))),
          if (recipe.inputs.isNotEmpty)
            Text(
              recipe.inputs.map((i) => '${i.amount} × ${i.name}').join(', '),
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          if (recipe.outputs.isNotEmpty)
            Text(
              '→ ${recipe.outputs.map((o) => '${o.amount} × ${o.name}').join(', ')}',
              style: const TextStyle(fontSize: 12, color: ficsitAmber),
            ),
          if (recipe.building != null)
            Text(
              '${recipe.building}${recipe.time != null ? ' · ${recipe.time}' : ''}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
        ],
      ),
    );
  }
}
