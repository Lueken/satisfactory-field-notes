class ProductionNode {
  final String itemClassName;
  final String itemName;
  final double rate; // items per minute
  final String? machineName;
  final double machineCount; // fractional (e.g., 3.5 constructors)
  final String? recipeName;
  final double? craftTime;
  final bool isRawResource;
  final List<ProductionNode> children;

  const ProductionNode({
    required this.itemClassName,
    required this.itemName,
    required this.rate,
    this.machineName,
    this.machineCount = 0,
    this.recipeName,
    this.craftTime,
    this.isRawResource = false,
    this.children = const [],
  });

  int get machineCountCeil => machineCount.ceil();

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
        .map((e) => (name: e.value.name, count: e.value.count))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }

  void _collectBuildings(Map<String, _BuildingSummary> map) {
    if (machineName != null && !isRawResource) {
      map.update(
        machineName!,
        (v) => _BuildingSummary(v.name, v.count + machineCount),
        ifAbsent: () => _BuildingSummary(machineName!, machineCount),
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
  const _BuildingSummary(this.name, this.count);
}

typedef BuildingSummary = ({String name, double count});
