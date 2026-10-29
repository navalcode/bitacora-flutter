#!/usr/bin/env bash
# One real journey, no automatic retries. Diagnostics contain only the fictional CI app.
set -euo pipefail
serial="${1:?Pass the explicit emulator serial}"
mkdir -p artifacts
adb -s "$serial" wait-for-device
adb -s "$serial" shell input keyevent KEYCODE_WAKEUP
adb -s "$serial" shell wm dismiss-keyguard
set +e
timeout --signal=TERM --kill-after=20s 8m flutter test integration_test/app_test.dart --flavor dev -d "$serial" --reporter expanded --timeout 6m
result=$?
# Exclude info-level Flutter VM service messages and their temporary connection tokens.
adb -s "$serial" logcat -d -v threadtime AndroidRuntime:E ActivityTaskManager:I flutter:E libc:F DEBUG:F tombstoned:E '*:S' > artifacts/android-runtime.log 2>&1
if [ "$result" -ne 0 ]; then
  adb -s "$serial" exec-out screencap -p > artifacts/android-failure.png
fi
exit "$result"
