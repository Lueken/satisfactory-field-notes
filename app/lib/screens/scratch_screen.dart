import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

class ScratchScreen extends ConsumerWidget {
  const ScratchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SCRATCH PAD',
              style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
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
              style: const TextStyle(fontSize: 15, height: 1.6),
              decoration: const InputDecoration(
                hintText: 'ratios, counts, half-formed plans...',
                hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE7E5E4), width: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerRight,
            child: Text('saves automatically',
                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          ),
        ],
      ),
    );
  }
}
