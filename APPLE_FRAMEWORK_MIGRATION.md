# Migration to Apple's Stable Diffusion Framework

This guide explains how to migrate from the manual implementation to Apple's official Stable Diffusion Swift package.

## Why Switch?

The manual implementation has several issues:
- Complex scheduler logic prone to errors
- Difficult to debug black image issues
- Missing optimizations for Apple Silicon
- No official support or updates

Apple's framework provides:
- ✅ Battle-tested implementation
- ✅ Proper scheduler and guidance handling
- ✅ Optimized for Neural Engine
- ✅ Regular updates and bug fixes
- ✅ Better error handling

## Migration Steps

### 1. Add Swift Package Dependency

**In Xcode:**
1. Open `ios/ImageGenerate.xcworkspace`
2. Select the `ImageGenerate` project in the navigator
3. Go to **File → Add Package Dependencies...**
4. Enter URL: `https://github.com/apple/ml-stable-diffusion`
5. Select version: `0.3.0` or latest
6. Add to target: `ImageGenerate`

**Or via command line:**
```bash
cd ios/ImageGenerate
# The package will be added via Xcode's Package.swift integration
```

### 2. Replace ImageGenerationModule.swift

Two options:

**Option A: Use the new file (recommended)**
- Backup current: `mv ImageGenerationModule.swift ImageGenerationModule.swift.backup`
- Use: `ImageGenerationModuleApple.swift` (rename to `ImageGenerationModule.swift`)

**Option B: Update existing file**
- Replace the entire implementation with the Apple framework version
- Keep the same `@objc` method signatures for React Native compatibility

### 3. Update Model Path Structure

Apple's framework expects models in a specific structure. You have two options:

**Option A: Keep current structure (models in `model/` directory)**
- The framework can load from any path
- Just pass the base directory path

**Option B: Use framework's expected structure**
```
{modelPath}/
  ├── TextEncoder.mlmodelc/
  ├── UnetChunk1.mlmodelc/
  ├── UnetChunk2.mlmodelc/
  ├── VAEDecoder.mlmodelc/
  ├── vocab.json
  └── merges.txt
```

### 4. Update React Native Interface

The React Native interface (`ImageGenerationModule.m` and TypeScript) should work as-is since we're keeping the same method signatures:
- `loadModel(path, resolve, reject)`
- `isModelLoaded(resolve, reject)`
- `generateImage(prompt, steps, guidanceScale, seed, width, height, resolve, reject)`

### 5. Test

1. Build the project: `npm run build:ios` or build in Xcode
2. Test model loading
3. Test image generation
4. Verify images are no longer black

## API Differences

### Manual Implementation
```swift
// Manual tokenization, encoding, diffusion loop, decoding
let tokens = tokenize(prompt)
let embeddings = encodeText(tokens)
let latents = runDiffusion(noise, embeddings, steps, guidanceScale)
let image = decodeLatents(latents)
```

### Apple's Framework
```swift
// Everything handled automatically
let images = try pipeline.generateImages(
  prompt: prompt,
  imageCount: 1,
  stepCount: steps,
  seed: seed,
  guidanceScale: guidanceScale,
  disableSafety: false
)
```

## Benefits

1. **Reliability**: No more black images from scheduler bugs
2. **Performance**: Optimized for Apple Silicon and Neural Engine
3. **Maintenance**: Official support and updates
4. **Simplicity**: Much less code to maintain
5. **Features**: Built-in safety checker, progress callbacks, etc.

## Troubleshooting

### Package Not Found
- Ensure Xcode version is 14.0+ (required for Swift Package Manager)
- Check internet connection for package download
- Try clearing Xcode derived data

### Model Loading Errors
- Verify model files are in correct location
- Check file permissions
- Ensure models are compiled (.mlmodelc format)

### Build Errors
- Clean build folder: Product → Clean Build Folder
- Delete derived data
- Re-add the Swift package

## Rollback

If you need to rollback:
1. Restore `ImageGenerationModule.swift.backup`
2. Remove Swift package dependency in Xcode
3. Clean and rebuild
