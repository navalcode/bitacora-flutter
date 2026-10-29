import 'package:bitacora/data/completion_preferences.dart';
import 'package:bitacora/domain/tasks.dart';
import 'package:bitacora/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
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
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('task-alba')),
      150,
      scrollable: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check Alba lookout'));
    await tester.pumpAndSettle();
    await model.setCompleted('alba', true);
    await tester.pumpAndSettle();
    expect(find.text('Mark pending'), findsOneWidget);
    await binding.takeScreenshot('detail');
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
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Completed: 1 / 6'), findsOneWidget);
    restored.filterChanged(TaskFilter.pending);
    await tester.pumpAndSettle();
    expect(restored.visible('en'), hasLength(5));
    await binding.takeScreenshot('board');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    // Leave this one fictional completion for a separate process-restart smoke check.
  });
}
