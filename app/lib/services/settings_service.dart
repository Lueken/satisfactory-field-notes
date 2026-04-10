import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_settings.dart';

const _settingsKey = 'game-settings-v1';

class SettingsNotifier extends StateNotifier<GameSettings> {
  SettingsNotifier() : super(const GameSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw != null) {
      try {
        state = GameSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(state.toJson()));
  }

  void toggleAlternate(String className) {
    final next = Set<String>.from(state.unlockedAlternates);
    if (next.contains(className)) {
      next.remove(className);
    } else {
      next.add(className);
    }
    state = state.copyWith(unlockedAlternates: next);
    _save();
  }

  void setAllAlternates(Set<String> classNames) {
    state = state.copyWith(unlockedAlternates: classNames);
    _save();
  }

  void setBeltTier(int tier) {
    state = state.copyWith(beltTier: tier);
    _save();
  }

  void setMinerTier(int tier) {
    state = state.copyWith(minerTier: tier);
    _save();
  }

  void setOverclocking(bool enabled) {
    state = state.copyWith(overclockingEnabled: enabled);
    _save();
  }

  void setSomersloop(bool enabled) {
    state = state.copyWith(somersloopEnabled: enabled);
    _save();
  }

  void setAdvancedPlanner(bool advanced) {
    state = state.copyWith(advancedPlanner: advanced);
    _save();
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, GameSettings>((_) => SettingsNotifier());
