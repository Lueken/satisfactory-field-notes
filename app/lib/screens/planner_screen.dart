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
  final Map<String, double> _inputConstraints = {};
  final Set<String> _collapsedSections = {};
  bool _showInputs = false;

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
    final colors = AppColors.of(context);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced production planning is a FICSIT-approved privilege reserved for Pioneers who have secured at least one Power Shard and completed the relevant Overclocking protocol.',
              style: TextStyle(
                fontSize: 13,
                color: colors.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'FICSIT does not recommend planning overclocked production without the means to actually overclock. Such planning has been statistically linked to pioneer frustration, unmet throughput targets, and, in one documented case, a strongly-worded letter.',
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Return once you have located your first Power Shard. FICSIT believes in you. Mostly.',
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'You may enable Advanced mode in Settings once Overclocking has been properly unlocked.',
              style: TextStyle(
                fontSize: 11,
                color: colors.textTertiary,
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

  Future<void> _saveAsFactory(WidgetRef ref) async {
    if (_result == null || _selectedItem == null) return;
    final rate = _rateController.text;
    final nameCtrl = TextEditingController(text: _selectedItem!.name);
    final colors = AppColors.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Save as factory',
            style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: TextStyle(fontSize: 15, color: colors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Factory name',
                labelStyle:
                    TextStyle(fontSize: 12, color: colors.textTertiary),
              ),
              onSubmitted: (_) => Navigator.of(ctx).pop(true),
            ),
            const SizedBox(height: 8),
            Text(
              'Producing $rate/min',
              style: TextStyle(fontSize: 12, color: colors.textTertiary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style:
                    TextStyle(fontSize: 13, color: colors.textTertiary)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: ficsitAmber),
            child: const Text('Save',
                style: TextStyle(
                    fontSize: 13, fontFamily: 'ShareTechMono')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final name = nameCtrl.text.trim().isNotEmpty
        ? nameCtrl.text.trim()
        : _selectedItem!.name;

    ref.read(notesProvider.notifier).addFactory(
          name,
          '$rate/min',
          'wip',
          plannerData: {
            'itemClassName': _selectedItem!.className,
            'rate': double.tryParse(rate) ?? 1,
            'advanced': _advanced,
            'overclocks': _overclocks,
            'inputConstraints': _inputConstraints,
          },
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved "$name" to factories'),
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
      inputConstraints: _advanced ? _inputConstraints : const {},
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

    final colors = AppColors.of(context);
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
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
                  style: TextStyle(
                      fontSize: 11, color: colors.textTertiary),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Clock %',
                              style: TextStyle(
                                  fontSize: 11, color: colors.textTertiary)),
                          TextField(
                            controller: clockCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'ShareTechMono',
                                color: colors.textPrimary),
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
                          Text('Items / min',
                              style: TextStyle(
                                  fontSize: 11, color: colors.textTertiary)),
                          TextField(
                            controller: rateCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'ShareTechMono',
                                color: colors.textPrimary),
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
                            style: TextStyle(
                                fontSize: 11, color: colors.textSecondary)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel',
                  style:
                      TextStyle(fontSize: 13, color: colors.textTertiary)),
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
      data: (data) {
        final colors = AppColors.of(context);
        return Column(
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
                    Text(
                      'PRODUCTION PLANNER',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textTertiary,
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
                    _inputConstraints.clear();
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
                        style: TextStyle(
                            fontSize: 16, color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'rate',
                          hintStyle: TextStyle(color: colors.textTertiary),
                          suffixText: '/min',
                          suffixStyle: TextStyle(
                              fontSize: 12, color: colors.textTertiary),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 14),
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
                    if (_advanced && _result != null) ...[
                      const SizedBox(width: 8),
                      _InputsButton(
                        count: _inputConstraints.length,
                        expanded: _showInputs,
                        onTap: () => setState(() => _showInputs = !_showInputs),
                      ),
                    ],
                  ],
                ),
                if (_advanced && _result != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Long-press or tap ⚙ to overclock',
                      style: TextStyle(
                          fontSize: 11, color: colors.textTertiary),
                    ),
                  ),
                if (_advanced && _result != null && _showInputs)
                  _InputsPanel(
                    data: data,
                    constraints: _inputConstraints,
                    onAdd: (item, rate) {
                      setState(() => _inputConstraints[item.className] = rate);
                      _calculate(data);
                    },
                    onRemove: (className) {
                      setState(() => _inputConstraints.remove(className));
                      _calculate(data);
                    },
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
                    root: _result!,
                    beltRate: _effectiveBeltRate(),
                    onEditOverclock: _advanced ? _showOverclockDialog : null,
                    collapsedSections: _collapsedSections,
                    onToggleSection: (cn) => setState(() {
                      if (_collapsedSections.contains(cn)) {
                        _collapsedSections.remove(cn);
                      } else {
                        _collapsedSections.add(cn);
                      }
                    }),
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
                    Text(
                      'Select an item and rate to calculate.',
                      style: TextStyle(
                          fontSize: 13, color: colors.textTertiary),
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
        );
      },
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool advanced;
  final ValueChanged<bool> onChanged;

  const _ModeToggle({required this.advanced, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment('Simple', !advanced, () => onChanged(false), colors),
          _segment('Advanced', advanced, () => onChanged(true), colors),
        ],
      ),
    );
  }

  Widget _segment(
      String label, bool active, VoidCallback onTap, AppColors colors) {
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
            color: active ? Colors.white : colors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _InputsButton extends StatelessWidget {
  final int count;
  final bool expanded;
  final VoidCallback onTap;

  const _InputsButton({
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          expanded ? Icons.expand_less : Icons.input,
          size: 14,
          color: const Color(0xFF185FA5),
        ),
        label: Text(
          count > 0 ? 'Inputs ($count)' : 'Inputs',
          style: const TextStyle(
              fontSize: 12,
              fontFamily: 'ShareTechMono',
              color: Color(0xFF185FA5)),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFD0D7DE), width: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _InputsPanel extends StatelessWidget {
  final GameData data;
  final Map<String, double> constraints;
  final void Function(GameItem item, double rate) onAdd;
  final void Function(String className) onRemove;

  const _InputsPanel({
    required this.data,
    required this.constraints,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    const suppliedColor = Color(0xFF3B82F6);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSecondary, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SUPPLIED INPUTS',
              style: TextStyle(
                  fontSize: 10,
                  color: colors.textTertiary,
                  letterSpacing: 1.5)),
          const SizedBox(height: 6),
          if (constraints.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'No supplied inputs. Add one to skip building production for that item.',
                style: TextStyle(
                    fontSize: 11, color: colors.textTertiary),
              ),
            ),
          for (final entry in constraints.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      data.itemName(entry.key),
                      style: const TextStyle(
                          fontSize: 13, color: suppliedColor),
                    ),
                  ),
                  Text(
                    '${entry.value == entry.value.roundToDouble() ? entry.value.toStringAsFixed(0) : entry.value.toStringAsFixed(1)}/min',
                    style: TextStyle(
                        fontSize: 13, color: colors.textSecondary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 14),
                    color: colors.textTertiary,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 26, minHeight: 26),
                    onPressed: () => onRemove(entry.key),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: () => _showAddDialog(context),
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Add supplied input',
                style: TextStyle(
                    fontSize: 12, fontFamily: 'ShareTechMono')),
            style: OutlinedButton.styleFrom(
              foregroundColor: suppliedColor,
              side: BorderSide(color: colors.borderSecondary, width: 0.5),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    GameItem? selected;
    final rateCtrl = TextEditingController();
    final colors = AppColors.of(context);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          title: const Text('Add supplied input',
              style: TextStyle(
                  fontFamily: 'ShareTechMono', fontSize: 15)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ItemSearch(
                  items: data.searchableItems,
                  onSelected: (item) {
                    setDialogState(() => selected = item);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rateCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 16, color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Rate available',
                    hintStyle: TextStyle(color: colors.textTertiary),
                    suffixText: '/min',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The planner will treat this item as supplied and skip building production for it.',
                  style: TextStyle(
                      fontSize: 11, color: colors.textTertiary),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel',
                  style:
                      TextStyle(fontSize: 13, color: colors.textTertiary)),
            ),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () {
                      final rate = double.tryParse(rateCtrl.text) ?? 0;
                      if (rate <= 0) return;
                      onAdd(selected!, rate);
                      Navigator.of(ctx).pop();
                    },
              style: FilledButton.styleFrom(
                  backgroundColor: ficsitAmber,
                  disabledBackgroundColor:
                      ficsitAmber.withValues(alpha: 0.4)),
              child: const Text('Add',
                  style: TextStyle(
                      fontSize: 13, fontFamily: 'ShareTechMono')),
            ),
          ],
        ),
      ),
    );
  }
}
