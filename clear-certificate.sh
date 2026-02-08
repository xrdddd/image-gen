#!/bin/bash
# Quick script to clear certificate selection

echo "🧹 Clearing certificate selection..."

# Clear Expo cache
echo "1. Clearing Expo cache..."
rm -rf .expo
rm -rf node_modules/.cache

# Clear Xcode derived data
echo "2. Clearing Xcode DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData

# Clear iOS build folder
echo "3. Clearing iOS build folder..."
rm -rf ios/build

echo "✅ Done! Run 'npx expo run:ios --device' again to select certificate."
