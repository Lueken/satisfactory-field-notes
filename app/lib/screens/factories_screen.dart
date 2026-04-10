import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FACTORY REGISTRY',
              style: TextStyle(
                  fontSize: 11,
                  color: colors.textTertiary,
                  letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Expanded(
            child: factories.isEmpty && !_showForm
                ? Center(
                    child: Text('No factories logged yet.',
                        style: TextStyle(
                            fontSize: 13, color: colors.textTertiary)))
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
    final colors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          TextField(
            controller: _nameCtrl,
            style: TextStyle(fontSize: 15, color: colors.textPrimary),
            decoration: const InputDecoration(hintText: 'Factory name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _producesCtrl,
            style: TextStyle(fontSize: 15, color: colors.textPrimary),
            decoration:
                const InputDecoration(hintText: 'Produces (optional)'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(),
            style: TextStyle(
                fontSize: 15,
                color: colors.textPrimary,
                fontFamily: 'ShareTechMono'),
            dropdownColor: colors.bgSecondary,
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
            child: Text('Cancel',
                style:
                    TextStyle(fontSize: 13, color: colors.textTertiary)),
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
    final colors = AppColors.of(context);
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
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.borderSecondary, width: 0.5),
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
                            style: TextStyle(
                                fontSize: 15, color: colors.textPrimary)),
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
                          style: TextStyle(
                              fontSize: 13, color: colors.textSecondary)),
                    ),
                ],
              ),
            ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(notesProvider.notifier).cycleFactoryStatus(f.id);
            },
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
            icon: const Icon(Icons.edit_outlined, size: 16),
            color: colors.textTertiary,
            tooltip: 'Rename',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _showRenameDialog(context, ref, f),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: colors.textTertiary,
            onPressed: () =>
                ref.read(notesProvider.notifier).deleteFactory(f.id),
          ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameDialog(
      BuildContext context, WidgetRef ref, notes.Factory f) async {
    final ctrl = TextEditingController(text: f.name);
    final colors = AppColors.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Rename factory',
            style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 15)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(fontSize: 15, color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Factory name',
            labelStyle:
                TextStyle(fontSize: 12, color: colors.textTertiary),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style:
                    TextStyle(fontSize: 13, color: colors.textTertiary)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: ficsitAmber),
            child: const Text('Save',
                style:
                    TextStyle(fontSize: 13, fontFamily: 'ShareTechMono')),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && result != f.name) {
      ref.read(notesProvider.notifier).renameFactory(f.id, result);
    }
  }
}
