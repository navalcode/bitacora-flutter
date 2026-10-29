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

  testWidgets(
    'failed storage is visible and completion controls are disabled',
    (tester) async {
      final store = MemoryStore()..failLoad = true;
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
      await showItem(tester, find.byKey(const ValueKey('complete-alba')));
      final checkbox = tester.widget<Checkbox>(
        find.byKey(const ValueKey('complete-alba')),
      );
      expect(checkbox.onChanged, isNull);
      expect(store.writes, 0);
    },
  );

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
      find.text('The update is unavailable. The demo list is still here.'),
      findsOneWidget,
    );
    await showItem(tester, find.byKey(const ValueKey('task-alba')));
    expect(find.byKey(const ValueKey('task-alba')), findsOneWidget);
  });

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
