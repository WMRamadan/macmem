#!/usr/bin/env bash
set -euo pipefail

# Script to build MacMem in release mode and package it into a standalone MacMem.app bundle

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="MacMem"
OUTPUT_DIR="${PROJECT_DIR}/dist"
APP_BUNDLE="${OUTPUT_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "==> Building ${APP_NAME} in release configuration..."
cd "${PROJECT_DIR}"
swift build -c release

RELEASE_BIN="${PROJECT_DIR}/.build/release/macmem"
if [[ ! -f "${RELEASE_BIN}" ]]; then
    echo "Error: Binary not found at ${RELEASE_BIN}" >&2
    exit 1
fi

echo "==> Creating application bundle at ${APP_BUNDLE}..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

echo "==> Copying executable..."
cp "${RELEASE_BIN}" "${MACOS_DIR}/macmem"
chmod +x "${MACOS_DIR}/macmem"

echo "==> Creating Info.plist..."
cat <<EOF > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>macmem</string>
    <key>CFBundleIdentifier</key>
    <string>com.macmem.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>MacMem</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026. All rights reserved.</string>
</dict>
</plist>
EOF

echo "==> ${APP_NAME}.app created successfully at:"
echo "    ${APP_BUNDLE}"
echo "==> You can run it with: open \"${APP_BUNDLE}\""
