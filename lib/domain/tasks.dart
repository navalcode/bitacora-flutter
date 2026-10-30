import 'dart:async';

import 'package:flutter/foundation.dart';

enum TaskArea { observe, review, maintain }

enum TaskFilter { all, pending, completed }

enum DemoScenario { connected, offline, slow }

enum SyncState { idle, loading, ready, offline, timeout }

enum AppEnvironment {
  dev,
  prod;

  static AppEnvironment parse(String value) => switch (value) {
    'dev' => AppEnvironment.dev,
    'prod' => AppEnvironment.prod,
    _ => throw ArgumentError.value(value, 'environment', 'Use dev or prod'),
  };
}

@immutable
class FieldTask {
  const FieldTask(
    this.id,
    this.area,
    this.titleEs,
    this.titleEn,
    this.detailEs,
    this.detailEn,
  );
  final String id;
  final TaskArea area;
  final String titleEs;
  final String titleEn;
  final String detailEs;
  final String detailEn;

  String title(String language) => language == 'es' ? titleEs : titleEn;
  String detail(String language) => language == 'es' ? detailEs : detailEn;
}

const bundledTasks = [
  FieldTask(
    'alba',
    TaskArea.observe,
    'Revisar el mirador Alba',
    'Check Alba lookout',
    'Comprueba que el acceso al mirador esté despejado y que la señal se vea desde el cruce.',
    'Check that the access path is clear and the lookout sign is visible from the junction.',
  ),
  FieldTask(
    'cedro',
    TaskArea.review,
    'Revisión de la señal Cedro',
    'Review the Cedar sign',
    'Comprueba que el cartel del sendero Cedro se lea bien y señale el inicio del recorrido.',
    'Check that the Cedar trail sign is legible and points towards the trail entrance.',
  ),
  FieldTask(
    'norte',
    TaskArea.maintain,
    'Preparar el refugio Norte',
    'Prepare the North shelter',
    'Revisa el inventario de la jornada: mapa, linterna y cuaderno.',
    'Check the day’s inventory: map, torch and notebook.',
  ),
  FieldTask(
    'cauce',
    TaskArea.observe,
    'Revisar el paso del Cauce',
    'Check the river crossing',
    'Comprueba que las señales del paso se vean desde las dos orillas.',
    'Check that the crossing signs are visible from both banks.',
  ),
  FieldTask(
    'sendero',
    TaskArea.review,
    'Actualizar la ficha del sendero',
    'Update the trail note',
    'Comprueba que la ficha del sendero incluya el inicio, la distancia y la duración estimada.',
    'Check that the trail note includes the starting point, distance and estimated duration.',
  ),
  FieldTask(
    'equipo',
    TaskArea.maintain,
    'Ordenar el equipo de campo',
    'Organize field equipment',
    'Ordena el material de la lista y prepara el equipo para la siguiente jornada.',
    'Organize the checklist items and prepare the equipment for the next workday.',
  ),
];

abstract interface class CompletionStore {
  Future<Set<String>> load();
  Future<void> save(Set<String> ids);
}

abstract interface class TaskSource {
  Future<List<FieldTask>> fetch(DemoScenario scenario);
}

class DemoOffline implements Exception {}

class BundledTaskSource implements TaskSource {
  @override
  Future<List<FieldTask>> fetch(DemoScenario scenario) async {
    await Future<void>.delayed(
      Duration(milliseconds: scenario == DemoScenario.slow ? 5000 : 400),
    );
    if (scenario == DemoScenario.offline) throw DemoOffline();
    return bundledTasks;
  }
}

/// Owns presentation state. A superseded Future is ignored, not transport-cancelled.
class TaskController extends ChangeNotifier {
  TaskController(
    this.source,
    this.store, {
    this.timeout = const Duration(seconds: 3),
  });
  final TaskSource source;
  final CompletionStore store;
  final Duration timeout;
  List<FieldTask> _items = bundledTasks;
  Set<String> _completed = {};
  String _query = '';
  TaskFilter _filter = TaskFilter.all;
  DemoScenario _scenario = DemoScenario.connected;
  SyncState _sync = SyncState.idle;
  bool _storageReady = false;
  bool _storageError = false;
  bool _saving = false;
  bool _disposed = false;
  int _request = 0;
  int _initialization = 0;

  List<FieldTask> get items => List.unmodifiable(_items);
  Set<String> get completed => Set.unmodifiable(_completed);
  String get query => _query;
  TaskFilter get filter => _filter;
  DemoScenario get scenario => _scenario;
  SyncState get sync => _sync;
  bool get storageReady => _storageReady;
  bool get storageError => _storageError;
  bool get saving => _saving;

  List<FieldTask> visible(String language) => List.unmodifiable(
    _items.where(
      (task) =>
          (_filter == TaskFilter.all ||
              (_filter == TaskFilter.completed) ==
                  _completed.contains(task.id)) &&
          _searchKey(task.title(language)).contains(_searchKey(_query)),
    ),
  );

  Future<void> initialize() async {
    if (_disposed || _saving) return;
    final attempt = ++_initialization;
    _storageReady = false;
    notifyListeners();
    try {
      final ids = await store.load();
      if (_disposed || attempt != _initialization) return;
      final known = _items.map((task) => task.id).toSet();
      _completed = ids.intersection(known);
      _storageReady = true;
      _storageError = false;
    } catch (_) {
      if (_disposed || attempt != _initialization) return;
      _storageError = true;
    }
    notifyListeners();
    await refresh();
  }

  void queryChanged(String value) {
    if (_disposed) return;
    _query = value;
    notifyListeners();
  }

  void filterChanged(TaskFilter value) {
    if (_disposed) return;
    _filter = value;
    notifyListeners();
  }

  Future<void> selectScenario(DemoScenario value) {
    if (_disposed) return Future.value();
    _scenario = value;
    return refresh();
  }

  Future<void> refresh() async {
    if (_disposed) return;
    final request = ++_request;
    final selected = _scenario;
    _sync = SyncState.loading;
    notifyListeners();
    try {
      final result = await source.fetch(selected).timeout(timeout);
      if (_disposed || request != _request) return;
      _items = List.unmodifiable(result);
      _sync = SyncState.ready;
    } on TimeoutException {
      if (_disposed || request != _request) return;
      _sync = SyncState.timeout;
    } on DemoOffline {
      if (_disposed || request != _request) return;
      _sync = SyncState.offline;
    }
    if (!_disposed && request == _request) notifyListeners();
  }

  Future<void> setCompleted(String id, bool value) async {
    if (_disposed || !_storageReady || _saving) return;
    if (!_items.any((task) => task.id == id)) {
      throw ArgumentError.value(id, 'id', 'Unknown task');
    }
    if (_completed.contains(id) == value) return;
    final updated = {..._completed};
    value ? updated.add(id) : updated.remove(id);
    _saving = true;
    notifyListeners();
    try {
      await store.save(Set.unmodifiable(updated));
      if (_disposed) return;
      _completed = updated;
      _storageError = false;
    } catch (_) {
      if (!_disposed) _storageError = true;
    } finally {
      _saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _request++;
    _initialization++;
    super.dispose();
  }
}

String _searchKey(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp('[áàäâ]'), 'a')
    .replaceAll(RegExp('[éèëê]'), 'e')
    .replaceAll(RegExp('[íìïî]'), 'i')
    .replaceAll(RegExp('[óòöô]'), 'o')
    .replaceAll(RegExp('[úùüû]'), 'u');
