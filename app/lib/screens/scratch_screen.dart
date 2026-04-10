import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class ScratchScreen extends ConsumerWidget {
  const ScratchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SCRATCH PAD',
              style: TextStyle(
                  fontSize: 11,
                  color: colors.textTertiary,
                  letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: notes.scratch),
              onChanged: (val) =>
                  ref.read(notesProvider.notifier).updateScratch(val),
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(
                  fontSize: 15, height: 1.6, color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'ratios, counts, half-formed plans...',
                hintStyle: TextStyle(color: colors.textTertiary),
                border: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: colors.borderSecondary, width: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text('saves automatically',
                style: TextStyle(fontSize: 11, color: colors.textTertiary)),
          ),
        ],
      ),
    );
  }
}
