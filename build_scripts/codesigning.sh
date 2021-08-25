#!/bin/bash

DEVELOPER_ID=""
TARGET_PACKAGE=""

. ./build_scripts/.conf.sh

if [ "a${DEVELOPER_ID}z" != "az" -a "a${TARGET_PACKAGE}z" != "az" ]; then
    codesign --verify \
            --sign "Developer ID Application: ${DEVELOPER_ID}" \
            --deep \
            --force \
            --verbose \
            --option runtime \
            --entitlements ./macos/Runner/entitlements.plist \
            --timestamp \
            --all-architectures \
            "${TARGET_PACKAGE}"
else
    echo "You need to create .conf.sh file in build_scripts directory,"
    echo "and add the environment variable for the DEVELOPER_ID and TARGET_PACKAGE on .conf.sh file which you created one."
fi
