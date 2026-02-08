# Quick Start: Using Apple's Stable Diffusion Framework

## Step 1: Add Swift Package in Xcode

1. Open `ios/ImageGenerate.xcworkspace` in Xcode
2. Select **ImageGenerate** project in navigator
3. Go to **File → Add Package Dependencies...**
4. Enter: `https://github.com/apple/ml-stable-diffusion`
5. Select version: **0.3.0** or latest
6. Click **Add Package**
7. Ensure **ImageGenerate** target is selected
8. Click **Add Package** again

## Step 2: Replace Implementation

**Option A: Use the new file (recommended)**
```bash
cd ios/ImageGenerate
mv ImageGenerationModule.swift ImageGenerationModule.swift.backup
mv ImageGenerationModuleApple.swift ImageGenerationModule.swift
```

**Option B: Manual update**
- Open `ImageGenerationModuleApple.swift`
- Copy the implementation
- Replace contents of `ImageGenerationModule.swift`
- Uncomment the `import StableDiffusion` and pipeline code

## Step 3: Update Code

In `ImageGenerationModule.swift`, uncomment:
1. `import StableDiffusion` at the top
2. `private var pipeline: StableDiffusionPipeline?` property
3. The pipeline initialization code in `loadModel`
4. The generation code in `generateImage`

## Step 4: Verify Model Structure

Your models should be in:
```
{modelPath}/
  ├── TextEncoder.mlmodelc/
  ├── UnetChunk1.mlmodelc/
  ├── UnetChunk2.mlmodelc/
  ├── VAEDecoder.mlmodelc/
  ├── vocab.json
  └── merges.txt
```

This matches your current structure in `ios/ImageGenerate/model/`

## Step 5: Build and Test

```bash
npm run build:ios
# Or build in Xcode
```

## Expected Benefits

✅ **No more black images** - Proper scheduler implementation  
✅ **Better performance** - Optimized for Neural Engine  
✅ **Less code** - ~100 lines vs ~1000 lines  
✅ **Official support** - Regular updates from Apple  
✅ **Production ready** - Battle-tested implementation  

## Troubleshooting

### "No such module 'StableDiffusion'"
- Ensure Swift package was added correctly
- Clean build folder: Product → Clean Build Folder
- Restart Xcode

### Model loading errors
- Verify model files exist at the path
- Check file permissions
- Ensure models are `.mlmodelc` format (compiled)

### API differences
- Check Apple's documentation for exact API
- The framework API may differ slightly from what's in the template
- Look at Apple's example code in the repository

## Reference

- Apple's Repository: https://github.com/apple/ml-stable-diffusion
- Documentation: Check the README in the repository
- Example Code: Look at the examples in the repository
