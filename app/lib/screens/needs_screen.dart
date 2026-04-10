import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

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
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STUFF YOU STILL NEED',
              style: TextStyle(
                  fontSize: 11,
                  color: colors.textTertiary,
                  letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _add(),
                  style: TextStyle(fontSize: 16, color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. screw sub-factory',
                    hintStyle: TextStyle(color: colors.textTertiary),
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
                ? const EmptyState(
                    icon: Icons.warning_amber,
                    title: 'Your hunt list is empty',
                    subtitle:
                        'Jot down the stuff you need to build, find, or unlock. Future-you will thank you.',
                    hint: 'e.g. "Screw sub-factory" or "Power slug on copper ridge"',
                  )
                : ListView.builder(
                    itemCount: needs.length,
                    itemBuilder: (context, i) {
                      final need = needs[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: colors.borderSecondary, width: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('▸ ',
                                style: TextStyle(
                                    fontSize: 16, color: ficsitAmber)),
                            Expanded(
                              child: Text(need.text,
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: colors.textPrimary)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              color: colors.textTertiary,
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
