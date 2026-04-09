import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class NeedsScreen extends ConsumerStatefulWidget {
  const NeedsScreen({super.key});

  @override
  ConsumerState<NeedsScreen> createState() => _NeedsScreenState();
}

class _NeedsScreenState extends ConsumerState<NeedsScreen> {
  final _controller = TextEditingController();

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(notesProvider.notifier).addNeed(text);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);
    final needs = notes.needs;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('STUFF YOU STILL NEED',
              style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                  letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _add(),
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'e.g. screw sub-factory',
                    hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _add,
                  style: FilledButton.styleFrom(
                    backgroundColor: ficsitAmber,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Add',
                      style: TextStyle(fontFamily: 'ShareTechMono')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: needs.isEmpty
                ? const Center(
                    child: Text('Nothing queued up.',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))))
                : ListView.builder(
                    itemCount: needs.length,
                    itemBuilder: (context, i) {
                      final need = needs[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Color(0xFFE7E5E4), width: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('▸ ',
                                style: TextStyle(
                                    fontSize: 16, color: ficsitAmber)),
                            Expanded(
                              child: Text(need.text,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF1A1A1A))),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              color: const Color(0xFF9CA3AF),
                              onPressed: () => ref
                                  .read(notesProvider.notifier)
                                  .deleteNeed(need.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
