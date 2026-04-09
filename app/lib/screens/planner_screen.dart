import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_data.dart';
import '../models/production_node.dart';
import '../services/game_data_service.dart';
import '../services/planner_engine.dart';
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
    final engine = PlannerEngine(data);
    setState(() {
      _result = engine.calculate(_selectedItem!.className, rate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameData = ref.watch(gameDataProvider);

    return gameData.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: ficsitAmber)),
      error: (e, _) => Center(child: Text('Failed to load game data: $e')),
      data: (data) => Column(
        children: [
          // Search + rate input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRODUCTION PLANNER',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                ItemSearch(
                  items: data.searchableItems,
                  onSelected: (item) {
                    _selectedItem = item;
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
                          suffixStyle:
                              TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
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
                  ProductionTree(root: _result!),
                  ItemsList(root: _result!, gameData: data),
                  BuildingsList(root: _result!),
                ],
              ),
            ),
            // Save as Factory
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _saveAsFactory(ref),
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Save as Factory',
                      style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 13)),
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

          // Empty state
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
