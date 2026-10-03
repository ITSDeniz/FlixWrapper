#!/bin/bash
set -e

echo "==> Building FlixWrapper for macOS (Release)..."
swift build -c release

APP_NAME="FlixWrapper"
BUILD_DIR=".build/release"
OUTPUT_DIR="dist"
APP_BUNDLE="${OUTPUT_DIR}/${APP_NAME}.app"

echo "==> Packaging ${APP_BUNDLE}..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy binary
cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Copy Info.plist
cp "Support/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

# Copy Icon if it exists
if [ -f "Support/AppIcon.icns" ]; then
    cp "Support/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
fi

# Ad-hoc code signing for local execution on Apple Silicon
echo "==> Signing app bundle (ad-hoc)..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "==> Successfully created ${APP_BUNDLE}!"
echo "    You can run it directly: open ${APP_BUNDLE}"
echo "    Or copy to Applications: cp -r ${APP_BUNDLE} /Applications/"
