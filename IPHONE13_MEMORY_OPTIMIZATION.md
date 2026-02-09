# iPhone 13 (4GB RAM) Memory Optimization Guide

## Problem
iPhone 13 has only **4GB RAM**, which is at the absolute minimum for Stable Diffusion models. Even with int4 quantization, memory crashes can occur.

## Current Optimizations for 4GB Devices

### 1. Ultra-Low Resolution ✅
- **Resolution**: 256x256 pixels (down from 384x384)
- **Memory savings**: 
  - 70% less than 512x512 (65,536 vs 262,144 pixels)
  - 56% less than 384x384 (65,536 vs 147,456 pixels)
- **Trade-off**: Lower image quality, but still usable

### 2. Minimal Steps ✅
- **Steps**: 10 (down from 15)
- **Memory savings**: Less intermediate state during generation
- **Trade-off**: Slightly faster, minimal quality difference with int4 models

### 3. CPU-Only Compute Units ✅
- **Compute Units**: `.cpuOnly` (for int4/int8 models)
- **Why**: GPU acceleration uses additional memory buffers
- **Trade-off**: Slower generation (~2-3x slower) but uses less memory

### 4. Reduced Guidance Scale ✅
- **Guidance Scale**: 7.0 (down from 7.5)
- **Memory savings**: Slightly less memory during generation
- **Trade-off**: Minimal quality impact

## Memory Usage Breakdown (iPhone 13)

### With Int4 Models:
- **Model Loading**: ~800 MB - 1.2 GB (int4 is ~40% of FP16)
- **During Generation**: +300-500 MB
- **Peak Memory**: ~1.5-1.7 GB
- **Available on 4GB device**: ~2-2.5 GB (after iOS overhead)
- **Margin**: ~500 MB - 1 GB (tight but should work)

### Why It Still Crashes:
1. **iOS System Memory**: iOS uses ~1-1.5 GB for system
2. **App Memory**: Your app uses ~200-300 MB base
3. **Model Memory**: ~1.2 GB for int4 models
4. **Generation Memory**: +500 MB during inference
5. **Total**: ~3-3.5 GB (close to 4GB limit)

## Additional Optimizations You Can Try

### Option 1: Further Reduce Resolution (If Still Crashing)
```typescript
// In App.tsx, try 224x224 (even smaller)
width: 224,
height: 224,
```

### Option 2: Reduce Steps Even More
```typescript
// Try 8 steps instead of 10
steps: 8,
```

### Option 3: Use CPU-Only (Already Implemented)
The code now uses `.cpuOnly` for int4 models automatically. This:
- Uses less memory than GPU
- Avoids GPU memory overhead
- Slower but more stable

### Option 4: Close Other Apps
- Close all other apps before generating
- Free up as much RAM as possible
- iOS will kill background apps, but manual closing helps

### Option 5: Restart Device
- Restart iPhone to clear memory
- Fresh boot has more available RAM
- Helps if device has been running for days

## Monitoring Memory Usage

### In Xcode:
1. Run app with Instruments → Allocations
2. Watch memory usage during generation
3. Look for memory spikes
4. Check if it exceeds ~3.5 GB

### In Console:
Look for memory warnings:
```
⚠️ Received memory warning
```

## Expected Performance (iPhone 13, 4GB RAM)

### With Current Optimizations (256x256, 10 steps, CPU-only):
- **Generation Time**: 30-60 seconds
- **Memory Usage**: ~1.5-1.7 GB peak
- **Stability**: Should work, but close to limit
- **Quality**: Lower resolution but acceptable

### If Still Crashing:
1. Try 224x224 resolution
2. Try 8 steps
3. Ensure no other apps running
4. Restart device
5. Consider if int4 models are actually smaller (verify file sizes)

## Verification: Check Model Sizes

Verify your int4 models are actually smaller:

```bash
# Check model directory sizes
du -sh Documents/models/*

# Expected sizes for int4:
# TextEncoder: ~60-80 MB (vs 235 MB FP16)
# UnetChunk1: ~200-250 MB (vs 847 MB FP16)  
# UnetChunk2: ~200-250 MB (vs 794 MB FP16)
# VAEDecoder: ~25-40 MB (vs 95 MB FP16)
# Total: ~500-600 MB (vs 2.56 GB FP16)
```

If models are still large, they might not be properly quantized to int4.

## Alternative: Use Cloud API

If memory issues persist on iPhone 13:
- Consider using cloud API (Qwen3) for 4GB devices
- Keep on-device generation for 6GB+ devices
- Detect device RAM and route accordingly

## Summary

**Current Settings for iPhone 13:**
- ✅ 256x256 resolution
- ✅ 10 steps
- ✅ CPU-only compute units
- ✅ Guidance scale 7.0

**If still crashing:**
- Try 224x224 resolution
- Try 8 steps
- Verify int4 models are actually smaller
- Close all other apps
- Restart device

**Expected Result:**
- Should work with ~500 MB memory margin
- Generation time: 30-60 seconds
- Lower quality but functional
