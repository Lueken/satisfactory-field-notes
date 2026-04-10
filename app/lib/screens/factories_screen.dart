import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_data.dart' as notes;
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'factory_detail_screen.dart';

const _statusStyle = {
  'wip': (bg: Color(0xFFE6F1FB), fg: Color(0xFF185FA5)),
  'minimal': (bg: Color(0xFFFAEEDA), fg: Color(0xFF633806)),
  'optimized': (bg: Color(0xFFEAF3DE), fg: Color(0xFF27500A)),
};

class FactoriesScreen extends ConsumerStatefulWidget {
  const FactoriesScreen({super.key});

  @override
  ConsumerState<FactoriesScreen> createState() => _FactoriesScreenState();
}

class _FactoriesScreenState extends ConsumerState<FactoriesScreen> {
  bool _showForm = false;
  final _nameCtrl = TextEditingController();
  final _producesCtrl = TextEditingController();
  String _status = 'wip';

  void _addFactory() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    ref.read(notesProvider.notifier).addFactory(
          name,
          _producesCtrl.text.trim(),
          _status,
        );
    _nameCtrl.clear();
    _producesCtrl.clear();
    setState(() {
      _status = 'wip';
      _showForm = false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _producesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);
    final factories = notes.factories;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FACTORY REGISTRY',
              style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                  letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Expanded(
            child: factories.isEmpty && !_showForm
                ? const Center(
                    child: Text('No factories logged yet.',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))))
                : ListView(
                    children: [
                      for (final f in factories) _FactoryRow(factory: f),
                      if (_showForm) _buildForm(),
                    ],
                  ),
          ),
          if (!_showForm)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => setState(() => _showForm = true),
                style: FilledButton.styleFrom(
                  backgroundColor: ficsitAmber,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('+ Log factory',
                    style: TextStyle(
                        fontSize: 15, fontFamily: 'ShareTechMono')),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(hintText: 'Factory name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _producesCtrl,
            style: const TextStyle(fontSize: 15),
            decoration:
                const InputDecoration(hintText: 'Produces (optional)'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(),
            items: ['wip', 'minimal', 'optimized']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _status = v ?? 'wip'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _addFactory,
              style: FilledButton.styleFrom(
                backgroundColor: ficsitAmber,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Add factory',
                  style: TextStyle(
                      fontSize: 15, fontFamily: 'ShareTechMono')),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _showForm = false),
            child: const Text('Cancel',
                style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          ),
        ],
      ),
    );
  }
}

class _FactoryRow extends ConsumerWidget {
  final notes.Factory factory;
  const _FactoryRow({required this.factory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = factory;
    final style = _statusStyle[f.status] ?? _statusStyle['wip']!;

    final hasPlan = f.plannerData != null;

    return InkWell(
      onTap: hasPlan
          ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FactoryDetailScreen(factory: f),
                ),
              )
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE7E5E4), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(f.name,
                            style: const TextStyle(
                                fontSize: 15, color: Color(0xFF1A1A1A))),
                      ),
                      if (hasPlan) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.account_tree,
                            size: 14, color: ficsitAmber),
                      ],
                    ],
                  ),
                  if (f.produces.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(f.produces,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF6B7280))),
                    ),
                ],
              ),
            ),
          GestureDetector(
            onTap: () =>
                ref.read(notesProvider.notifier).cycleFactoryStatus(f.id),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: style.bg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(f.status,
                  style: TextStyle(
                      fontSize: 12,
                      color: style.fg,
                      letterSpacing: 0.5)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: const Color(0xFF9CA3AF),
            onPressed: () =>
                ref.read(notesProvider.notifier).deleteFactory(f.id),
          ),
          ],
        ),
      ),
    );
  }
}
