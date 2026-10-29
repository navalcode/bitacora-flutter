import 'dart:async';
import 'package:bitacora/domain/tasks.dart';
import 'package:bitacora/l10n/copy.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fakes.dart';

void main() {
  late MemoryStore store;
  late TaskController model;
  setUp(() {
    store = MemoryStore();
    model = TaskController(ImmediateSource(), store);
  });
  tearDown(() => model.dispose());

  test('loads known saved IDs and ignores IDs outside the catalog', () async {
    store.ids = {'alba', 'not-a-task'};
    await model.initialize();
    expect(model.completed, {'alba'});
    expect(model.storageReady, isTrue);
    expect(model.sync, SyncState.ready);
  });

  test(
    'failed reads block writes instead of overwriting unknown stored state',
    () async {
      store.failLoad = true;
      await model.initialize();
      await model.setCompleted('alba', true);
      expect(model.storageError, isTrue);
      expect(model.storageReady, isFalse);
      expect(store.writes, 0);
      expect(model.items, hasLength(6));
    },
  );

  test('storage can recover on explicit retry', () async {
    store.failLoad = true;
    await model.initialize();
    store.failLoad = false;
    store.ids = {'cedro'};
    await model.initialize();
    expect(model.completed, {'cedro'});
    expect(model.storageReady, isTrue);
    expect(model.storageError, isFalse);
  });

  test('repeated completion does not repeat a write', () async {
    await model.initialize();
    await model.setCompleted('alba', true);
    await model.setCompleted('alba', true);
    expect(store.writes, 1);
    expect(store.ids, {'alba'});
    await model.setCompleted('alba', false);
    expect(store.ids, isEmpty);
  });

  test('failed writes retain the previous state and can be retried', () async {
    await model.initialize();
    store.failSave = true;
    await model.setCompleted('alba', true);
    expect(model.completed, isEmpty);
    expect(model.storageError, isTrue);
    store.failSave = false;
    await model.setCompleted('alba', true);
    expect(model.completed, {'alba'});
    expect(model.storageError, isFalse);
  });

  test('a pending write disables another write until it completes', () async {
    await model.initialize();
    store.gate = Completer<void>();
    final saving = model.setCompleted('alba', true);
    expect(model.saving, isTrue);
    await model.setCompleted('cedro', true);
    expect(store.writes, 1);
    expect(model.completed, isEmpty);
    store.gate!.complete();
    await saving;
    expect(model.completed, {'alba'});
    expect(model.saving, isFalse);
  });

  test('unknown task cannot be persisted', () async {
    await model.initialize();
    await expectLater(model.setCompleted('unknown', true), throwsArgumentError);
    expect(store.writes, 0);
  });

  test(
    'source failure preserves bundled content and supports recovery',
    () async {
      await model.initialize();
      await model.selectScenario(DemoScenario.offline);
      expect(model.sync, SyncState.offline);
      expect(model.items, bundledTasks);
      await model.selectScenario(DemoScenario.connected);
      expect(model.sync, SyncState.ready);
    },
  );

  test('a stale response cannot overwrite the newest result', () async {
    final source = ControlledSource();
    final controller = TaskController(source, store);
    final first = controller.refresh();
    final second = controller.refresh();
    source.requests[1].complete([bundledTasks[1]]);
    await second;
    source.requests[0].complete([bundledTasks[0]]);
    await first;
    expect(controller.items.single.id, 'cedro');
    controller.dispose();
  });

  test('an obsolete failure cannot replace the newest success', () async {
    final source = ControlledSource();
    final controller = TaskController(source, store);
    final first = controller.refresh();
    final second = controller.refresh();
    source.requests[1].complete(bundledTasks);
    await second;
    source.requests[0].completeError(DemoOffline());
    await first;
    expect(controller.sync, SyncState.ready);
    controller.dispose();
  });

  test('deadline reports timeout with virtual time and keeps the list', () {
    fakeAsync((time) {
      final controller = TaskController(ControlledSource(), store);
      controller.refresh();
      time.elapse(const Duration(seconds: 4));
      time.flushMicrotasks();
      expect(controller.sync, SyncState.timeout);
      expect(controller.items, bundledTasks);
      controller.dispose();
    });
  });

  test('disposed controller ignores an in-flight result', () async {
    final source = ControlledSource();
    final controller = TaskController(source, store);
    var notifications = 0;
    controller.addListener(() => notifications++);
    final pending = controller.refresh();
    controller.dispose();
    source.requests.single.complete([bundledTasks[1]]);
    await pending;
    expect(notifications, 1);
  });

  test('search ignores case, whitespace and supported Spanish diacritics', () {
    model.queryChanged('  REVISION ');
    expect(model.visible('es').single.id, 'cedro');
  });

  test('filter and completion compose without fetching again', () async {
    await model.initialize();
    await model.setCompleted('alba', true);
    model.filterChanged(TaskFilter.completed);
    expect(model.visible('en').single.id, 'alba');
    model.filterChanged(TaskFilter.pending);
    expect(model.visible('en').any((task) => task.id == 'alba'), isFalse);
  });

  test('callers cannot mutate exposed state', () {
    expect(() => model.items.clear(), throwsUnsupportedError);
    expect(() => model.completed.add('alba'), throwsUnsupportedError);
  });

  test('environment names are explicit and fail on typos', () {
    expect(AppEnvironment.parse('prod'), AppEnvironment.prod);
    expect(() => AppEnvironment.parse('production'), throwsArgumentError);
  });

  test('both languages cover every UI message', () {
    for (final messages in translations.values) {
      expect(messages.keys.toSet(), CopyKey.values.toSet());
    }
  });
}
