# Fix "Native Module Not Available" Issue

## The Problem

When launching on device, you see:
- "Native module not available"
- No download models UI showing
- Native module not detected

## Root Cause

The native module files exist in `services/native/` but are **not linked to the Xcode project**. They need to be added to the iOS project and compiled.

## Solution: Link Native Module Files

### Step 1: Copy Native Module Files to iOS Project

```bash
# Copy Swift file
cp services/native/ImageGenerationModule.ios.swift ios/ImageGenerate/ImageGenerationModule.swift

# Copy Objective-C bridge file
cp services/native/ImageGenerationModule.m ios/ImageGenerate/ImageGenerationModule.m
```

### Step 2: Add Files to Xcode Project

**Option A: Using Xcode (Recommended)**

1. **Open Xcode:**
   ```bash
   open ios/*.xcworkspace
   ```

2. **Add Swift file:**
   - Right-click on `ImageGenerate` folder in Project Navigator
   - Select "Add Files to ImageGenerate..."
   - Navigate to `ios/ImageGenerate/ImageGenerationModule.swift`
   - Make sure:
     - ✅ "Copy items if needed" is **unchecked** (file already there)
     - ✅ "Add to targets: ImageGenerate" is **checked**
   - Click "Add"

3. **Add Objective-C file:**
   - Right-click on `ImageGenerate` folder
   - Select "Add Files to ImageGenerate..."
   - Navigate to `ios/ImageGenerate/ImageGenerationModule.m`
   - Make sure:
     - ✅ "Copy items if needed" is **unchecked**
     - ✅ "Add to targets: ImageGenerate" is **checked**
   - Click "Add"

**Option B: Using Command Line (Automated)**

```bash
# Run this script to add files to Xcode project
# (You'll need to manually verify in Xcode)
```

### Step 3: Verify Bridging Header

The bridging header should already exist. Verify it includes:

```objc
// ImageGenerate-Bridging-Header.h
#import <React/RCTBridgeModule.h>
```

### Step 4: Rebuild the Project

```bash
# Clean build
cd ios
rm -rf build
pod install
cd ..

# Rebuild
npx expo run:ios --device
```

## Alternative: Use Script to Add Files

I'll create a script to automate this:

```bash
# Copy files
cp services/native/ImageGenerationModule.ios.swift ios/ImageGenerate/ImageGenerationModule.swift
cp services/native/ImageGenerationModule.m ios/ImageGenerate/ImageGenerationModule.m

# Then open Xcode and add them manually
open ios/*.xcworkspace
```

## Verify Native Module is Linked

After adding files, verify:

1. **In Xcode:**
   - Open `ios/*.xcworkspace`
   - Check Project Navigator - you should see:
     - `ImageGenerationModule.swift`
     - `ImageGenerationModule.m`

2. **Check Build Phases:**
   - Select project → Target "ImageGenerate" → Build Phases
   - Under "Compile Sources", you should see:
     - `ImageGenerationModule.m`
     - `ImageGenerationModule.swift`

3. **Check Build Settings:**
   - Search for "Swift Compiler"
   - Verify "Objective-C Bridging Header" is set correctly

## Test After Fixing

1. **Rebuild:**
   ```bash
   npx expo run:ios --device
   ```

2. **Check Console:**
   - Open Xcode → Window → Devices and Simulators
   - Select your device
   - View console logs
   - Should see native module loading messages

3. **In App:**
   - Should see "On-Device Generation" badge
   - Should show model download UI if models not cached
   - Should NOT show "Native module not available"

## Troubleshooting

### "Module not found" Error

**Solution:**
- Make sure files are in `ios/ImageGenerate/` directory
- Verify files are added to target in Xcode
- Clean build folder: `rm -rf ios/build`

### "Swift Compilation Error"

**Solution:**
- Make sure bridging header is configured
- Check Swift version in Build Settings
- Verify CoreML framework is linked

### "Native module still not available"

**Solution:**
1. Check console logs for errors
2. Verify module is registered:
   ```bash
   # In Xcode console, check for:
   # "ImageGenerationModule registered"
   ```
3. Rebuild completely:
   ```bash
   npm run clear-certificate
   npx expo prebuild --platform ios --clean
   npx expo run:ios --device
   ```

## Quick Fix Script

I'll create a script to automate the file copying:

```bash
#!/bin/bash
# fix_native_module.sh

echo "🔧 Fixing native module linking..."

# Copy files
cp services/native/ImageGenerationModule.ios.swift ios/ImageGenerate/ImageGenerationModule.swift
cp services/native/ImageGenerationModule.m ios/ImageGenerate/ImageGenerationModule.m

echo "✅ Files copied to ios/ImageGenerate/"
echo ""
echo "Next steps:"
echo "1. Open Xcode: open ios/*.xcworkspace"
echo "2. Add files to project (see FIX_NATIVE_MODULE.md)"
echo "3. Rebuild: npx expo run:ios --device"
```

## Summary

**The Issue:** Native module files exist but aren't linked to Xcode project.

**The Fix:**
1. Copy files to `ios/ImageGenerate/`
2. Add them to Xcode project
3. Rebuild

**After Fix:**
- Native module will be available
- Model download UI will show
- On-device generation will work
