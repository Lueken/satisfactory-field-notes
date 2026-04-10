import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_data.dart';
import '../models/production_node.dart';
import '../services/game_data_service.dart';
import '../services/planner_engine.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../widgets/item_search.dart';
import '../widgets/production_tree.dart';
import '../widgets/items_list.dart';
import '../widgets/buildings_list.dart';
import '../theme/app_theme.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _rateController = TextEditingController(text: '1');
  GameItem? _selectedItem;
  ProductionNode? _result;
  final Map<String, double> _overclocks = {};

  bool get _advanced => ref.read(settingsProvider).advancedPlanner;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  /// Effective belt rate: always from user settings now.
  int _effectiveBeltRate() => ref.read(settingsProvider).beltRate;

  Future<void> _onModeChange(bool advanced, GameData data) async {
    if (advanced) {
      final overclockingUnlocked =
          ref.read(settingsProvider).overclockingEnabled;
      if (!overclockingUnlocked) {
        await _showOverclockLockedDialog();
        return;
      }
    }
    ref.read(settingsProvider.notifier).setAdvancedPlanner(advanced);
    _calculate(data);
  }

  Future<void> _showOverclockLockedDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, size: 18, color: ficsitAmber),
            SizedBox(width: 8),
            Text(
              'ADVANCED MODE LOCKED',
              style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced production planning is a FICSIT-approved privilege reserved for Pioneers who have secured at least one Power Shard and completed the relevant Overclocking protocol.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF1A1A1A),
                height: 1.5,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'FICSIT does not recommend planning overclocked production without the means to actually overclock. Such planning has been statistically linked to pioneer frustration, unmet throughput targets, and, in one documented case, a strongly-worded letter.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Return once you have located your first Power Shard. FICSIT believes in you. Mostly.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            SizedBox(height: 14),
            Text(
              'You may enable Advanced mode in Settings once Overclocking has been properly unlocked.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(backgroundColor: ficsitAmber),
            child: const Text(
              'Acknowledged',
              style:
                  TextStyle(fontSize: 13, fontFamily: 'ShareTechMono'),
            ),
          ),
        ],
      ),
    );
  }

  void _saveAsFactory(WidgetRef ref) {
    if (_result == null || _selectedItem == null) return;
    final rate = _rateController.text;
    ref.read(notesProvider.notifier).addFactory(
          _selectedItem!.name,
          '$rate/min',
          'wip',
          plannerData: {
            'itemClassName': _selectedItem!.className,
            'rate': double.tryParse(rate) ?? 1,
            'advanced': _advanced,
            'overclocks': _overclocks,
          },
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved ${_selectedItem!.name} to factories'),
        backgroundColor: ficsitAmber,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _calculate(GameData data) {
    if (_selectedItem == null) return;
    final rate = double.tryParse(_rateController.text) ?? 1;
    if (rate <= 0) return;
    final settings = ref.read(settingsProvider);
    final engine = PlannerEngine(
      data,
      unlockedAlternates: settings.unlockedAlternates,
      overclocks: _advanced ? _overclocks : const {},
    );
    setState(() {
      _result = engine.calculate(_selectedItem!.className, rate);
    });
  }

  Future<void> _showOverclockDialog(ProductionNode node) async {
    if (!_advanced) return;
    final current = _overclocks[node.itemClassName] ?? 100.0;
    // Base rate at 100% per machine
    final baseRatePerMachine = node.overclock > 0
        ? (node.machineCount * (node.overclock / 100) > 0
            ? node.rate / (node.machineCount * (node.overclock / 100))
            : 0.0)
        : 0.0;
    // Alternative: node.rate / node.machineCount gives effective rate at current clock.
    // base = effective / (clock/100)
    final ratePerMachine = node.machineCount > 0
        ? node.rate / node.machineCount
        : 0.0;
    final baseRate = ratePerMachine > 0 && node.overclock > 0
        ? ratePerMachine / (node.overclock / 100)
        : 0.0;
    // Use baseRate as the canonical 100% rate.
    final base = baseRate > 0 ? baseRate : baseRatePerMachine;

    final clockCtrl =
        TextEditingController(text: current.toStringAsFixed(2));
    final rateCtrl = TextEditingController(
        text: (base * current / 100).toStringAsFixed(2));
    double value = current;

    // Prevent feedback loops when syncing fields
    bool syncing = false;

    void updateFromClock(String text) {
      if (syncing) return;
      final parsed = double.tryParse(text);
      if (parsed == null) return;
      final clamped = parsed.clamp(1.0, 250.0);
      value = clamped;
      syncing = true;
      rateCtrl.text = (base * clamped / 100).toStringAsFixed(2);
      syncing = false;
    }

    void updateFromRate(String text) {
      if (syncing) return;
      final parsed = double.tryParse(text);
      if (parsed == null || base <= 0) return;
      final clock = (parsed / base) * 100;
      final clamped = clock.clamp(1.0, 250.0);
      value = clamped;
      syncing = true;
      clockCtrl.text = clamped.toStringAsFixed(2);
      syncing = false;
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Overclock ${node.itemName}',
            style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 15),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${node.machineName} — base ${base.toStringAsFixed(2)}/min per machine',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Clock %',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF9CA3AF))),
                          TextField(
                            controller: clockCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'ShareTechMono'),
                            decoration: const InputDecoration(
                              isDense: true,
                              suffixText: '%',
                            ),
                            onChanged: (v) => setDialogState(() => updateFromClock(v)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Items / min',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF9CA3AF))),
                          TextField(
                            controller: rateCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'ShareTechMono'),
                            decoration: const InputDecoration(
                              isDense: true,
                              suffixText: '/min',
                            ),
                            onChanged: (v) => setDialogState(() => updateFromRate(v)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Slider(
                  value: value.clamp(1.0, 250.0),
                  min: 1,
                  max: 250,
                  activeColor: ficsitAmber,
                  onChanged: (v) {
                    setDialogState(() {
                      value = v;
                      syncing = true;
                      clockCtrl.text = v.toStringAsFixed(2);
                      rateCtrl.text = (base * v / 100).toStringAsFixed(2);
                      syncing = false;
                    });
                  },
                ),
                Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  spacing: 4,
                  children: [
                    for (final preset in [50, 100, 150, 200, 250])
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => setDialogState(() {
                          value = preset.toDouble();
                          syncing = true;
                          clockCtrl.text = value.toStringAsFixed(2);
                          rateCtrl.text =
                              (base * value / 100).toStringAsFixed(2);
                          syncing = false;
                        }),
                        child: Text('$preset%',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF6B7280))),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() {
                  if ((value - 100).abs() < 0.01) {
                    _overclocks.remove(node.itemClassName);
                  } else {
                    _overclocks[node.itemClassName] = value;
                  }
                });
                final data = ref.read(gameDataProvider).valueOrNull;
                if (data != null) _calculate(data);
              },
              style: FilledButton.styleFrom(backgroundColor: ficsitAmber),
              child: const Text('Apply',
                  style: TextStyle(
                      fontSize: 13, fontFamily: 'ShareTechMono')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsProvider); // rebuild on mode/settings changes
    final gameData = ref.watch(gameDataProvider);

    return gameData.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: ficsitAmber)),
      error: (e, _) => Center(child: Text('Failed to load game data: $e')),
      data: (data) => Column(
        children: [
          // Header + mode toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PRODUCTION PLANNER',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 1.5,
                      ),
                    ),
                    _ModeToggle(
                      advanced: _advanced,
                      onChanged: (v) => _onModeChange(v, data),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ItemSearch(
                  items: data.searchableItems,
                  onSelected: (item) {
                    _selectedItem = item;
                    _overclocks.clear();
                    _calculate(data);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _rateController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: 'Items per minute',
                          hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                          suffixText: '/min',
                          suffixStyle: TextStyle(
                              fontSize: 13, color: Color(0xFF9CA3AF)),
                        ),
                        onSubmitted: (_) => _calculate(data),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: () => _calculate(data),
                        style: FilledButton.styleFrom(
                          backgroundColor: ficsitAmber,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Go',
                            style: TextStyle(fontFamily: 'ShareTechMono')),
                      ),
                    ),
                  ],
                ),
                if (_advanced && _result != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Long-press any machine to overclock',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                  ),
              ],
            ),
          ),

          // Sub-tabs
          if (_result != null) ...[
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              labelColor: ficsitAmber,
              unselectedLabelColor: const Color(0xFF9CA3AF),
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
                    root: _result!,
                    beltRate: _effectiveBeltRate(),
                    onEditOverclock: _advanced ? _showOverclockDialog : null,
                  ),
                  ItemsList(root: _result!, gameData: data),
                  BuildingsList(root: _result!),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _saveAsFactory(ref),
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Save as Factory',
                      style:
                          TextStyle(fontFamily: 'ShareTechMono', fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ficsitAmber,
                    side: const BorderSide(color: ficsitAmber, width: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
          ],

          if (_result == null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Select an item and rate to calculate.',
                      style:
                          TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${data.recipesByProduct.length} producible items',
                      style: const TextStyle(
                          fontSize: 13, color: ficsitAmber),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool advanced;
  final ValueChanged<bool> onChanged;

  const _ModeToggle({required this.advanced, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment('Simple', !advanced, () => onChanged(false)),
          _segment('Advanced', advanced, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _segment(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? ficsitAmber : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'ShareTechMono',
            color: active ? Colors.white : const Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
