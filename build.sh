#!/usr/bin/env bash
set -euo pipefail

APP_NAME="OptionStatusChip"
BUNDLE_ID="com.abcom.optionstatuschip"
BUILD_DIR="build"
APP_DIR="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
PLIST_PATH="${CONTENTS_DIR}/Info.plist"
EXECUTABLE_PATH="${MACOS_DIR}/${APP_NAME}"
SOURCE_ROOT="Sources"

mkdir -p "${MACOS_DIR}"

SWIFT_SOURCES=()
while IFS= read -r file; do
  SWIFT_SOURCES+=("${file}")
done < <(find "${SOURCE_ROOT}" -type f -name "*.swift" | sort)
if [[ ${#SWIFT_SOURCES[@]} -eq 0 ]]; then
  echo "No Swift sources found in ${SOURCE_ROOT}" >&2
  exit 1
fi

swiftc \
  -Onone \
  -framework AppKit \
  -framework ApplicationServices \
  -framework AVFoundation \
  "${SWIFT_SOURCES[@]}" \
  -o "${EXECUTABLE_PATH}"

cat > "${PLIST_PATH}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSMicrophoneUsageDescription</key>
  <string>Used for push-to-talk dictation recording.</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

chmod +x "${EXECUTABLE_PATH}"

echo "Built ${APP_DIR}"
