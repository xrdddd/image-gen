#!/bin/bash
# Use Xcode for building instead of EAS authentication
# This bypasses Apple Developer Portal authentication issues

echo "🔧 Setting up Xcode build (bypasses EAS authentication)..."
echo ""

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Please install Xcode from Mac App Store."
    exit 1
fi

# Prebuild iOS project if not exists
if [ ! -d "ios" ]; then
    echo "📱 Prebuilding iOS project..."
    npx expo prebuild --platform ios
    echo ""
fi

# Check if workspace exists
if [ ! -d "ios" ] || [ ! -f "ios/*.xcworkspace" ]; then
    echo "❌ iOS project not found. Run: npx expo prebuild --platform ios"
    exit 1
fi

echo "✅ iOS project ready!"
echo ""
echo "Next steps:"
echo "1. Open Xcode:"
echo "   open ios/*.xcworkspace"
echo ""
echo "2. In Xcode:"
echo "   - Select your development team in 'Signing & Capabilities'"
echo "   - Connect your iPhone via USB"
echo "   - Press ⌘R to build and run"
echo ""
echo "This uses Xcode's built-in authentication (no EAS needed)."
echo ""
