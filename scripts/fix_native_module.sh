#!/bin/bash
# Fix Native Module Linking
# Copies native module files to iOS project directory

echo "🔧 Fixing native module linking..."
echo ""

# Check if ios directory exists
if [ ! -d "ios/ImageGenerate" ]; then
    echo "❌ ios/ImageGenerate directory not found!"
    echo "   Run: npx expo prebuild --platform ios"
    exit 1
fi

# Copy Swift file
if [ -f "services/native/ImageGenerationModule.ios.swift" ]; then
    cp services/native/ImageGenerationModule.ios.swift ios/ImageGenerate/ImageGenerationModule.swift
    echo "✅ Copied ImageGenerationModule.swift"
else
    echo "⚠️  services/native/ImageGenerationModule.ios.swift not found"
fi

# Copy Objective-C bridge file
if [ -f "services/native/ImageGenerationModule.m" ]; then
    cp services/native/ImageGenerationModule.m ios/ImageGenerate/ImageGenerationModule.m
    echo "✅ Copied ImageGenerationModule.m"
else
    echo "⚠️  services/native/ImageGenerationModule.m not found"
fi

echo ""
echo "✅ Files copied to ios/ImageGenerate/"
echo ""
echo "⚠️  IMPORTANT: You must add these files to Xcode project:"
echo ""
echo "1. Open Xcode:"
echo "   open ios/*.xcworkspace"
echo ""
echo "2. In Xcode Project Navigator:"
echo "   - Right-click on 'ImageGenerate' folder"
echo "   - Select 'Add Files to ImageGenerate...'"
echo "   - Select both files:"
echo "     • ImageGenerationModule.swift"
echo "     • ImageGenerationModule.m"
echo "   - Make sure:"
echo "     ✅ 'Add to targets: ImageGenerate' is checked"
echo "     ❌ 'Copy items if needed' is UNCHECKED (files already there)"
echo "   - Click 'Add'"
echo ""
echo "3. Rebuild:"
echo "   npx expo run:ios --device"
echo ""
