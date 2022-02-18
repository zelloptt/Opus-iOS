#!/bin/bash
# Merge Script

TEMP_BUILD_DIR="${PROJECT_TEMP_DIR}/build"
OUTPUTDIR="${PROJECT_DIR}/build"

# 1
# Set bash script to exit immediately if any commands fail.
set -e

# 2
# Setup some constants for use later on.
FRAMEWORK_NAME="opus"

# 4
# Build the framework for device and for simulator (using
# all needed architectures).
xcodebuild -project opus.xcodeproj -target "${FRAMEWORK_NAME}" -configuration Release -arch arm64 only_active_arch=no defines_module=yes -sdk "iphoneos" PROJECT_TEMP_DIR="${PROJECT_TEMP_DIR}" SYMROOT="${TEMP_BUILD_DIR}"
xcodebuild -project opus.xcodeproj -target "${FRAMEWORK_NAME}" -configuration Release -arch x86_64 -arch arm64 only_active_arch=no defines_module=yes -sdk "iphonesimulator" PROJECT_TEMP_DIR="${PROJECT_TEMP_DIR}" SYMROOT="${TEMP_BUILD_DIR}"

# 5
# Remove .xcframework file if it exists from previous run.
if [ -d "${OUTPUTDIR}/${FRAMEWORK_NAME}.xcframework" ]; then
rm -rf "${OUTPUTDIR}/${FRAMEWORK_NAME}.xcframework"
fi

# 6 Create an xcframework combining the frameworks
mkdir -p "${OUTPUTDIR}"
xcodebuild -create-xcframework -framework "${TEMP_BUILD_DIR}/Release-iphoneos/${FRAMEWORK_NAME}.framework" -framework "${TEMP_BUILD_DIR}/Release-iphonesimulator/${FRAMEWORK_NAME}.framework" -output "${OUTPUTDIR}/${FRAMEWORK_NAME}.xcframework"
