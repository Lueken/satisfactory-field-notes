import 'dart:math' as math;

class ProductionNode {
  final String itemClassName;
  final String itemName;
  final double rate; // items per minute (demand)
  final String? machineName;
  final String? machineClassName;
  final double machineCount; // fractional (e.g., 3.5 constructors)
  final double powerPerMachine; // MW per machine (at 100%)
  final double overclock; // percentage, 50-250
  final String? recipeName;
  final double? craftTime;
  final bool isRawResource;
  final bool isSupplied; // item is constrained (comes from external source)
  final double suppliedAmount; // how much is actually supplied (if constrained)
  final List<ProductionNode> children;

  const ProductionNode({
    required this.itemClassName,
    required this.itemName,
    required this.rate,
    this.machineName,
    this.machineClassName,
    this.machineCount = 0,
    this.powerPerMachine = 0,
    this.overclock = 100,
    this.recipeName,
    this.craftTime,
    this.isRawResource = false,
    this.isSupplied = false,
    this.suppliedAmount = 0,
    this.children = const [],
  });

  /// True if supply can meet demand
  bool get isFullySupplied => isSupplied && suppliedAmount >= rate;

  /// Shortfall in items/min (positive when supply < demand)
  double get shortfall => isSupplied ? (rate - suppliedAmount).clamp(0, double.infinity) : 0;

  int get machineCountCeil => machineCount.ceil();

  /// Power scales by (clock/100)^1.321928 per game formula
  double get powerPerMachineOC {
    if (overclock == 100) return powerPerMachine;
    final ratio = overclock / 100.0;
    return powerPerMachine * math.pow(ratio, 1.321928).toDouble();
  }

  double get totalPower => machineCount * powerPerMachineOC;

  /// Total power for this node and all descendants.
  double get totalTreePower {
    var sum = totalPower;
    for (final child in children) {
      sum += child.totalTreePower;
    }
    return sum;
  }

  Map<String, double> flatItems() {
    final map = <String, double>{};
    _collectItems(map);
    return map;
  }

  void _collectItems(Map<String, double> map) {
    map.update(itemClassName, (v) => v + rate, ifAbsent: () => rate);
    for (final child in children) {
      child._collectItems(map);
    }
  }

  List<BuildingSummary> get buildingsList {
    final map = <String, _BuildingSummary>{};
    _collectBuildings(map);
    return map.entries
        .map((e) => (
              name: e.value.name,
              count: e.value.count,
              powerEach: e.value.powerEach,
            ))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }

  void _collectBuildings(Map<String, _BuildingSummary> map) {
    if (machineName != null && !isRawResource) {
      map.update(
        machineName!,
        (v) => _BuildingSummary(v.name, v.count + machineCount, v.powerEach),
        ifAbsent: () =>
            _BuildingSummary(machineName!, machineCount, powerPerMachine),
      );
    }
    for (final child in children) {
      child._collectBuildings(map);
    }
  }
}

class _BuildingSummary {
  final String name;
  final double count;
  final double powerEach;
  const _BuildingSummary(this.name, this.count, this.powerEach);
}

typedef BuildingSummary = ({String name, double count, double powerEach});
