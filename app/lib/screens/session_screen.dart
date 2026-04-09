import 'package:flutter/material.dart';
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('THIS SESSION',
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
                    hintText: "What's the next small step?",
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
            child: tasks.isEmpty
                ? const Center(
                    child: Text('No tasks yet. Keep them small and specific.',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))))
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, i) {
                      final task = tasks[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Color(0xFFE7E5E4), width: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: task.done,
                              onChanged: (_) => ref
                                  .read(notesProvider.notifier)
                                  .toggleTask(task.id),
                              activeColor: ficsitAmber,
                            ),
                            Expanded(
                              child: Text(
                                task.text,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: task.done
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF1A1A1A),
                                  decoration: task.done
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              color: const Color(0xFF9CA3AF),
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
                  child: const Text('Clear completed',
                      style:
                          TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
