import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/note_data.dart';
import 'auth_service.dart';

const _localKey = 'satisfactory-field-notes-v2';
const String _syncUrl = 'https://satisfactory-field-notes-production.up.railway.app';

class StorageService {
  final AuthService _auth;
  NoteData _data = const NoteData();
  NoteData get data => _data;

  StorageService(this._auth);

  Future<NoteData> load() async {
    // Try remote if signed in
    if (_auth.isSignedIn) {
      try {
        final token = await _auth.getFreshToken();
        final res = await http
            .get(
              Uri.parse('$_syncUrl/api/notes'),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final json = jsonDecode(res.body);
          if (json != null && json is Map<String, dynamic>) {
            _data = NoteData.fromJson(json);
            await _saveLocal();
            return _data;
          }
        }
      } catch (_) {}
    }

    // Fall back to local
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKey);
    if (raw != null) {
      try {
        _data = NoteData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    return _data;
  }

  Future<void> save(NoteData next) async {
    _data = next;
    await _saveLocal();
    _syncRemote();
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localKey, jsonEncode(_data.toJson()));
  }

  void _syncRemote() {
    if (!_auth.isSignedIn) return;
    _auth.getFreshToken().then((token) {
      if (token == null) return;
      http
          .put(
            Uri.parse('$_syncUrl/api/notes'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(_data.toJson()),
          )
          .timeout(const Duration(seconds: 5))
          .catchError((_) => http.Response('', 0));
    });
  }
}

class NotesNotifier extends StateNotifier<NoteData> {
  final StorageService _storage;

  NotesNotifier(this._storage) : super(const NoteData()) {
    _load();
  }

  Future<void> _load() async {
    state = await _storage.load();
  }

  Future<void> reload() async {
    state = await _storage.load();
  }

  Future<void> _save(NoteData next) async {
    state = next;
    await _storage.save(next);
  }

  // Session tasks
  void addTask(String text) =>
      _save(state.copyWith(session: [
        ...state.session,
        SessionTask(id: DateTime.now().millisecondsSinceEpoch, text: text),
      ]));

  void toggleTask(int id) =>
      _save(state.copyWith(
        session: state.session
            .map((t) => t.id == id ? t.copyWith(done: !t.done) : t)
            .toList(),
      ));

  void deleteTask(int id) =>
      _save(state.copyWith(
        session: state.session.where((t) => t.id != id).toList(),
      ));

  void clearCompleted() =>
      _save(state.copyWith(
        session: state.session.where((t) => !t.done).toList(),
      ));

  // Needs
  void addNeed(String text) =>
      _save(state.copyWith(needs: [
        ...state.needs,
        Need(id: DateTime.now().millisecondsSinceEpoch, text: text),
      ]));

  void deleteNeed(int id) =>
      _save(state.copyWith(
        needs: state.needs.where((n) => n.id != id).toList(),
      ));

  // Factories
  void addFactory(String name, String produces, String status,
          {Map<String, dynamic>? plannerData}) =>
      _save(state.copyWith(factories: [
        ...state.factories,
        Factory(
          id: DateTime.now().millisecondsSinceEpoch,
          name: name,
          produces: produces,
          status: status,
          plannerData: plannerData,
        ),
      ]));

  void cycleFactoryStatus(int id) =>
      _save(state.copyWith(
        factories: state.factories
            .map((f) => f.id == id ? f.cycleStatus() : f)
            .toList(),
      ));

  void deleteFactory(int id) =>
      _save(state.copyWith(
        factories: state.factories.where((f) => f.id != id).toList(),
      ));

  void renameFactory(int id, String newName) =>
      _save(state.copyWith(
        factories: state.factories
            .map((f) => f.id == id
                ? Factory(
                    id: f.id,
                    name: newName,
                    produces: f.produces,
                    status: f.status,
                    plannerData: f.plannerData,
                  )
                : f)
            .toList(),
      ));

  // Scratch
  void updateScratch(String text) =>
      _save(state.copyWith(scratch: text));
}

final storageServiceProvider = Provider(
  (ref) => StorageService(ref.watch(authServiceProvider)),
);

final notesProvider = StateNotifierProvider<NotesNotifier, NoteData>(
  (ref) => NotesNotifier(ref.watch(storageServiceProvider)),
);
