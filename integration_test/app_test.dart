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
}
