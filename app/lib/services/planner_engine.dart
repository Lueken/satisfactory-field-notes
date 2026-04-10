import '../models/game_data.dart';
import '../models/production_node.dart';

class PlannerEngine {
  final GameData data;
  final Set<String> unlockedAlternates;

  /// Overclock per item class (1-250). Default 100.
  final Map<String, double> overclocks;

  const PlannerEngine(
    this.data, {
    this.unlockedAlternates = const {},
    this.overclocks = const {},
  });

  static const _machineNames = {
    'Desc_ConstructorMk1_C': 'Constructor',
    'Desc_AssemblerMk1_C': 'Assembler',
    'Desc_ManufacturerMk1_C': 'Manufacturer',
    'Desc_OilRefinery_C': 'Refinery',
    'Desc_Packager_C': 'Packager',
    'Desc_Blender_C': 'Blender',
    'Desc_SmelterMk1_C': 'Smelter',
    'Desc_FoundryMk1_C': 'Foundry',
    'Desc_HadronCollider_C': 'Particle Accelerator',
    'Desc_Converter_C': 'Converter',
    'Desc_QuantumEncoder_C': 'Quantum Encoder',
  };

  ProductionNode calculate(String itemClassName, double desiredRate,
      {int depth = 0, Set<String>? visited}) {
    visited ??= {};
    final itemName = data.itemName(itemClassName);

    if (depth > 20 || visited.contains(itemClassName)) {
      return ProductionNode(
        itemClassName: itemClassName,
        itemName: itemName,
        rate: desiredRate,
        isRawResource: true,
      );
    }

    final recipe = data.defaultRecipeFor(
      itemClassName,
      unlockedAlternates: unlockedAlternates,
    );
    if (recipe == null) {
      return ProductionNode(
        itemClassName: itemClassName,
        itemName: itemName,
        rate: desiredRate,
        isRawResource: true,
      );
    }

    final productIndex =
        recipe.products.indexWhere((p) => p.item == itemClassName);
    if (productIndex < 0) {
      return ProductionNode(
        itemClassName: itemClassName,
        itemName: itemName,
        rate: desiredRate,
        isRawResource: true,
      );
    }

    final baseRatePerMachine = recipe.outputPerMin(productIndex);
    if (baseRatePerMachine <= 0) {
      return ProductionNode(
        itemClassName: itemClassName,
        itemName: itemName,
        rate: desiredRate,
        isRawResource: true,
      );
    }

    // Apply overclock (defaults to 100%)
    final overclock = overclocks[itemClassName] ?? 100.0;
    final effectiveRatePerMachine = baseRatePerMachine * (overclock / 100);
    final machineCount = desiredRate / effectiveRatePerMachine;

    final machineClass =
        recipe.producedIn.isNotEmpty ? recipe.producedIn.first : null;
    final machineName = machineClass != null
        ? _machineNames[machineClass] ?? machineClass
        : null;
    final powerPerMachine =
        machineClass != null ? data.powerForMachine(machineClass) : 0.0;

    // Recurse into each ingredient. Total input rate = desiredOutput * ratio,
    // independent of overclock (more overclock = fewer machines but each
    // consumes more, total is the same).
    final nextVisited = {...visited, itemClassName};
    final children = <ProductionNode>[];
    final outputPerCycle = recipe.products[productIndex].amount;
    for (var i = 0; i < recipe.ingredients.length; i++) {
      final ingredient = recipe.ingredients[i];
      final ratio = recipe.ingredients[i].amount / outputPerCycle;
      final inputRate = desiredRate * ratio;
      children.add(
        calculate(ingredient.item, inputRate,
            depth: depth + 1, visited: nextVisited),
      );
    }

    return ProductionNode(
      itemClassName: itemClassName,
      itemName: itemName,
      rate: desiredRate,
      machineName: machineName,
      machineClassName: machineClass,
      machineCount: machineCount,
      powerPerMachine: powerPerMachine,
      overclock: overclock,
      recipeName: recipe.name,
      craftTime: recipe.time,
      children: children,
    );
  }
}
