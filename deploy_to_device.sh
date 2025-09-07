#!/bin/bash

# Deploy FreeCollage to iPhone
# This script builds and deploys the app to your connected iPhone

set -e  # Exit on any error

echo "🔍 Checking for connected iOS device..."
export DEVICE_UDID=$(idevice_id -l)

if [ -z "$DEVICE_UDID" ]; then
    echo "❌ No iOS device found. Please connect your iPhone via USB and make sure it's trusted."
    exit 1
fi

echo "📱 Found device: $DEVICE_UDID"

echo "🔨 Building app for device..."
xcodebuild -project FreeCollage.xcodeproj \
    -scheme FreeCollage \
    -destination "platform=iOS,id=$DEVICE_UDID" \
    -configuration Debug \
    install

echo "📦 Finding built app..."
# Find the installation build products location dynamically
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -type d -path "*/ArchiveIntermediates/FreeCollage/InstallationBuildProductsLocation/Applications/FreeCollage.app" | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Could not find built app. Build may have failed."
    exit 1
fi

echo "📲 Installing app to device..."
ios-deploy --id "$DEVICE_UDID" --bundle "$APP_PATH"

echo "✅ Successfully deployed FreeCollage to your iPhone!"
