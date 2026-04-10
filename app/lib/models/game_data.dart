class GameItem {
  final String className;
  final String name;
  final String slug;
  final String description;
  final int sinkPoints;
  final int stackSize;
  final double energyValue;
  final bool liquid;

  const GameItem({
    required this.className,
    required this.name,
    required this.slug,
    required this.description,
    required this.sinkPoints,
    required this.stackSize,
    required this.energyValue,
    required this.liquid,
  });

  factory GameItem.fromJson(Map<String, dynamic> json) => GameItem(
        className: json['className'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
        description: json['description'] as String? ?? '',
        sinkPoints: (json['sinkPoints'] as num?)?.toInt() ?? 0,
        stackSize: (json['stackSize'] as num?)?.toInt() ?? 100,
        energyValue: (json['energyValue'] as num?)?.toDouble() ?? 0,
        liquid: json['liquid'] as bool? ?? false,
      );
}

class RecipeIngredient {
  final String item;
  final double amount;

  const RecipeIngredient({required this.item, required this.amount});

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        item: json['item'] as String,
        amount: (json['amount'] as num).toDouble(),
      );
}

class GameRecipe {
  final String className;
  final String name;
  final String slug;
  final bool alternate;
  final double time;
  final bool inMachine;
  final bool forBuilding;
  final List<RecipeIngredient> ingredients;
  final List<RecipeIngredient> products;
  final List<String> producedIn;
  final bool isVariablePower;
  final double minPower;
  final double maxPower;

  const GameRecipe({
    required this.className,
    required this.name,
    required this.slug,
    required this.alternate,
    required this.time,
    required this.inMachine,
    required this.forBuilding,
    required this.ingredients,
    required this.products,
    required this.producedIn,
    required this.isVariablePower,
    required this.minPower,
    required this.maxPower,
  });

  factory GameRecipe.fromJson(Map<String, dynamic> json) => GameRecipe(
        className: json['className'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
        alternate: json['alternate'] as bool? ?? false,
        time: (json['time'] as num).toDouble(),
        inMachine: json['inMachine'] as bool? ?? false,
        forBuilding: json['forBuilding'] as bool? ?? false,
        ingredients: (json['ingredients'] as List)
            .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
        products: (json['products'] as List)
            .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
        producedIn: (json['producedIn'] as List)
            .map((e) => e as String)
            .toList(),
        isVariablePower: json['isVariablePower'] as bool? ?? false,
        minPower: (json['minPower'] as num?)?.toDouble() ?? 0,
        maxPower: (json['maxPower'] as num?)?.toDouble() ?? 0,
      );

  double outputPerMin(int productIndex) =>
      time > 0 ? (60 / time) * products[productIndex].amount : 0;

  double inputPerMin(int ingredientIndex) =>
      time > 0 ? (60 / time) * ingredients[ingredientIndex].amount : 0;
}

class GameData {
  final Map<String, GameItem> items;
  final Map<String, GameRecipe> recipes;
  final Map<String, double> machinePower; // className -> MW
  final Map<String, List<GameRecipe>> recipesByProduct;
  final List<GameItem> searchableItems;

  GameData({
    required this.items,
    required this.recipes,
    required this.machinePower,
  })  : recipesByProduct = _indexByProduct(recipes),
        searchableItems = items.values.toList()
          ..sort((a, b) => a.name.compareTo(b.name));

  double powerForMachine(String className) => machinePower[className] ?? 0;

  static Map<String, List<GameRecipe>> _indexByProduct(
      Map<String, GameRecipe> recipes) {
    final index = <String, List<GameRecipe>>{};
    for (final recipe in recipes.values) {
      if (!recipe.inMachine || recipe.forBuilding) continue;
      for (final product in recipe.products) {
        index.putIfAbsent(product.item, () => []).add(recipe);
      }
    }
    return index;
  }

  List<GameRecipe> recipesFor(String itemClassName) =>
      recipesByProduct[itemClassName] ?? [];

  // Machine tier: prefer basic machines over advanced ones
  static const _machineTier = {
    'Desc_SmelterMk1_C': 0,
    'Desc_ConstructorMk1_C': 1,
    'Desc_AssemblerMk1_C': 2,
    'Desc_FoundryMk1_C': 3,
    'Desc_ManufacturerMk1_C': 4,
    'Desc_OilRefinery_C': 5,
    'Desc_Packager_C': 6,
    'Desc_Blender_C': 7,
    'Desc_Converter_C': 8,
    'Desc_HadronCollider_C': 9,
    'Desc_QuantumEncoder_C': 10,
  };

  int _recipeTier(GameRecipe r) {
    if (r.producedIn.isEmpty) return 99;
    return _machineTier[r.producedIn.first] ?? 50;
  }

  GameRecipe? defaultRecipeFor(
    String itemClassName, {
    Set<String> unlockedAlternates = const {},
  }) {
    final list = recipesFor(itemClassName);
    if (list.isEmpty) return null;
    // Include non-alternate defaults + any unlocked alternates
    final available = list
        .where((r) => !r.alternate || unlockedAlternates.contains(r.className))
        .toList();
    if (available.isEmpty) return list.first;
    // Prefer non-Converter recipes; if only Converter recipes exist, this is
    // effectively a raw resource (ore-to-ore swaps) — return null
    final nonConverter = available.where((r) => _recipeTier(r) < 8).toList();
    if (nonConverter.isEmpty) return null;
    nonConverter.sort((a, b) => _recipeTier(a).compareTo(_recipeTier(b)));
    return nonConverter.first;
  }

  String itemName(String className) =>
      items[className]?.name ?? className.replaceAll('Desc_', '').replaceAll('_C', '');
}
