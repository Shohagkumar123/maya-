#!/usr/bin/env bash
#
# build-apk.sh — build an installable debug APK for the Maya clone.
#
# Run this on a computer that has JDK 17 and the Android SDK (command-line
# tools or Android Studio) and an internet connection for the first build.
# It will NOT work on a bare Android device (no JDK/Gradle/SDK there).
#
#   ./build-apk.sh
#
# Result: app/build/outputs/apk/debug/app-debug.apk
# Install with:  adb install -r app/build/outputs/apk/debug/app-debug.apk

set -euo pipefail
cd "$(dirname "$0")"

echo "==> Checking Java (need 17)…"
if ! command -v java >/dev/null 2>&1; then
  echo "ERROR: 'java' not found. Install JDK 17 (e.g. Temurin) and set JAVA_HOME."
  exit 1
fi
java -version

echo "==> Checking Android SDK…"
if [ -z "${ANDROID_HOME:-}" ] && [ -z "${ANDROID_SDK_ROOT:-}" ] && [ ! -f local.properties ]; then
  echo "WARNING: ANDROID_HOME / ANDROID_SDK_ROOT not set and local.properties missing."
  echo "         Create local.properties with:  sdk.dir=/path/to/Android/sdk"
  echo "         (Android Studio writes this automatically.)"
fi

echo "==> Building debug APK…"
if [ -x ./gradlew ]; then
  ./gradlew assembleDebug --stacktrace
else
  echo "    gradlew wrapper not found; using system 'gradle'."
  echo "    (Tip: run 'gradle wrapper' once to generate the wrapper.)"
  gradle assembleDebug --stacktrace
fi

APK="app/build/outputs/apk/debug/app-debug.apk"
if [ -f "$APK" ]; then
  echo
  echo "==> Done: $APK"
  echo "    Install with: adb install -r $APK"
else
  echo "ERROR: build finished but $APK was not produced."
  exit 1
fi
