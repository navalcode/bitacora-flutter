import 'package:bitacora/domain/tasks.dart';
import 'package:bitacora/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fakes.dart';

void main() {
  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDownAll(() => WidgetController.hitTestWarningShouldBeFatal = false);
  testWidgets(
    'detail, completion, back and pending filter form a working journey',
    (tester) async {
      final store = MemoryStore();
      final model = TaskController(ImmediateSource(), store);
      await model.initialize();
      await tester.pumpWidget(
        BitacoraApp(
          model: model,
          environment: AppEnvironment.dev,
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      await showItem(tester, find.byKey(const ValueKey('task-alba')));
      await tester.tap(find.text('Check Alba lookout'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('detail-complete')));
      await tester.pumpAndSettle();
      expect(find.text('Mark pending'), findsOneWidget);
      expect(store.ids, {'alba'});
      await tester.pageBack();
      await tester.pumpAndSettle();
      await showItem(
        tester,
        find.byKey(const ValueKey('filter-pending')),
        step: -150,
      );
      await tester.tap(find.byKey(const ValueKey('filter-pending')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('task-alba')), findsNothing);
    },
  );

  testWidgets('Spanish search finds accented titles without accents', (
    tester,
  ) async {
    final model = TaskController(ImmediateSource(), MemoryStore());
    await model.initialize();
    await tester.pumpWidget(
      BitacoraApp(
        model: model,
        environment: AppEnvironment.dev,
        locale: const Locale('es'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('search')), 'revision');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('task-cedro')), findsOneWidget);
    expect(find.byKey(const ValueKey('task-alba')), findsNothing);
  });

  for (final language in ['en', 'es']) {
    testWidgets(
      '$language counts only current tasks while retaining hidden saved IDs',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.8;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final store = MemoryStore()..ids = {'alba', 'future-task'};
        final source = ImmediateSource();
        final model = TaskController(source, store);
        await model.initialize();
        await tester.pumpWidget(
          BitacoraApp(
            model: model,
            environment: AppEnvironment.dev,
            locale: Locale(language),
          ),
        );
        await tester.pumpAndSettle();
        final count = language == 'en' ? 'Completed' : 'Completadas';
        expect(find.text('$count: 1 / 6'), findsOneWidget);
        source.tasks = [bundledTasks[1]];
        await model.refresh();
        await tester.pumpAndSettle();
        expect(find.text('$count: 0 / 1'), findsOneWidget);
        await showItem(tester, find.byKey(const ValueKey('complete-cedro')));
        await tester.tap(find.byKey(const ValueKey('complete-cedro')));
        await tester.pumpAndSettle();
        expect(store.ids, {'alba', 'cedro', 'future-task'});
        source.tasks = bundledTasks;
        await model.refresh();
        await tester.pumpAndSettle();
        await showItem(tester, find.text('$count: 2 / 6'), step: -150);
        expect(find.text('$count: 2 / 6'), findsOneWidget);
        expect(model.completed, {'alba', 'cedro'});
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      '$language storage read failure explains recovery and blocks writes',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.8;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final store = MemoryStore()..failLoad = true;
        final model = TaskController(ImmediateSource(), store);
        await model.initialize();
        await tester.pumpWidget(
          BitacoraApp(
            model: model,
            environment: AppEnvironment.dev,
            locale: Locale(language),
          ),
        );
        await tester.pumpAndSettle();
        // Unknown saved status must not be presented as zero completed tasks.
        expect(
          find.text(
            language == 'en' ? 'Completed: 0 / 6' : 'Completadas: 0 / 6',
          ),
          findsNothing,
        );
        final message = language == 'en'
            ? 'Saved task status could not be read. Reload tasks to enable changes.'
            : 'No se puede leer el estado guardado. Vuelve a cargar las tareas para poder editarlas.';
        final reload = language == 'en' ? 'Reload tasks' : 'Recargar tareas';
        await showItem(tester, find.text(message));
        expect(find.text(message), findsOneWidget);
        await showItem(tester, find.byKey(const ValueKey('complete-alba')));
        expect(
          tester
              .widget<Checkbox>(find.byKey(const ValueKey('complete-alba')))
              .onChanged,
          isNull,
        );
        expect(store.writes, 0);
        store.failLoad = false;
        await showItem(tester, find.text(reload), step: -150);
        await tester.tap(find.text(reload));
        await tester.pumpAndSettle();
        // Removing the notice moves this row above the retained scroll offset.
        await showItem(
          tester,
          find.byKey(const ValueKey('complete-alba')),
          step: -150,
        );
        expect(
          tester
              .widget<Checkbox>(find.byKey(const ValueKey('complete-alba')))
              .onChanged,
          isNotNull,
        );
        await tester.tap(find.byKey(const ValueKey('complete-alba')));
        await tester.pumpAndSettle();
        expect(store.ids, {'alba'});
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '$language failed save keeps status and offers a working reload',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.8;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final store = MemoryStore()..failSave = true;
        final model = TaskController(ImmediateSource(), store);
        await model.initialize();
        await tester.pumpWidget(
          BitacoraApp(
            model: model,
            environment: AppEnvironment.dev,
            locale: Locale(language),
          ),
        );
        await tester.pumpAndSettle();
        await showItem(tester, find.byKey(const ValueKey('task-alba')));
        await tester.tap(
          find.text(
            language == 'en' ? 'Check Alba lookout' : 'Revisar el mirador Alba',
          ),
        );
        await tester.pumpAndSettle();
        await showItem(tester, find.byKey(const ValueKey('detail-complete')));
        await tester.tap(find.byKey(const ValueKey('detail-complete')));
        await tester.pumpAndSettle();
        expect(store.ids, isEmpty);
        expect(model.completed, isEmpty);
        await showItem(tester, find.byKey(const ValueKey('detail-complete')));
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('detail-complete')),
              )
              .onPressed,
          isNull,
        );
        final message = language == 'en'
            ? 'Saving could not be confirmed. Reload tasks before trying again.'
            : 'No se ha podido confirmar el guardado. Recarga las tareas antes de intentarlo de nuevo.';
        final reload = language == 'en' ? 'Reload tasks' : 'Recargar tareas';
        await showItem(tester, find.text(message), step: -150);
        expect(find.text(message), findsOneWidget);
        store.failSave = false;
        await showItem(tester, find.text(reload));
        await tester.tap(find.text(reload));
        await tester.pumpAndSettle();
        expect(find.text(message), findsNothing);
        await showItem(tester, find.byKey(const ValueKey('detail-complete')));
        await tester.tap(find.byKey(const ValueKey('detail-complete')));
        await tester.pumpAndSettle();
        expect(store.ids, {'alba'});
        expect(
          find.text(language == 'en' ? 'Mark pending' : 'Marcar pendiente'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '$language unconfirmed save blocks detail and list until reload',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.8;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final store = MemoryStore()..failAfterSave = true;
        final model = TaskController(ImmediateSource(), store);
        await model.initialize();
        await tester.pumpWidget(
          BitacoraApp(
            model: model,
            environment: AppEnvironment.dev,
            locale: Locale(language),
          ),
        );
        await tester.pumpAndSettle();
        await showItem(tester, find.byKey(const ValueKey('task-alba')));
        await showItem(
          tester,
          find.text(
            language == 'en' ? 'Check Alba lookout' : 'Revisar el mirador Alba',
          ),
          step: -150,
        );
        await tester.tap(
          find.text(
            language == 'en' ? 'Check Alba lookout' : 'Revisar el mirador Alba',
          ),
        );
        await tester.pumpAndSettle();
        await showItem(tester, find.byKey(const ValueKey('detail-complete')));
        await tester.tap(find.byKey(const ValueKey('detail-complete')));
        await tester.pumpAndSettle();
        expect(store.ids, {'alba'});
        expect(model.completed, isEmpty);
        await showItem(tester, find.byKey(const ValueKey('detail-complete')));
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('detail-complete')),
              )
              .onPressed,
          isNull,
        );
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        for (final id in ['alba', 'cedro']) {
          await showItem(tester, find.byKey(ValueKey('complete-$id')));
          expect(
            tester
                .widget<Checkbox>(find.byKey(ValueKey('complete-$id')))
                .onChanged,
            isNull,
          );
        }
        expect(store.writes, 1);
        store.failAfterSave = false;
        final reload = language == 'en' ? 'Reload tasks' : 'Recargar tareas';
        await showItem(tester, find.text(reload), step: -150);
        await tester.tap(find.text(reload));
        await tester.pumpAndSettle();
        expect(model.completed, {'alba'});
        await showItem(
          tester,
          find.byKey(const ValueKey('complete-alba')),
          step: -150,
        );
        expect(
          tester
              .widget<Checkbox>(find.byKey(const ValueKey('complete-alba')))
              .value,
          isTrue,
        );
        expect(
          tester
              .widget<Checkbox>(find.byKey(const ValueKey('complete-alba')))
              .onChanged,
          isNotNull,
        );
        await showItem(
          tester,
          find.text(
            language == 'en' ? 'Check Alba lookout' : 'Revisar el mirador Alba',
          ),
          step: -150,
        );
        await tester.tap(
          find.text(
            language == 'en' ? 'Check Alba lookout' : 'Revisar el mirador Alba',
          ),
        );
        await tester.pumpAndSettle();
        await showItem(tester, find.byKey(const ValueKey('detail-complete')));
        expect(
          find.text(language == 'en' ? 'Mark pending' : 'Marcar pendiente'),
          findsOneWidget,
        );
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('detail-complete')),
              )
              .onPressed,
          isNotNull,
        );
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await showItem(tester, find.byKey(const ValueKey('complete-cedro')));
        await tester.tap(find.byKey(const ValueKey('complete-cedro')));
        await tester.pumpAndSettle();
        expect(store.ids, {'alba', 'cedro'});
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('offline notice preserves usable task content', (tester) async {
    final model = TaskController(ImmediateSource(), MemoryStore());
    await model.initialize();
    await model.selectScenario(DemoScenario.offline);
    await tester.pumpWidget(
      BitacoraApp(
        model: model,
        environment: AppEnvironment.prod,
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'The update failed. The task list is still available. Choose Normal loading in Loading scenarios.',
      ),
      findsOneWidget,
    );
    await showItem(tester, find.byKey(const ValueKey('task-alba')));
    expect(find.byKey(const ValueKey('task-alba')), findsOneWidget);
  });

  testWidgets(
    'resizing a detail preserves its route and acknowledged completion',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = MemoryStore();
      final model = TaskController(ImmediateSource(), store);
      await model.initialize();
      await tester.pumpWidget(
        BitacoraApp(
          model: model,
          environment: AppEnvironment.dev,
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      await showItem(tester, find.byKey(const ValueKey('task-alba')));
      await tester.tap(find.text('Check Alba lookout'));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(360, 800);
      await tester.pumpAndSettle();
      await showItem(tester, find.byKey(const ValueKey('detail-complete')));
      await tester.tap(find.byKey(const ValueKey('detail-complete')));
      await tester.pumpAndSettle();
      expect(store.ids, {'alba'});
      expect(find.text('Mark pending'), findsOneWidget);
      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpAndSettle();
      expect(find.text('Mark pending'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await showItem(tester, find.text('Completed: 1 / 6'), step: -150);
      expect(find.text('Completed: 1 / 6'), findsOneWidget);
    },
  );

  testWidgets(
    'narrow viewport and large text keep the board and detail usable',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final model = TaskController(ImmediateSource(), MemoryStore());
      await model.initialize();
      await tester.pumpWidget(
        BitacoraApp(
          model: model,
          environment: AppEnvironment.dev,
          locale: const Locale('es'),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await showItem(tester, find.byKey(const ValueKey('task-alba')));
      await tester.tap(find.text('Revisar el mirador Alba'));
      await tester.pumpAndSettle();
      await showItem(tester, find.byKey(const ValueKey('detail-complete')));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('detail-complete')), findsOneWidget);
    },
  );
}

Future<void> showItem(
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
