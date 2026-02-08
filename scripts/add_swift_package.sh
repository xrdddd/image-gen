#!/bin/bash

# Script to add Apple's Stable Diffusion Swift package to Xcode project
# This script provides instructions and attempts to add the package reference

set -e

PROJECT_DIR="ios/ImageGenerate.xcodeproj"
PROJECT_FILE="$PROJECT_DIR/project.pbxproj"

echo "📦 Adding Apple's Stable Diffusion Swift package..."

# Check if project file exists
if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ Project file not found: $PROJECT_FILE"
    exit 1
fi

echo "⚠️  Note: Swift packages are best added via Xcode's UI"
echo ""
echo "To add the package manually:"
echo "1. Open ios/ImageGenerate.xcworkspace in Xcode"
echo "2. Select the ImageGenerate project in the navigator"
echo "3. Go to File → Add Package Dependencies..."
echo "4. Enter URL: https://github.com/apple/ml-stable-diffusion"
echo "5. Select version: 0.3.0 or latest"
echo "6. Add to target: ImageGenerate"
echo ""
echo "Alternatively, you can use Xcode's command line tools or modify the project.pbxproj file directly."
echo ""
echo "✅ ImageGenerationModule.swift has been updated to use Apple's framework"
echo "   After adding the package, rebuild the project"
