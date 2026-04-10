import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_data.dart' as notes;
import '../services/game_data_service.dart';
import '../services/planner_engine.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../widgets/production_tree.dart';
import '../widgets/items_list.dart';
import '../widgets/buildings_list.dart';
import '../theme/app_theme.dart';

class FactoryDetailScreen extends ConsumerStatefulWidget {
  final notes.Factory factory;
  const FactoryDetailScreen({super.key, required this.factory});

  @override
  ConsumerState<FactoryDetailScreen> createState() =>
      _FactoryDetailScreenState();
}

class _FactoryDetailScreenState extends ConsumerState<FactoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _collapsed = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final factory = widget.factory;
    final gameData = ref.watch(gameDataProvider);
    // Watch notes so rename updates the app bar title reactively
    final notesState = ref.watch(notesProvider);
    final liveFactory = notesState.factories.firstWhere(
      (f) => f.id == factory.id,
      orElse: () => factory,
    );
    final colors = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(liveFactory.name,
            style: const TextStyle(
                fontSize: 16, fontFamily: 'ShareTechMono')),
        toolbarHeight: 48,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Rename',
            onPressed: () => _showRenameDialog(context, liveFactory),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: gameData.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: ficsitAmber)),
        error: (e, _) => Center(child: Text('Failed to load game data: $e')),
        data: (data) {
          final pd = liveFactory.plannerData;
          if (pd == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'This factory was created manually and has no saved plan.\nLog it from the Planner tab to see the production tree.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: colors.textTertiary),
                ),
              ),
            );
          }

          final itemClassName = pd['itemClassName'] as String?;
          final rate = (pd['rate'] as num?)?.toDouble() ?? 1;
          final advanced = pd['advanced'] as bool? ?? false;
          final savedOverclocks = _parseDoubleMap(pd['overclocks']);
          final savedConstraints = _parseDoubleMap(pd['inputConstraints']);
          if (itemClassName == null) {
            return Center(
              child: Text('Missing item data in saved plan.',
                  style: TextStyle(
                      fontSize: 13, color: colors.textTertiary)),
            );
          }

          final settings = ref.watch(settingsProvider);
          final engine = PlannerEngine(
            data,
            unlockedAlternates: settings.unlockedAlternates,
            overclocks: advanced ? savedOverclocks : const {},
            inputConstraints: advanced ? savedConstraints : const {},
          );
          final result = engine.calculate(itemClassName, rate);

          return Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: ficsitAmber,
                unselectedLabelColor: colors.textTertiary,
                indicatorColor: ficsitAmber,
                labelStyle: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 0.5),
                tabs: const [
                  Tab(text: 'TREE'),
                  Tab(text: 'ITEMS'),
                  Tab(text: 'BUILDINGS'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ProductionTree(
                      root: result,
                      beltRate: settings.beltRate,
                      onToggleSection: (cn) => setState(() {
                        if (_collapsed.contains(cn)) {
                          _collapsed.remove(cn);
                        } else {
                          _collapsed.add(cn);
                        }
                      }),
                      collapsedSections: _collapsed,
                    ),
                    ItemsList(root: result, gameData: data),
                    BuildingsList(root: result),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showRenameDialog(
      BuildContext context, notes.Factory f) async {
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

  Map<String, double> _parseDoubleMap(dynamic raw) {
    final out = <String, double>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final v = entry.value;
        if (v is num) out[entry.key.toString()] = v.toDouble();
      }
    }
    return out;
  }
}
