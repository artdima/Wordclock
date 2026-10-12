#!/usr/bin/env bash
# Builds a Release .saver signed with Developer ID, notarizes and staples it.
#
# One-time setup:
#   xcrun notarytool store-credentials wordclock \
#       --apple-id <apple-id> --team-id <TEAM_ID> --password <app-specific-password>
#
# Usage:
#   WORDCLOCK_TEAM_ID=<TEAM_ID> scripts/release.sh
#   WORDCLOCK_NOTARY_PROFILE=<profile> overrides the keychain profile name (default: wordclock).
#   WORDCLOCK_SIGN_IDENTITY="Developer ID Application: Name (TEAM)" picks one certificate when several are installed.
set -euo pipefail

cd "$(dirname "$0")/.."

TEAM_ID="${WORDCLOCK_TEAM_ID:?set WORDCLOCK_TEAM_ID to your Apple Developer Team ID}"
PROFILE="${WORDCLOCK_NOTARY_PROFILE:-wordclock}"
IDENTITY="${WORDCLOCK_SIGN_IDENTITY:-Developer ID Application}"
SCHEME="WordclockScreenSaver"
BUILD_DIR="build"
DIST_DIR="dist"
PRODUCT="$BUILD_DIR/Build/Products/Release/Wordclock.saver"

rm -rf "$PRODUCT" "$DIST_DIR"
mkdir -p "$DIST_DIR"

xcodebuild -scheme "$SCHEME" -configuration Release -derivedDataPath "$BUILD_DIR" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="$IDENTITY" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    OTHER_CODE_SIGN_FLAGS="--timestamp" \
    -quiet build

codesign --force --options runtime --timestamp --sign "$IDENTITY" "$PRODUCT"
codesign --verify --strict --verbose=2 "$PRODUCT"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$PRODUCT/Contents/Info.plist")"
ZIP="$DIST_DIR/Wordclock-$VERSION.saver.zip"

ditto -c -k --keepParent --norsrc --noextattr "$PRODUCT" "$ZIP"
xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$PRODUCT"
xcrun stapler validate "$PRODUCT"

rm -f "$ZIP"
ditto -c -k --keepParent --norsrc --noextattr "$PRODUCT" "$ZIP"
shasum -a 256 "$ZIP"
echo "Ready: $ZIP"
