#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
xcodebuild \
  -project Classic2048.xcodeproj \
  -scheme Classic2048 \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData \
  build
# Copy the complete Xcode-built bundle, including its embedded framework.
APP_SOURCE="$PWD/build/DerivedData/Build/Products/Release/2048.app"
APP_OUTPUT="$PWD/build/2048.app"
if [[ -d "$APP_OUTPUT" ]]; then
  rm -rf "$APP_OUTPUT"
fi
ditto "$APP_SOURCE" "$APP_OUTPUT"
printf 'Built %s\n' "$APP_OUTPUT"
