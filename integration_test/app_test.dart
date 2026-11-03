import 'package:bitacora/data/completion_preferences.dart';
import 'package:bitacora/domain/tasks.dart';
import 'package:bitacora/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const captureScreenshots = bool.fromEnvironment('CAPTURE_SCREENSHOTS');
  const language = String.fromEnvironment(
    'CAPTURE_LANGUAGE',
    defaultValue: 'en',
  );
  const prefix = String.fromEnvironment('CAPTURE_PREFIX');
  if (!['en', 'es'].contains(language) ||
      !RegExp(r'^[a-z0-9-]{0,32}$').hasMatch(prefix)) {
    throw ArgumentError('Use en/es and a short lowercase screenshot prefix');
  }
  String imageName(String name) => prefix.isEmpty ? name : '$prefix-$name';
  testWidgets('native preferences survive disposal and a fresh controller', (
    tester,
  ) async {
    final store = PreferencesCompletionStore(SharedPreferencesAsync());
    await store.save({});
    final model = TaskController(BundledTaskSource(), store);
    await model.initialize();
    await tester.pumpWidget(
      BitacoraApp(
        model: model,
        environment: AppEnvironment.dev,
        locale: const Locale(language),
      ),
    );
    await tester.pumpAndSettle();
    if (captureScreenshots) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
    }
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('task-alba')),
      150,
      scrollable: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(
        language == 'en' ? 'Check Alba lookout' : 'Revisar el mirador Alba',
      ),
    );
    await tester.pumpAndSettle();
    await model.setCompleted('alba', true);
    await tester.pumpAndSettle();
    expect(
      find.text(language == 'en' ? 'Mark pending' : 'Marcar pendiente'),
      findsOneWidget,
    );
    if (captureScreenshots) await binding.takeScreenshot(imageName('detail'));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    final restored = TaskController(
      BundledTaskSource(),
      PreferencesCompletionStore(SharedPreferencesAsync()),
    );
    await restored.initialize();
    expect(restored.completed, {'alba'});
    await tester.pumpWidget(
      BitacoraApp(
        model: restored,
        environment: AppEnvironment.dev,
        locale: const Locale(language),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(language == 'en' ? 'Completed: 1 / 6' : 'Completadas: 1 / 6'),
      findsOneWidget,
    );
    restored.filterChanged(TaskFilter.pending);
    await tester.pumpAndSettle();
    expect(restored.visible('en'), hasLength(5));
    if (captureScreenshots) await binding.takeScreenshot(imageName('board'));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    // Leave this one fictional completion for a separate process-restart smoke check.
  });

  testWidgets('native saved IDs survive a lost write acknowledgement', (
    tester,
  ) async {
    final preferences = PreferencesCompletionStore(SharedPreferencesAsync());
    await preferences.save({});
    final model = TaskController(
      BundledTaskSource(),
      LoseFirstAcknowledgement(preferences),
    );
    await model.initialize();
    await tester.pumpWidget(
      BitacoraApp(
        model: model,
        environment: AppEnvironment.dev,
        locale: const Locale(language),
      ),
    );
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('task-alba')));
    await tester.tap(
      find.text(
        language == 'en' ? 'Check Alba lookout' : 'Revisar el mirador Alba',
      ),
    );
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('detail-complete')));
    await tester.tap(find.byKey(const ValueKey('detail-complete')));
    await tester.pumpAndSettle();
    expect(await preferences.load(), {'alba'});
    expect(model.completed, isEmpty);
    await reveal(tester, find.byKey(const ValueKey('detail-complete')));
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('detail-complete')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    for (final id in ['alba', 'cedro']) {
      await reveal(tester, find.byKey(ValueKey('complete-$id')));
      expect(
        tester.widget<Checkbox>(find.byKey(ValueKey('complete-$id'))).onChanged,
        isNull,
      );
    }
    // Direct calls are protected too; disabling widgets alone is insufficient.
    await model.setCompleted('cedro', true);
    expect(await preferences.load(), {'alba'});
    final reload = language == 'en' ? 'Reload tasks' : 'Recargar tareas';
    await reveal(tester, find.text(reload), step: -150);
    await tester.tap(find.text(reload));
    await tester.pumpAndSettle();
    expect(model.completed, {'alba'});
    await reveal(
      tester,
      find.byKey(const ValueKey('complete-cedro')),
      step: -150,
    );
    expect(
      tester
          .widget<Checkbox>(find.byKey(const ValueKey('complete-cedro')))
          .onChanged,
      isNotNull,
    );
    await tester.tap(find.byKey(const ValueKey('complete-cedro')));
    await tester.pumpAndSettle();
    expect(await preferences.load(), {'alba', 'cedro'});
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    final restored = TaskController(
      BundledTaskSource(),
      PreferencesCompletionStore(SharedPreferencesAsync()),
    );
    await restored.initialize();
    expect(restored.completed, {'alba', 'cedro'});
    restored.dispose();
    // Leave both completions for a separate normal-process restart check.
  });
  testWidgets('native edits preserve IDs hidden by catalog changes', (
    tester,
  ) async {
    final preferences = PreferencesCompletionStore(SharedPreferencesAsync());
    await preferences.save({'alba', 'future-task'});
    final source = MutableCatalogSource();
    final model = TaskController(source, preferences);
    await model.initialize();
    await tester.pumpWidget(
      BitacoraApp(
        model: model,
        environment: AppEnvironment.dev,
        locale: const Locale(language),
      ),
    );
    await tester.pumpAndSettle();
    final count = language == 'en' ? 'Completed' : 'Completadas';
    expect(find.text('$count: 1 / 6'), findsOneWidget);
    source.tasks = [bundledTasks[1]];
    await model.refresh();
    await tester.pumpAndSettle();
    expect(find.text('$count: 0 / 1'), findsOneWidget);
    await reveal(tester, find.byKey(const ValueKey('complete-cedro')));
    await tester.tap(find.byKey(const ValueKey('complete-cedro')));
    await tester.pumpAndSettle();
    expect(await preferences.load(), {'alba', 'cedro', 'future-task'});
    source.tasks = bundledTasks;
    await model.refresh();
    await tester.pumpAndSettle();
    await reveal(tester, find.text('$count: 2 / 6'), step: -150);
    expect(find.text('$count: 2 / 6'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    final restored = TaskController(BundledTaskSource(), preferences);
    await restored.initialize();
    expect(restored.completed, {'alba', 'cedro'});
    expect(await preferences.load(), {'alba', 'cedro', 'future-task'});
    restored.dispose();
    // Normal entry-point restart checks can now verify the two known IDs
    // while inspecting that this fictional unknown ID remains in preferences.
  });
}

class MutableCatalogSource implements TaskSource {
  List<FieldTask> tasks = bundledTasks;
  @override
  Future<List<FieldTask>> fetch(DemoScenario scenario) async => tasks;
}

/// Injects an acknowledgement error after the real native adapter has saved.
/// It does not simulate a disk failure or change the normal application entry point.
class LoseFirstAcknowledgement implements CompletionStore {
  LoseFirstAcknowledgement(this.delegate);
  final CompletionStore delegate;
  bool failed = false;
  @override
  Future<Set<String>> load() => delegate.load();
  @override
  Future<void> save(Set<String> ids) async {
    await delegate.save(ids);
    if (!failed) {
      failed = true;
      throw StateError('Synthetic lost acknowledgement after native save');
    }
  }
}

Future<void> reveal(
  WidgetTester tester,
  Finder target, {
  double step = 150,
}) async {
  await tester.scrollUntilVisible(
    target,
    step,
    scrollable: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    ),
  );
  await tester.pumpAndSettle();
}
