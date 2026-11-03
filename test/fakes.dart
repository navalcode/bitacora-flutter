import 'dart:async';
import 'package:bitacora/domain/tasks.dart';

class MemoryStore implements CompletionStore {
  Set<String> ids = {};
  bool failLoad = false;
  bool failSave = false;
  bool failAfterSave = false;
  int writes = 0;
  Completer<void>? gate;
  Completer<void>? loadGate;
  @override
  Future<Set<String>> load() async {
    if (loadGate != null) await loadGate!.future;
    if (failLoad) throw StateError('Synthetic read failure');
    return {...ids};
  }

  @override
  Future<void> save(Set<String> value) async {
    writes++;
    if (gate != null) await gate!.future;
    if (failSave) throw StateError('Synthetic write failure');
    ids = {...value};
    if (failAfterSave) throw StateError('Synthetic lost acknowledgement');
  }
}

class ImmediateSource implements TaskSource {
  @override
  Future<List<FieldTask>> fetch(DemoScenario scenario) async {
    if (scenario == DemoScenario.offline) throw DemoOffline();
    return bundledTasks;
  }
}

class ControlledSource implements TaskSource {
  final requests = <Completer<List<FieldTask>>>[];
  @override
  Future<List<FieldTask>> fetch(DemoScenario scenario) {
    final request = Completer<List<FieldTask>>();
    requests.add(request);
    return request.future;
  }
}
