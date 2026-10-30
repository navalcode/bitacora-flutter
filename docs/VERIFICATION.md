# Verification record

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
