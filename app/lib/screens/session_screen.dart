import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  final _controller = TextEditingController();

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(notesProvider.notifier).addTask(text);
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
    final tasks = notes.session;
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THIS SESSION',
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
                    hintText: "What's the next small step?",
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
            child: tasks.isEmpty
                ? Center(
                    child: Text('No tasks yet. Keep them small and specific.',
                        style: TextStyle(
                            fontSize: 13, color: colors.textTertiary)))
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, i) {
                      final task = tasks[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: colors.borderSecondary, width: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: task.done,
                              onChanged: (_) {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(notesProvider.notifier)
                                    .toggleTask(task.id);
                              },
                              activeColor: ficsitAmber,
                            ),
                            Expanded(
                              child: Text(
                                task.text,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: task.done
                                      ? colors.textTertiary
                                      : colors.textPrimary,
                                  decoration: task.done
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              color: colors.textTertiary,
                              onPressed: () => ref
                                  .read(notesProvider.notifier)
                                  .deleteTask(task.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (tasks.any((t) => t.done))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () =>
                      ref.read(notesProvider.notifier).clearCompleted(),
                  child: Text('Clear completed',
                      style: TextStyle(
                          fontSize: 13, color: colors.textTertiary)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
