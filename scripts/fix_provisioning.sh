#!/bin/bash
# Fix Old Provisioning Profile Issue
# Clears old provisioning profiles and forces regeneration with correct bundle ID

echo "🔧 Fixing provisioning profile issue..."
echo ""

# Current bundle ID from app.json
BUNDLE_ID=$(grep -A 1 '"ios"' app.json | grep 'bundleIdentifier' | sed 's/.*"bundleIdentifier": "\(.*\)".*/\1/')
echo "Current bundle identifier: $BUNDLE_ID"
echo ""

# 1. Clear provisioning profiles
echo "1. Clearing old provisioning profiles..."
if [ -d "$HOME/Library/MobileDevice/Provisioning Profiles" ]; then
  rm -rf "$HOME/Library/MobileDevice/Provisioning Profiles"/*
  echo "   ✓ Provisioning profiles cleared"
else
  echo "   ⚠️  No provisioning profiles directory found"
fi
echo ""

# 2. Clear Xcode DerivedData
echo "2. Clearing Xcode DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData
echo "   ✓ Xcode DerivedData cleared"
echo ""

# 3. Clear Expo cache
echo "3. Clearing Expo cache..."
rm -rf .expo
rm -rf node_modules/.cache
echo "   ✓ Expo cache cleared"
echo ""

# 4. Clear iOS build folder
echo "4. Clearing iOS build folder..."
if [ -d "ios/build" ]; then
  rm -rf ios/build
  echo "   ✓ iOS build folder cleared"
fi
echo ""

# 5. Rebuild iOS project with correct bundle ID
echo "5. Rebuilding iOS project with correct bundle ID..."
if [ -d "ios" ]; then
  echo "   ⚠️  iOS project exists. Consider running: npx expo prebuild --platform ios --clean"
  echo "   This will regenerate the project with the correct bundle ID."
else
  echo "   iOS project doesn't exist. Will be created on next build."
fi
echo ""

echo "✅ Provisioning profile fix complete!"
echo ""
echo "Next steps:"
echo "1. For EAS Build:"
echo "   npx eas-cli credentials -p ios"
echo "   (This will let you configure credentials with the correct bundle ID)"
echo ""
echo "2. For local build:"
echo "   npx expo prebuild --platform ios --clean"
echo "   open ios/*.xcworkspace"
echo "   (In Xcode, select your team in Signing & Capabilities)"
echo ""
echo "3. Or rebuild directly:"
echo "   npx expo run:ios --device"
echo ""
