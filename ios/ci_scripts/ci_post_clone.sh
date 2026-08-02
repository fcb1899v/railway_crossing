#!/bin/sh
set -euo pipefail
# Ensure Flutter + SPM platform (>= iOS 15 for Firebase plugins) before Xcode Cloud builds.
cd "$CI_PRIMARY_REPOSITORY_PATH"
flutter pub get
flutter build ios --config-only --no-codesign
MANIFEST="ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift"
if [ -f "$MANIFEST" ]; then
  /usr/bin/sed -i '' 's/\.iOS("13\.[0-9]*")/.iOS("15.0")/' "$MANIFEST"
fi
