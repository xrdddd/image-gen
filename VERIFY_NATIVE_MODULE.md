# Verify Native Module is Working

## Step 1: Check Console Logs

After rebuilding, check the console logs. You should see:

```
🔍 Available native modules: [list of modules]
🔍 ImageGenerationModule: [object or undefined]
🔍 Platform: ios
🔍 Checking local generation availability...
🔍 ImageGenerationModuleNative: [object or null]
🔍 NativeImageGen: [object or null]
```

## Step 2: What to Look For

### ✅ Module is Working:
- `ImageGenerationModule` appears in available modules list
- `ImageGenerationModuleNative` is an object (not null)
- `NativeImageGen` is an object (not null)
- App shows "On-Device Generation" badge
- Model download UI appears

### ❌ Module Not Working:
- `ImageGenerationModule` is `undefined` in available modules
- `ImageGenerationModuleNative` is `null`
- Console shows "Native module not available"
- No download UI

## Step 3: Common Issues

### Issue 1: Module Not in Available Modules List

**Symptom:** `ImageGenerationModule` is `undefined`

**Causes:**
- Module not compiled
- Module not linked to target
- Build error preventing compilation
- Module name mismatch

**Fix:**
1. Open Xcode → Build (⌘B)
2. Check for compilation errors
3. Verify files are in "Compile Sources"
4. Clean build: `rm -rf ios/build`

### Issue 2: Module Compiled But Not Registered

**Symptom:** Module exists but `ImageGenerationModuleNative` is `null`

**Causes:**
- `RCT_EXTERN_MODULE` not working
- Swift class name mismatch
- Bridging header issue

**Fix:**
1. Verify `@objc(ImageGenerationModule)` matches `RCT_EXTERN_MODULE(ImageGenerationModule, NSObject)`
2. Check bridging header includes React imports
3. Rebuild completely

### Issue 3: Build Errors

**Symptom:** Xcode shows compilation errors

**Fix:**
1. Fix Swift compilation errors
2. Check all imports are correct
3. Verify CoreML framework is linked
4. Clean and rebuild

## Step 4: Manual Test

Add this to `App.tsx` temporarily to test:

```typescript
import { NativeModules } from 'react-native';

// In your component
console.log('All modules:', Object.keys(NativeModules));
console.log('ImageGenerationModule:', NativeModules.ImageGenerationModule);

// Try calling a method
if (NativeModules.ImageGenerationModule) {
  NativeModules.ImageGenerationModule.isModelLoaded()
    .then(result => console.log('isModelLoaded result:', result))
    .catch(err => console.error('Error:', err));
}
```

## Step 5: Rebuild Checklist

1. ✅ Files copied to `ios/ImageGenerate/`
2. ✅ Files added to Xcode target
3. ✅ Files appear in "Compile Sources"
4. ✅ No build errors in Xcode
5. ✅ Clean build: `rm -rf ios/build`
6. ✅ Rebuild: `npx expo run:ios --device`
7. ✅ Check console logs

## Still Not Working?

1. **Check Xcode build log:**
   - Product → Build (⌘B)
   - Look for "ImageGenerationModule" in build log
   - Check for any errors

2. **Verify module registration:**
   - The module should auto-register via `RCT_EXTERN_MODULE`
   - No manual registration needed

3. **Try explicit registration (if needed):**
   - This shouldn't be necessary, but if `RCT_EXTERN_MODULE` isn't working, we might need to use `RCTBridgeModule` protocol directly

4. **Check React Native version:**
   - Some versions have issues with Swift modules
   - Verify compatibility
