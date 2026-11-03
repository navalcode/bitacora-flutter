#!/usr/bin/env bash
# Native cases, one invocation, no automatic retries. Diagnostics use the isolated CI emulator and runner.
# The official integration driver uses a direct VM connection without the test command golden relay.
set -euo pipefail
serial="${1:?Pass the explicit emulator serial}"
mkdir -p artifacts
test_apk="${2:-build/app/outputs/flutter-apk/app-dev-debug.apk}"
test -f "$test_apk"
adb -s "$serial" wait-for-device
adb -s "$serial" shell input keyevent KEYCODE_WAKEUP
adb -s "$serial" shell wm dismiss-keyguard
set +e
timeout --signal=TERM --kill-after=20s 8m flutter drive --driver test_driver/ci.dart --target integration_test/app_test.dart --flavor dev -d "$serial" --no-dds --timeout 360 --use-application-binary "$test_apk"
result=$?
# Exclude info-level Flutter VM service messages and their temporary connection tokens.
timeout 15s adb -s "$serial" logcat -d -v threadtime AndroidRuntime:E ActivityManager:I ActivityTaskManager:I flutter:E libc:F DEBUG:F tombstoned:E '*:S' > artifacts/android-runtime.log 2>&1
timeout 15s adb -s "$serial" get-state > artifacts/adb-state.txt 2>&1
df -h . > artifacts/host-disk.txt
free -m > artifacts/host-memory.txt
ps -eo comm,rss --sort=-rss | head -16 > artifacts/host-process-memory.txt
if [ "$result" -ne 0 ]; then
  timeout 15s adb -s "$serial" exec-out screencap -p > artifacts/android-failure.png
fi
exit "$result"
