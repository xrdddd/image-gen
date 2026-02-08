#!/bin/bash
# Clear Certificate Selection Script
# This clears cached certificate/team selections so you can choose again

echo "🧹 Clearing certificate selection..."
echo ""

# 1. Clear Expo cache
echo "1. Clearing Expo cache..."
rm -rf .expo
rm -rf node_modules/.cache
echo "   ✓ Expo cache cleared"
echo ""

# 2. Clear Xcode DerivedData
echo "2. Clearing Xcode DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData
echo "   ✓ Xcode DerivedData cleared"
echo ""

# 3. Clear iOS build folder
echo "3. Clearing iOS build folder..."
if [ -d "ios/build" ]; then
  rm -rf ios/build
  echo "   ✓ iOS build folder cleared"
else
  echo "   ⚠️  No ios/build folder found"
fi
echo ""

# 4. Clear provisioning profiles
echo "4. Clearing provisioning profiles..."
if [ -d "$HOME/Library/MobileDevice/Provisioning Profiles" ]; then
  rm -rf "$HOME/Library/MobileDevice/Provisioning Profiles"/*
  echo "   ✓ Provisioning profiles cleared"
else
  echo "   ⚠️  No provisioning profiles directory found"
fi
echo ""

# 5. Clear Xcode user data (optional - more aggressive)
read -p "Clear Xcode user data (xcuserdata)? This will reset all Xcode project settings. (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  find ios -name "xcuserdata" -type d -exec rm -rf {} + 2>/dev/null
  echo "   ✓ Xcode user data cleared"
fi
echo ""

echo "✅ Certificate selection cleared!"
echo ""
echo "Next steps:"
echo "1. Run: npx expo run:ios --device"
echo "2. You'll be prompted to select a development team/certificate"
echo "3. Choose your Apple Developer account"
echo ""
