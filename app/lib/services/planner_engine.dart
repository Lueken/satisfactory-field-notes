import '../models/game_data.dart';
import '../models/production_node.dart';

class PlannerEngine {
  final GameData data;

  const PlannerEngine(this.data);

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

    // Prevent infinite recursion on circular recipes
    if (depth > 20 || visited.contains(itemClassName)) {
      return ProductionNode(
        itemClassName: itemClassName,
        itemName: itemName,
        rate: desiredRate,
        isRawResource: true,
      );
    }

    final recipe = data.defaultRecipeFor(itemClassName);
    if (recipe == null) {
      // Raw resource (ore, water, etc.) — no recipe, leaf node
      return ProductionNode(
        itemClassName: itemClassName,
        itemName: itemName,
        rate: desiredRate,
        isRawResource: true,
      );
    }

    // Find which product index matches our target item
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

    // Rate per machine = (60 / craftTime) * amountPerCycle
    final ratePerMachine = recipe.outputPerMin(productIndex);
    if (ratePerMachine <= 0) {
      return ProductionNode(
        itemClassName: itemClassName,
        itemName: itemName,
        rate: desiredRate,
        isRawResource: true,
      );
    }

    final machineCount = desiredRate / ratePerMachine;
    final machineName = recipe.producedIn.isNotEmpty
        ? _machineNames[recipe.producedIn.first] ?? recipe.producedIn.first
        : null;

    // Recurse into each ingredient
    final nextVisited = {...visited, itemClassName};
    final children = <ProductionNode>[];
    for (var i = 0; i < recipe.ingredients.length; i++) {
      final ingredient = recipe.ingredients[i];
      final inputRate = machineCount * recipe.inputPerMin(i);
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
      machineCount: machineCount,
      recipeName: recipe.name,
      craftTime: recipe.time,
      children: children,
    );
  }
}
