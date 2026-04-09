class WikiRecipeItem {
  final String name;
  final String amount;
  final String perMin;

  const WikiRecipeItem({
    required this.name,
    required this.amount,
    this.perMin = '',
  });
}

class WikiRecipe {
  final String name;
  final bool isAlternate;
  final List<WikiRecipeItem> inputs;
  final List<WikiRecipeItem> outputs;
  final String? building;
  final String? time;

  const WikiRecipe({
    required this.name,
    required this.isAlternate,
    required this.inputs,
    required this.outputs,
    this.building,
    this.time,
  });
}

class WikiResult {
  final String item;
  final String description;
  final WikiRecipe? recipe;
  final List<WikiRecipe> alternates;
  final List<WikiRecipe> usedIn;
  final Map<String, String> stats;
  final String wikiUrl;

  const WikiResult({
    required this.item,
    required this.description,
    this.recipe,
    this.alternates = const [],
    this.usedIn = const [],
    this.stats = const {},
    required this.wikiUrl,
  });
}
