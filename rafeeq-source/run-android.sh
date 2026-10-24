#!/usr/bin/env bash
# Build the Android app from this folder and install it on a connected phone or a running emulator.
# Usage:  ./run-android.sh
set -e
cd "$(dirname "$0")"

# 1. Android SDK (installed with Android Studio)
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
[ -d "$ANDROID_HOME" ] || { echo "Android SDK not found. Install Android Studio first: https://developer.android.com/studio"; exit 1; }
export PATH="$ANDROID_HOME/platform-tools:$PATH"

# 2. Java 17 (Android Studio ships one)
if ! java -version 2>&1 | grep -q '"17\|"21'; then
  for j in "/Applications/Android Studio.app/Contents/jbr/Contents/Home" "/Applications/Android Studio Preview.app/Contents/jbr/Contents/Home"; do
    [ -d "$j" ] && export JAVA_HOME="$j" && export PATH="$JAVA_HOME/bin:$PATH" && break
  done
fi
command -v node >/dev/null || { echo "Node.js is missing. Install it from https://nodejs.org"; exit 1; }

# 3. A phone (USB debugging on) or an emulator must be connected
adb start-server >/dev/null
adb devices | sed 1d | grep -q 'device$' || { echo "No phone or emulator found. Connect the phone with USB debugging on, or start an emulator from Android Studio."; adb devices; exit 1; }

# 4. Build the web app, sync it into the Android project, build the APK
[ -d node_modules ] || npm ci
npm run build
npx cap sync android
( cd android && chmod +x gradlew && ./gradlew assembleDebug )

# 5. Install and open
APK=android/app/build/outputs/apk/debug/app-debug.apk
adb install -r "$APK"
adb shell monkey -p "$(grep -o '"appId": *"[^"]*"' capacitor.config.json | sed 's/.*: *"//;s/"//')" -c android.intent.category.LAUNCHER 1 >/dev/null
echo "Done: the app is installed and opened."
