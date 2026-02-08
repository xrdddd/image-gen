# Fix: Noisy Output Images

## The Problem

Models load successfully, but generated images are just noise. This is because the **diffusion loop is not actually calling the Unet models**.

## Root Cause

The `runDiffusion()` function is a **placeholder** that:
- ❌ Doesn't call Unet models
- ❌ Just does simple math on latents
- ❌ Never actually denoises the image

Looking at the code:
```swift
// Run Unet (simplified - actual implementation needs proper chunking)
// For now, we'll use a placeholder that processes the latents
```

The Unet models are loaded but **never used**!

## Solution: Implement Actual Unet Inference

I've started implementing the actual Unet inference, but it's complex because:

1. **Unet is chunked** (UnetChunk1 + UnetChunk2) - need to chain them properly
2. **Input/output shapes** need to match exactly
3. **Classifier-free guidance** requires batch size 2
4. **Proper DDPM scheduler** needed

## Current Status

The code now:
- ✅ Tries to call Unet models
- ✅ Prepares batched inputs for guidance
- ✅ Extracts noise predictions
- ⚠️ May need adjustment based on actual model input/output names

## Next Steps

### Option 1: Use Apple's Stable Diffusion Framework (Recommended)

This is the **easiest and most reliable** approach:

1. **Add Swift Package** in Xcode:
   - File → Add Packages
   - URL: `https://github.com/apple/ml-stable-diffusion`
   - Add `StableDiffusion` package

2. **Update the native module** to use Apple's framework:
   ```swift
   import StableDiffusion
   
   let pipeline = StableDiffusionPipeline(
     resourceAt: modelURL,
     controlNet: nil,
     disableSafety: false,
     reduceMemory: true
   )
   
   let images = try pipeline.generateImages(
     prompt: prompt,
     imageCount: 1,
     stepCount: steps.intValue,
     seed: seed.intValue,
     guidanceScale: guidanceScale.floatValue
   )
   ```

This handles all the complexity for you!

### Option 2: Complete the Manual Implementation

If you want to implement it manually, you need to:

1. **Inspect model inputs/outputs** to get exact names and shapes
2. **Properly chain UnetChunk1 and UnetChunk2**
3. **Implement proper DDPM/DDIM scheduler**
4. **Handle classifier-free guidance correctly**

This is very complex and error-prone.

## MPSGraph Warnings

The MPSGraph warnings are **expected on iOS Simulator**:
- MPSGraph requires a real device (iPhone/iPad with Apple Silicon)
- Models will work but may be slower on simulator
- These warnings can be ignored for now

## Recommendation

**Use Apple's Stable Diffusion framework** (Option 1). It's:
- ✅ Battle-tested
- ✅ Handles all complexity
- ✅ Optimized for iOS
- ✅ Much faster to implement

The manual implementation would take significant time and debugging.
