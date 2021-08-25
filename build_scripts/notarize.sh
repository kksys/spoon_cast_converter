#!/bin/bash

. ./build_scripts/.conf.sh

APP_PACKAGE_DIR="build/macos/Build/Products/Release"
APP_PACKAGE_NAME="Spoon CAST Converter.app"
DMG_PACKAGE_NAME="Spoon CAST Converter.dmg"
APP_PACKAGE_PATH="${APP_PACKAGE_DIR}/${APP_PACKAGE_NAME}"
DMG_PACKAGE_PATH="${APP_PACKAGE_DIR}/${DMG_PACKAGE_NAME}"

if [ "a$1z" == "ahelpz" -o "a$1z" == "az" ]; then
    echo "notarize.sh <command> <uuid>"
    echo "command:"
    echo "  upload"
    echo "  status: In this command, it requires uuid parameter"
    echo "  history"
    echo "  staple"
    echo "  staplecheck"
elif [ "a$1z" == "auploadz" ]; then
    mkdir -p ./build_scripts/.notarization_log/
    xcrun altool \
        --notarize-app \
        -t osx \
        -f "${DMG_PACKAGE_PATH}" \
        --primary-bundle-id "${PACKAGE_NAME}" \
        -u "${DEVELOPER_MAIL}" \
        -p "${APP_PASSWORD}" > ./build_scripts/.notarization_log/$(date "+%Y%m%d%H%M%S")
elif [ "a$1z" == "astatusz" ]; then
    xcrun altool \
        --notarization-info "$2" \
        --username "${DEVELOPER_MAIL}" \
        --password "${APP_PASSWORD}"
elif [ "a$1z" == "ahistoryz" ]; then
    xcrun altool \
        --notarization-history 0 \
        --username "${DEVELOPER_MAIL}" \
        --password "${APP_PASSWORD}"
elif [ "a$1z" == "astaplez" ]; then
    xcrun stapler staple "${DMG_PACKAGE_PATH}"
elif [ "a$1z" == "astaplecheckz" ]; then
    xcrun stapler validate "${DMG_PACKAGE_PATH}"
fi
