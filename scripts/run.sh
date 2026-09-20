#!/usr/bin/env bash
#
# Start the app on a simulator, an emulator or a real device.
#
# Usage:
#   ./scripts/run.sh            list the devices that are ready
#   ./scripts/run.sh ios        boot an iOS simulator and run the app
#   ./scripts/run.sh android    boot an Android emulator and run the app
#   ./scripts/run.sh <id>       run on a device id from the list
#
set -euo pipefail

export PATH="/opt/homebrew/bin:$PATH"
cd "$(dirname "$0")/.."

if ! command -v fvm >/dev/null 2>&1; then
  echo "error: fvm is not installed. Run: brew install fvm" >&2
  exit 1
fi

flutter() { fvm flutter "$@"; }

# Reports the number of installed iOS simulator runtimes.
ios_runtime_count() {
  xcrun simctl list runtimes 2>/dev/null | grep -c "iOS" || true
}

start_ios() {
  if [ "$(ios_runtime_count)" -eq 0 ]; then
    cat >&2 <<'MSG'
error: no iOS simulator runtime is installed.

Xcode 26 does not include the simulator runtime. Download it one time:

    xcodebuild -downloadPlatform iOS

The download is about 9 GB. It takes 20 to 40 minutes.

To use a real iPhone instead, connect it with a cable, trust this Mac,
then run: ./scripts/run.sh
MSG
    exit 1
  fi

  local udid
  udid=$(xcrun simctl list devices available --json \
    | python3 -c "
import json, sys
data = json.load(sys.stdin)['devices']
for runtime, devices in sorted(data.items(), reverse=True):
    if 'iOS' not in runtime:
        continue
    for d in devices:
        if d.get('isAvailable'):
            print(d['udid'])
            sys.exit(0)
")

  if [ -z "$udid" ]; then
    echo "error: a runtime exists but no simulator device. Create one in Xcode." >&2
    exit 1
  fi

  echo "booting the simulator $udid"
  xcrun simctl boot "$udid" 2>/dev/null || true
  open -a Simulator
  flutter run -d "$udid"
}

start_android() {
  if ! command -v adb >/dev/null 2>&1 && [ ! -d "$HOME/Library/Android/sdk" ]; then
    cat >&2 <<'MSG'
error: the Android SDK is not installed.

Install the command line tools only. They are much smaller than Android Studio:

    brew install --cask android-commandlinetools
    sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"
    sdkmanager "emulator" "system-images;android-36;google_apis;arm64-v8a"
    fvm flutter config --android-sdk "$(brew --prefix)/share/android-commandlinetools"
MSG
    exit 1
  fi

  local emulator_id
  emulator_id=$(flutter emulators 2>/dev/null | awk '/android/ {print $1; exit}')

  if [ -n "$emulator_id" ]; then
    echo "starting the emulator $emulator_id"
    flutter emulators --launch "$emulator_id"
  fi
  flutter run -d android
}

case "${1:-list}" in
  list)
    echo "=== devices that are ready ==="
    flutter devices
    echo
    echo "=== iOS simulator runtimes ==="
    xcrun simctl list runtimes 2>/dev/null | grep "iOS" || echo "none installed"
    echo
    echo "Run './scripts/run.sh ios' or './scripts/run.sh android' to start one."
    ;;
  ios) start_ios ;;
  android) start_android ;;
  *) flutter run -d "$1" ;;
esac
