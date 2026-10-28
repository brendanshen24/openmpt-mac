#!/bin/sh
# Builds a release of the native macOS OpenMPT app and packages it as dist/OpenMPT-<version>-macOS-<arch>.{zip,dmg}.
# Usage: mptrack/mac/make-release.sh   (run from anywhere)
set -eu

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
BUILD="$ROOT/build-mac-release"
DIST="$ROOT/dist"
MIN_MACOS=${MIN_MACOS:-13.0}

cmake -S "$ROOT" -B "$BUILD" -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_DEPLOYMENT_TARGET="$MIN_MACOS"
cmake --build "$BUILD" -j "$(sysctl -n hw.ncpu)"

APP="$BUILD/OpenMPT.app"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$APP/Contents/Info.plist")
ARCH=$(uname -m)
NAME="OpenMPT-$VERSION-macOS-$ARCH"

# Ad-hoc signature: required on Apple silicon; not notarized, so first launch needs right-click > Open.
codesign --force --deep --sign - "$APP"

rm -rf "$DIST/$NAME" "$DIST/$NAME.zip" "$DIST/$NAME.dmg"
mkdir -p "$DIST/$NAME"
ditto "$APP" "$DIST/$NAME/OpenMPT.app"
cp "$ROOT/LICENSE" "$DIST/$NAME/LICENSE.txt"
ln -s /Applications "$DIST/$NAME/Applications"

(cd "$DIST" && ditto -c -k --keepParent "$NAME/OpenMPT.app" "$NAME.zip")
hdiutil create -quiet -volname "OpenMPT $VERSION" -srcfolder "$DIST/$NAME" -ov -format UDZO "$DIST/$NAME.dmg"
rm -rf "$DIST/$NAME"

shasum -a 256 "$DIST/$NAME.zip" "$DIST/$NAME.dmg"
