import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_data.dart' as notes;
import '../services/game_data_service.dart';
import '../services/planner_engine.dart';
import '../services/settings_service.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(factory.name,
            style: const TextStyle(
                fontSize: 16, fontFamily: 'ShareTechMono')),
        toolbarHeight: 48,
      ),
      body: gameData.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: ficsitAmber)),
        error: (e, _) => Center(child: Text('Failed to load game data: $e')),
        data: (data) {
          final pd = factory.plannerData;
          if (pd == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'This factory was created manually and has no saved plan.\nLog it from the Planner tab to see the production tree.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                ),
              ),
            );
          }

          final itemClassName = pd['itemClassName'] as String?;
          final rate = (pd['rate'] as num?)?.toDouble() ?? 1;
          final advanced = pd['advanced'] as bool? ?? false;
          final savedOverclocks = <String, double>{};
          final rawOc = pd['overclocks'];
          if (rawOc is Map) {
            for (final entry in rawOc.entries) {
              final v = entry.value;
              if (v is num) savedOverclocks[entry.key.toString()] = v.toDouble();
            }
          }
          if (itemClassName == null) {
            return const Center(
              child: Text('Missing item data in saved plan.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
            );
          }

          final settings = ref.watch(settingsProvider);
          final engine = PlannerEngine(
            data,
            unlockedAlternates: settings.unlockedAlternates,
            overclocks: advanced ? savedOverclocks : const {},
          );
          final result = engine.calculate(itemClassName, rate);

          return Column(
            children: [
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
                      root: result,
                      beltRate: settings.beltRate,
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
}
