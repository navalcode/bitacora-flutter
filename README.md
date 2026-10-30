# Bitácora

[Español](README.es.md) · [Build and tests](https://github.com/navalcode/bitacora-flutter/actions/workflows/checks.yml)

A Flutter app for six fictional field tasks. Search and filter the list, read a task’s instructions and mark it complete. Completion is saved on the device and restored after a restart.

The project shows asynchronous state, superseded requests, confirmed writes and recovery from storage failures. The task list ships with the app. No account, API key, location or backend is needed.

<p>
<img src="docs/images/board.png" alt="Bitácora pending tasks after completing one task" width="240">
<img src="docs/images/detail.png" alt="Bitácora detail of a completed task" width="240">
</p>

## Try it

1. Open a task, read its instructions and select **Mark complete**.
2. Return to the list and compare All, Pending and Completed. Search by title; Spanish searches accept unaccented vowels.
3. Open **Loading scenarios** with the science icon. Select Simulated failure or Slow response. The bundled tasks remain available.
4. Choose **Normal loading** to recover.
5. Restart the app to check that completion remains saved.

If saved status cannot be read, completion controls stay disabled and the app does not show a guessed completion count. If a write cannot be confirmed, the screen keeps the last confirmed state. **Reload tasks** reads the saved status before another attempt. Controller and widget tests exercise these failures without damaging real storage.

## Run it

Checked with **Flutter 3.38.7 / Dart 3.10.7**, **JDK 17** and **Android SDK 36**. Android requires API 24+. Versions and dependency hashes are recorded in `pubspec.lock`.

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter run --flavor dev
flutter build apk --debug --flavor dev
flutter build apk --release --flavor prod
flutter build web --dart-define=APP_ENV=dev --no-web-resources-cdn --pwa-strategy=none
```

Both `dev` and `prod` are demos. Android gives them different application IDs and launcher names, so they keep separate local storage. Both use `lib/main.dart`. `APP_ENV` selects the web environment label; it does not select a live service. Unknown environment names fail explicitly. To generate an AAB, use `flutter build appbundle --release --flavor prod`.

Flutter may select Android Studio’s JDK before `JAVA_HOME`. Use JDK 17 for this project through local Gradle configuration or `GRADLE_OPTS=-Dorg.gradle.java.home=/path/to/jdk-17`. Keep local paths and signing keys outside version control. Production signing is not configured.

## Native checks and screenshots

Replace `DEVICE_ID` with the target serial:

```sh
flutter test integration_test/app_test.dart --flavor dev -d DEVICE_ID
flutter drive --driver test_driver/capture.dart --target integration_test/app_test.dart --dart-define=CAPTURE_SCREENSHOTS=true --flavor dev -d DEVICE_ID --keep-app-running
```

The integration test resets only this demo’s completion IDs, recreates its controller and leaves one fictional task completed. The opt-in driver writes the two PNGs in `docs/images/`. Run Flutter build/test/drive commands sequentially in one checkout because they share generated Android files. For a normal-process restart check after an integration build, rebuild or reinstall the normal entry point without clearing its preferences; see [verification](docs/VERIFICATION.md).

## Read the code

- [tasks.dart](lib/domain/tasks.dart): models, source/store contracts, request generations, time limit and confirmed completion state.
- [completion_preferences.dart](lib/data/completion_preferences.dart): `SharedPreferencesAsync` adapter, storing only completed task IDs.
- [main.dart](lib/main.dart): dependency construction, board/detail navigation, controller ownership and recovery actions.
- [copy.dart](lib/l10n/copy.dart): Spanish/English resources with English fallback for unsupported languages.
- [controller_test.dart](test/controller_test.dart): failures, late results, disposal, timeout and read-only state.
- [widget_test.dart](test/widget_test.dart): navigation, filters, storage recovery, resizing and enlarged text.
- [app_test.dart](integration_test/app_test.dart): actual Android preferences and optional captures.

[Architecture](docs/ARCHITECTURE.md) explains why ignoring a superseded Future differs from cancelling transport, and why storage reads must succeed before editing. [DESIGN.md](DESIGN.md) records the layout, independent row actions and locally bundled Outfit font.

## Checks and limits

There are **26 controller/widget tests**: 17 controller and nine widget cases, including English/Spanish read/write recovery at 360×800 with 1.8 text scaling. [Verification](docs/VERIFICATION.md) separates the latest local runs, native persistence, browser checks, artifact audits and any failed attempts. The [workflow](https://github.com/navalcode/bitacora-flutter/actions/workflows/checks.yml) runs Android/web checks and a separate API 35 integration job.

The source export includes Android and web. Native iOS and physical devices have not been validated. Release enables R8/resource shrinking, but there is no production signing or store release. Artifact audits are advisory. Widget/emulator checks are not a formal accessibility certification.

## License

Original application code, text, data and vector artwork: [MIT](LICENSE), Manuel Naval, 2026. Flutter shells, fonts and dependencies retain their licenses in [third-party notices](THIRD_PARTY.md).
