import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../models/wiki_result.dart';

const _wikiApi = 'https://satisfactory.wiki.gg/api.php';
const _wikiBase = 'https://satisfactory.wiki.gg/wiki';

class WikiService {
  Future<WikiResult> lookup(String query) async {
    // Step 1: fuzzy search for canonical title
    final searchUrl = Uri.parse(
      '$_wikiApi?action=opensearch&search=${Uri.encodeComponent(query)}&limit=5&format=json&origin=*',
    );
    final searchRes = await http.get(searchUrl);
    if (searchRes.statusCode != 200) {
      throw Exception('Search failed: HTTP ${searchRes.statusCode}');
    }
    final searchData = jsonDecode(searchRes.body) as List;
    final titles = (searchData[1] as List).cast<String>();
    if (titles.isEmpty) {
      throw Exception('No results for "$query"');
    }
    final title = titles.first;
    final wikiUrl =
        '$_wikiBase/${Uri.encodeComponent(title.replaceAll(' ', '_'))}';

    // Step 2: rendered HTML
    final parseUrl = Uri.parse(
      '$_wikiApi?action=parse&page=${Uri.encodeComponent(title)}&prop=text&format=json&origin=*',
    );
    final parseRes = await http.get(parseUrl);
    if (parseRes.statusCode != 200) {
      throw Exception('Parse failed: HTTP ${parseRes.statusCode}');
    }
    final parseData = jsonDecode(parseRes.body) as Map<String, dynamic>;
    final htmlStr =
        (parseData['parse'] as Map?)?['text']?['*'] as String? ?? '';
    if (htmlStr.isEmpty) {
      throw Exception('Page found but no content returned');
    }

    return _parseHtml(title, htmlStr, wikiUrl);
  }

  WikiResult _parseHtml(String title, String htmlStr, String wikiUrl) {
    final doc = html_parser.parse(htmlStr);

    // Description: collect all <p> content before the first heading
    final descParts = <String>[];
    for (final p in doc.querySelectorAll('p')) {
      final text = p.text.trim();
      if (text.isEmpty || text.length < 10) continue;
      descParts.add(text);
      if (descParts.length >= 3) break;
    }
    final description = descParts.join('\n\n');

    // Infobox stats
    final stats = <String, String>{};
    for (final label in doc.querySelectorAll('.pi-data-label')) {
      final key = label.text.trim();
      final val = label.nextElementSibling?.text.trim();
      if (val != null && val.isNotEmpty) {
        stats[key] = val;
      }
    }

    // All recipes from rendered tables, separated by section heading
    final allRecipes = <WikiRecipe>[];
    for (final table in doc.querySelectorAll('table.recipetable')) {
      for (final row in table.querySelectorAll('tbody > tr')) {
        if (row.querySelector('th') != null) continue;
        final cells = row.querySelectorAll('td');
        if (cells.length < 4) continue;

        final recipeName = cells[0].text.trim();
        final inputs = _parseItems(cells[1]);
        final outputs = _parseItems(cells[3]);

        final buildingLink = cells[2].querySelector('a');
        final building = buildingLink?.text.trim();
        final timeMatch =
            RegExp(r'(\d+(?:\.\d+)?)\s*sec').firstMatch(cells[2].text);
        final time = timeMatch != null ? '${timeMatch.group(1)}s' : null;

        if (inputs.isNotEmpty || outputs.isNotEmpty) {
          allRecipes.add(WikiRecipe(
            name: recipeName,
            isAlternate: recipeName.toLowerCase().contains('alternate'),
            inputs: inputs,
            outputs: outputs,
            building: building,
            time: time,
          ));
        }
      }
    }

    // Separate: recipes that produce this item vs recipes that use it.
    // The first recipetable on the page is "Obtaining/Crafting" (produces this item).
    // The second is "Usage/Crafting" (uses this item as ingredient).
    // We detect by checking if the item name appears in outputs vs inputs.
    final titleLower = title.toLowerCase();
    final producingRecipes = <WikiRecipe>[];
    final usingRecipes = <WikiRecipe>[];

    for (final recipe in allRecipes) {
      final producesTarget =
          recipe.outputs.any((o) => o.name.toLowerCase() == titleLower);
      if (producesTarget) {
        producingRecipes.add(recipe);
      } else {
        usingRecipes.add(recipe);
      }
    }

    final defaultRecipe =
        producingRecipes.where((r) => !r.isAlternate).firstOrNull;
    final alternates =
        producingRecipes.where((r) => r.isAlternate).toList();

    return WikiResult(
      item: title,
      description: description,
      recipe: defaultRecipe,
      alternates: alternates,
      usedIn: usingRecipes,
      stats: stats,
      wikiUrl: wikiUrl,
    );
  }

  List<WikiRecipeItem> _parseItems(Element cell) {
    final items = <WikiRecipeItem>[];
    for (final el in cell.querySelectorAll('.recipe-item')) {
      final amount = (el.querySelector('.item-amount')?.text ?? '')
          .replaceAll('×', '')
          .trim();
      final name = el.querySelector('.item-name')?.text.trim();
      final perMin = el.querySelector('.item-minute')?.text.trim() ?? '';
      if (name != null && name.isNotEmpty) {
        items.add(WikiRecipeItem(name: name, amount: amount, perMin: perMin));
      }
    }
    return items;
  }
}
