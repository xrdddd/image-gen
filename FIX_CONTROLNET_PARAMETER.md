# Fix: Missing controlNet Parameter

## Issue
```
Missing argument for parameter 'controlNet' in call
```

## Solution Applied

The `controlNet` parameter has been added to the `StableDiffusionPipeline` initialization:

```swift
self.pipeline = try StableDiffusionPipeline(
  resourcesAt: baseURL,
  controlNet: nil,  // No ControlNet for basic text-to-image
  configuration: configuration
)
```

## If Error Persists

If you're still seeing the error after this fix, try:

### 1. Clean Build
```bash
# In Xcode: Product → Clean Build Folder (Shift+Cmd+K)
# Or via command line:
cd ios
xcodebuild clean -workspace ImageGenerate.xcworkspace -scheme ImageGenerate
```

### 2. Check Parameter Order

The API might require a different parameter order. Try:

**Option A (current):**
```swift
StableDiffusionPipeline(
  resourcesAt: baseURL,
  controlNet: nil,
  configuration: configuration
)
```

**Option B (alternative order):**
```swift
StableDiffusionPipeline(
  resourcesAt: baseURL,
  configuration: configuration,
  controlNet: nil
)
```

### 3. Check Framework Version

Different versions of Apple's ml-stable-diffusion package may have different APIs:

- Check the version you added in Xcode
- Check the repository for the correct API: https://github.com/apple/ml-stable-diffusion
- Look at example code in the repository

### 4. Verify Package Added Correctly

- Ensure the Swift package is properly added
- Check Package Dependencies in Xcode
- Verify `import StableDiffusion` works (no red errors)

## Alternative: Check Actual API

If the error persists, the API might be different. Check:

1. **Apple's Repository**: https://github.com/apple/ml-stable-diffusion
2. **Example Code**: Look at examples in the repository
3. **Documentation**: Check README or documentation files

The actual API signature might be:
- Different parameter names
- Different parameter order
- Different initialization method

## Quick Fix

If you need to quickly test, you can also try using named parameters explicitly:

```swift
self.pipeline = try StableDiffusionPipeline(
  resourcesAt: baseURL,
  controlNet: nil,
  configuration: configuration
)
```

Or if that doesn't work, check the actual source code or documentation for the exact signature.
