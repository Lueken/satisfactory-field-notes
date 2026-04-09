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
  final Map<String, List<GameRecipe>> recipesByProduct;
  final List<GameItem> searchableItems;

  GameData({
    required this.items,
    required this.recipes,
  })  : recipesByProduct = _indexByProduct(recipes),
        searchableItems = items.values.toList()
          ..sort((a, b) => a.name.compareTo(b.name));

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

  GameRecipe? defaultRecipeFor(String itemClassName) {
    final list = recipesFor(itemClassName);
    if (list.isEmpty) return null;
    return list.firstWhere((r) => !r.alternate, orElse: () => list.first);
  }

  String itemName(String className) =>
      items[className]?.name ?? className.replaceAll('Desc_', '').replaceAll('_C', '');
}
