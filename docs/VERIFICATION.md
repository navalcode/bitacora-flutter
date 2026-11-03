# Verification record

## CI action runtime maintenance · 3 November 2026

The workflow pins maintained releases of checkout, Java setup, artifact upload, Gradle setup and Android setup by full commit SHA. Their JavaScript runtime is Node 24; this does not change the app's JDK 17, SDK 36, dependency versions or test commands. Flutter setup and the emulator action keep their existing reviewed commits.

`setup-gradle` uses `cache-provider: basic`, retaining GitHub Actions caching instead of selecting the new enhanced provider. `setup-android` explicitly retains command-line tools archive `12266719`, which was the previous action's implicit default. Events, read-only contents permission, disabled credential persistence, runners, timeouts and artifact retention are unchanged.

Local validation: actionlint 1.7.12 and a byte-for-byte comparison after reversing only the reviewed pins and explicit cache/SDK inputs. ShellCheck was unavailable; existing shell commands are unchanged. This validates workflow configuration, not a new hosted build. Follow the repository's current Actions run for hosted results; earlier app/runtime records below retain their original scope.

## Unconfirmed write recovery · 3 November 2026

This revision prevents a subsequent edit from overwriting an earlier save whose acknowledgement failed. `CompletionStore.save` errors do not promise rollback. `canEdit` protects the controller, list checkboxes and detail action until saved IDs are reloaded successfully. A catalog refresh cannot reopen editing. The last confirmed UI state remains visible; a reload may reveal that the unacknowledged write already succeeded.

- **31 controller/widget tests pass**: 20 controller and 11 widget cases. New coverage includes an error before/after writing, blocked edits after catalog refresh, a pending/failed reconciliation read, and a successful reload followed by a second edit without losing the first ID. List and detail are checked in English/Spanish at 360 × 800 with text scale 1.8.
- The expanded suite was run against the unchanged implementation first: 25 passed and six failed on behavior assertions after correcting the test's scroll positioning. All 31 pass after the controller/UI fix. An intermediate run found two test-harness problems: English-only `pageBack()` with a Spanish tooltip, and a row title obscured by the app bar after scrolling to its checkbox. The tests now tap the actual BackButton and reveal the title action; hit-test warnings remain fatal.
- Locked dependency resolution, analyzer, Android `dev` debug / `prod` optimized release and web builds pass. Dependency versions, lockfile, preference key/format, product copy and layout are unchanged. Gradle uses JDK 17.0.14; Flutter may start the launcher with Android Studio's JDK, as described in the README.
- Two native integration cases pass on the dedicated API 37 emulator at 360 × 800 in English / scale 1.0 and Spanish / scale 1.8. The new case writes with `PreferencesCompletionStore`, then a test-only wrapper throws an acknowledgement error. It checks disabled list/detail controls, rejection of a direct controller edit, successful reread, both saved IDs and reconstruction with a fresh controller. This injects a lost acknowledgement, not a disk or plugin fault.
- Normal debug APK process restart passes twice after a retained `flutter drive` run and reinstalling the original normal APK without clearing preferences. Its installed hash matches the retained build; distinct PIDs (4730 and 4829) show `Completed: 2 / 6` with Alba checked. This is separate from reconstructing a controller in the integration test. The emulator’s `am start -W` wait reported timeouts before UI readiness; the smoke check then waited for the actual hierarchy and confirmed state. No startup-time or device-performance claim is made.
- The normal web bundle was exercised in Spanish at 1366 × 768 and 360 × 800: detail completion, second completion from the list, both completions after full reload, empty search/clear, simulated source failure and Normal loading recovery. No document overflow or warning/error console entries observed. Browser storage faults and an English browser journey were not exercised in this block.

Advisory audits: debug **13.53 MB DEX**, release **0.95 MB DEX**, native ELF / APK ZIP 16 KB checks pass. Percentage R8 metrics are absent; the overall advisory verdict does not prove an optimization percentage, official store policy or acceptance. No new physical-device, iOS, formal accessibility, production signing or release-runtime result is claimed.

The opt-in capture driver still captures the first preferences journey with one completion. The full suite now ends with Alba and Cedar completed; normal-process checks must expect **2 / 6**, not the earlier one-completion fixture. Run Flutter build/test/drive commands sequentially and retain a normal APK before running integration. Flutter 3.38.7’s `flutter test` device cleanup stops and uninstalls its integration app. Use the documented `flutter drive --keep-app-running` command to retain preferences before replacing that APK with the normal entry point. The first normal-restart attempt after `flutter test` saw zero completions from the fresh install and is retained as an unsuccessful harness setup, not an app persistence failure.

Current normal artifact SHA-256:

- `app-dev-debug.apk`: `3e81145c0c41b1ea7b9b48e45918620665a808ad6d69cfbb252fddf344261e68`.
- `app-prod-release.apk`: `b489a5bf4bb32abf4b1ca4cb1e2575ded386fc00b1e5ca4cf5afa26e7c1a6194`.

## Earlier editorial verification · 30 October 2026

30 October 2026. This revision rewrites task instructions and recovery messages, distinguishes storage reads from unconfirmed writes, and hides the completed count until saved status has been read. The source/store algorithms and dependency lock remain unchanged.

## Local checks

- Flutter 3.38.7 / Dart 3.10.7, JDK 17.0.14, Android SDK 36. `flutter analyze` passed.
- **26 controller/widget tests passed**: 17 controller and nine widget cases. The widget cases include separate read/write failure and recovery in English and Spanish at 360 × 800 with 1.8 text scaling. Failed reads disable writes and hide the unknown count; failed writes keep the last confirmed state. Recovery reads saved status before another write.
- Android `dev` debug, `prod` release and web builds passed on final application sources. The web build bundles its rendering resources and has no service-worker cache.
- Native integration uses the actual Android preferences plugin, then disposes and reconstructs the controller. Widget/controller fault tests use controlled stores; they do not inject a hardware storage fault.

| Native journey | Viewport / text scale | Result |
|---|---|---|
| English | 360 × 800 / 1.0 | Preferences journey passed; board/detail PNGs |
| Spanish | 360 × 800 / 1.0 | Same journey passed; Spanish PNGs |
| Spanish enlarged text | 360 × 800 / 1.8 | Same journey passed; enlarged-text PNGs |

The final normal debug APK was then installed over the integration APK without clearing preferences. Two force-stop/start cycles used distinct process IDs; both showed `Completed: 1 / 6` with Alba checked. This is a process-restart check on API 37, separate from reconstructing a controller inside the integration test.

The web build was exercised in a browser in Spanish at 1366 × 768 and 360 × 800: open/complete/back, empty search and clear, simulated loading failure and Normal loading recovery, and completion after a full reload. No warning/error console entries were observed. Browser persistence is scoped to that origin; it is separate from Android preferences.

## Reproduce

From the project directory, run Flutter commands sequentially because they share generated Android files:

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter build apk --debug --flavor dev
flutter build apk --release --flavor prod
flutter build web --dart-define=APP_ENV=dev --no-web-resources-cdn --pwa-strategy=none
flutter test integration_test/app_test.dart --flavor dev -d DEVICE_ID
```

Replace `DEVICE_ID` with an explicit serial. To create the two English screenshots:

```sh
flutter drive --driver test_driver/capture.dart --target integration_test/app_test.dart --dart-define=CAPTURE_SCREENSHOTS=true --flavor dev -d DEVICE_ID --keep-app-running
```

For Spanish, add `--dart-define=CAPTURE_LANGUAGE=es --dart-define=CAPTURE_PREFIX=es`. The driver also accepts `es-large` as a screenshot prefix; text scale is an emulator setting, not something that prefix applies. Only the six documented board/detail filenames are writable. Screenshots are actual Flutter frames, without pixel editing.

The journey resets this demo's completion IDs and leaves `alba` completed. It does not test a normal entry point's process restart by itself. For that check, retain a normal debug APK from before the integration build, install it with `adb -s DEVICE_ID install -r normal-debug.apk` without clearing data, then force-stop/start `dev.navalcode.bitacora.dev`. Repeat the process restart and inspect the completed count. Never replace a normal APK with the integration entry point and describe that as a production launch.

## Unsuccessful attempts and limits

The first expanded widget tests retained a scroll offset after an error notice disappeared. They searched downward for a row that was now above the viewport. Correcting the search direction kept the recovery assertions intact; the final suite passed all 26 cases.

One release build failed because a generated plugin registrant referenced the integration-test plugin in the normal entry point. A subsequent ordinary build regenerated the files and passed; no generated registrant is exported. A driver allowlist formatting warning was corrected before the final analyzer/build run.

An initial native drive was interrupted while installation stalled on the dedicated emulator. Flutter exited zero without a test-completion line; it is recorded as interrupted, not passed. After restarting that emulator, the native journey completed. This does not establish a universal cause or fix for emulator delays. The first normal-process hierarchy dump also ran before Android exposed a root node; the smoke helper was corrected to wait for a valid hierarchy before checking the count. No application assertion was removed.

Advisory APK audit: release **0.95 MB DEX**, debug **13.53 MB**. Native ELF and APK ZIP 16 KB alignment checks passed on both. R8 percentage metadata was unavailable. The tool's overall pass does not verify an optimization rate, official Play policy or store acceptance. Debug is not an optimized release artifact. No dependency was removed to satisfy an advisory recommendation.

No physical-device, native iOS, formal accessibility certification, production signing or store release is claimed. Filters are not restored after process death; completion is stored separately. The hosted workflow runs its own API 35 job; its result must be checked against the published commit.

## Normal APK identities

- `dev` debug SHA-256: `2470ad3ab52dad8d0497979ac5401a696529a4736b77bad73b1d877937644f90`.
- `prod` release SHA-256: `3466ac30f39dfe0a70021aa404760788f3e4ae3836860d891d93f8815d42dba2`.
