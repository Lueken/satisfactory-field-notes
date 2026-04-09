import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_data.dart';

final gameDataProvider = FutureProvider<GameData>((ref) async {
  final raw = await rootBundle.loadString('assets/data.json');
  final json = jsonDecode(raw) as Map<String, dynamic>;

  final itemsJson = json['items'] as Map<String, dynamic>;
  final recipesJson = json['recipes'] as Map<String, dynamic>;

  final items = itemsJson.map(
    (key, value) => MapEntry(key, GameItem.fromJson(value as Map<String, dynamic>)),
  );

  final recipes = recipesJson.map(
    (key, value) => MapEntry(key, GameRecipe.fromJson(value as Map<String, dynamic>)),
  );

  return GameData(items: items, recipes: recipes);
});
