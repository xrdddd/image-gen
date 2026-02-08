# Quick Fix: Native Module Not Available

## Problem
- App shows "Native module not available"
- No download models UI
- Native module not detected

## Solution (3 Steps)

### Step 1: Files Already Copied ✅
The native module files have been copied to `ios/ImageGenerate/`:
- `ImageGenerationModule.swift`
- `ImageGenerationModule.m`

### Step 2: Add Files to Xcode Project (REQUIRED)

**Open Xcode:**
```bash
open ios/*.xcworkspace
```

**In Xcode:**

1. **Find the files in Project Navigator:**
   - Look for `ImageGenerationModule.swift` and `ImageGenerationModule.m` in the `ImageGenerate` folder
   - If they're grayed out, they're not added to the target

2. **Add files to target:**
   - Select `ImageGenerationModule.swift` in Project Navigator
   - In the right panel (File Inspector), check:
     - ✅ **"ImageGenerate"** under "Target Membership"
   - Repeat for `ImageGenerationModule.m`

3. **OR Add files manually:**
   - Right-click on `ImageGenerate` folder
   - Select "Add Files to ImageGenerate..."
   - Navigate to `ios/ImageGenerate/`
   - Select both:
     - `ImageGenerationModule.swift`
     - `ImageGenerationModule.m`
   - Make sure:
     - ✅ "Add to targets: ImageGenerate" is **checked**
     - ❌ "Copy items if needed" is **unchecked** (files already there)
   - Click "Add"

### Step 3: Rebuild

```bash
# Clean and rebuild
cd ios
rm -rf build
pod install
cd ..

# Rebuild for device
npx expo run:ios --device
```

## Verify It Works

After rebuilding, the app should:
- ✅ Show "On-Device Generation" badge
- ✅ Show model download UI if models not cached
- ✅ NOT show "Native module not available"

## If Still Not Working

1. **Check Xcode console for errors:**
   - Window → Devices and Simulators
   - Select your device
   - View console logs

2. **Verify files are compiled:**
   - In Xcode: Project → Target "ImageGenerate" → Build Phases
   - Under "Compile Sources", you should see:
     - `ImageGenerationModule.m`
     - `ImageGenerationModule.swift`

3. **Check bridging header:**
   - Build Settings → Search "Objective-C Bridging Header"
   - Should be: `ImageGenerate/ImageGenerate-Bridging-Header.h`

## Summary

**The Issue:** Files exist but aren't added to Xcode target.

**The Fix:** Add files to target in Xcode (Step 2 above).

**Time:** 2 minutes in Xcode.
