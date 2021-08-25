#!/bin/bash

brew install create-dmg

APP_PACKAGE_DIR="build/macos/Build/Products/Release"
APP_PACKAGE_NAME="Spoon CAST Converter.app"
DMG_PACKAGE_NAME="Spoon CAST Converter.dmg"
APP_PACKAGE_PATH="${APP_PACKAGE_DIR}/${APP_PACKAGE_NAME}"
DMG_PACKAGE_PATH="${APP_PACKAGE_DIR}/${DMG_PACKAGE_NAME}"

mkdir -p "${APP_PACKAGE_DIR}/.tmp"
cp -R "${APP_PACKAGE_PATH}" "${APP_PACKAGE_DIR}/.tmp/${APP_PACKAGE_NAME}"

#!/bin/sh
test -f "${DMG_PACKAGE_PATH}" && rm "${DMG_PACKAGE_PATH}"

create-dmg \
  --volname "Spoon CAST Converter Installer" \
  --volicon "${APP_PACKAGE_PATH}/Contents/Resources/AppIcon.icns" \
  --background "./build_scripts/resources/background-dmg.tif" \
  --window-pos 200 120 \
  --window-size 800 600 \
  --icon-size 130 \
  --text-size 14 \
  --icon "${APP_PACKAGE_NAME}" 260 275 \
  --hide-extension "${APP_PACKAGE_NAME}" \
  --app-drop-link 540 275 \
  --hdiutil-quiet \
  "${DMG_PACKAGE_PATH}" \
  "${APP_PACKAGE_DIR}/.tmp/"

rm -rf "${APP_PACKAGE_DIR}/.tmp"

. ./build_scripts/.conf.sh

if [ "a${DEVELOPER_ID}z" != "az" ]; then
    codesign --verify \
            --sign "Developer ID Application: ${DEVELOPER_ID}" \
            --deep \
            --force \
            --verbose \
            --option runtime \
            --entitlements ./macos/Runner/entitlements.plist \
            --timestamp \
            --all-architectures \
            "${DMG_PACKAGE_PATH}"
else
    echo "You need to create .conf.sh file in build_scripts directory,"
    echo "and add the environment variable for the DEVELOPER_ID on .conf.sh file which you created one."
fi
