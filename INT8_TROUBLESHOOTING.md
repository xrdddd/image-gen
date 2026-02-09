# Int8 Model Troubleshooting Guide

## Problem: Generation Hangs or Takes Forever

If your int8 quantized model seems to generate endlessly with no output, try these solutions:

## Problem: MPSGraph Backend Validation Error

If you see errors like:
```
E5RT: Espresso exception: "Invalid state": MpsGraph backend validation on incompatible OS
[Espresso::handle_ex_] exception=Espresso compiled without MPSGraph engine.
```

**This is now automatically handled!** The code will:
1. Try CPU-only first (avoids MPSGraph entirely)
2. Fallback to Neural Engine if needed
3. Fallback to CPU+GPU as last resort

**Note**: MPSGraph errors often occur on:
- iOS Simulator (MPSGraph requires real device)
- Older devices without Metal support
- Incompatible model quantization

The automatic fallback should resolve this.

## Solution 1: Change Compute Units (If Automatic Fallback Doesn't Work)

**Note**: The code now automatically tries CPU-only first, then falls back to other options. Only modify this if you need to force a specific compute unit.

Int8 models may require different compute units than FP16 models. The current code tries:
1. `.cpuOnly` first (most compatible, avoids MPSGraph errors)
2. `.cpuAndNeuralEngine` as fallback
3. `.cpuAndGPU` as last resort

To manually override, modify `ImageGenerationModule.swift` around line 75-90:

### Option A: Force CPU only (Most compatible, avoids MPSGraph)
```swift
configuration.computeUnits = .cpuOnly
```

### Option B: Force Neural Engine
```swift
configuration.computeUnits = .cpuAndNeuralEngine
```

### Option C: Force GPU
```swift
configuration.computeUnits = .cpuAndGPU
```

### Option D: Try all (may still trigger MPSGraph errors)
```swift
configuration.computeUnits = .all
```

## Solution 2: Check Model Files

Verify your int8 models are correctly structured:

1. **Check model directory structure:**
   ```
   Documents/models/
   ├── TextEncoder.mlmodelc/
   ├── UnetChunk1.mlmodelc/  (or Unet.mlmodelc)
   ├── UnetChunk2.mlmodelc/  (if using chunks)
   ├── VAEDecoder.mlmodelc/
   ├── vocab.json
   └── merges.txt
   ```

2. **Verify model files are not corrupted:**
   - Check file sizes (int8 models should be ~50% smaller than FP16)
   - Ensure all `.mlmodelc` directories contain model files

3. **Check console logs** for any loading errors:
   ```
   📦 Loading Stable Diffusion pipeline from: ...
   ✅ Stable Diffusion pipeline loaded successfully
   ```

## Solution 3: Reduce Generation Parameters

Int8 models might struggle with certain parameters:

1. **Reduce steps:**
   ```typescript
   // In App.tsx, try reducing from 15 to 10
   steps: 10
   ```

2. **Reduce resolution:**
   ```typescript
   // Try 256x256 instead of 384x384
   width: 256,
   height: 256,
   ```

3. **Reduce guidance scale:**
   ```typescript
   guidanceScale: 5.0  // Instead of 7.5
   ```

## Solution 4: Check Console Logs

The updated code now includes detailed logging. Look for:

```
🚀 Starting image generation...
  📋 Config: steps=15, guidance=7.5, seed=12345
  ⏱️  This may take 30-60 seconds for int8 models...
  🔄 Calling pipeline.generateImages()...
```

If you see the last line but nothing after, the generation is hanging at the `generateImages()` call.

## Solution 5: Verify Model Quantization

Ensure your models are actually int8 quantized:

1. **Check model metadata** (if available):
   - Int8 models should have quantization info in metadata
   - File sizes should be ~50% of FP16 models

2. **Try re-quantizing:**
   - If conversion had errors, models might be corrupted
   - Re-run the quantization process

## Solution 6: Test with FP16 Models First

To isolate the issue:

1. **Temporarily use FP16 models** to verify the pipeline works
2. **If FP16 works but int8 doesn't**, the issue is with quantization or compute units
3. **If neither works**, the issue is elsewhere

## Solution 7: Check Device Compatibility

Int8 models still require:
- iOS 13.0+ (for Neural Engine support)
- Sufficient RAM (4+ GB recommended)
- Neural Engine or GPU support

## Common Error Messages

### "Generation timed out"
- **Fix**: Try different compute units (see Solution 1)
- **Fix**: Reduce steps/resolution (see Solution 3)

### "Model not loaded"
- **Fix**: Check model files exist and are in correct location
- **Fix**: Check console for loading errors

### "Generation appears to have hung"
- **Fix**: This means `generateImages()` never returned
- **Fix**: Try `.all` or `.cpuAndGPU` compute units
- **Fix**: Check if model files are corrupted

## Debugging Steps

1. **Enable detailed logging** (already enabled in latest code)
2. **Check Xcode console** for Swift print statements
3. **Monitor memory usage** in Xcode Instruments
4. **Try one compute unit at a time** to find what works
5. **Test with minimal parameters** (10 steps, 256x256) first

## Quick Test

Try this minimal configuration to test if int8 models work at all:

```typescript
const imageDataUri = await generateImageLocal(prompt.trim(), {
  steps: 10,           // Minimal steps
  guidanceScale: 5.0,  // Lower guidance
  width: 256,          // Small resolution
  height: 256,
});
```

If this works, gradually increase parameters until you find the limit.

## Still Not Working?

1. **Check the exact error message** in console
2. **Verify model conversion** was successful
3. **Try FP16 models** to confirm pipeline works
4. **Check Apple's Stable Diffusion documentation** for int8-specific requirements
5. **Consider using FP16 models** if int8 continues to have issues (they work well on 6+ GB devices)
