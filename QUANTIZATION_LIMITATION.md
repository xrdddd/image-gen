# Quantization Limitation: .mlmodelc Files

## The Problem

Your models are in `.mlmodelc` format, which are **compiled Core ML packages**. These are runtime-optimized binaries that cannot be directly quantized.

### Why Quantization Failed

- `.mlmodelc` files are compiled/optimized packages (like `.app` bundles)
- They don't contain the source model structure needed for quantization
- Core ML Tools can't modify compiled packages directly
- Missing `Manifest.json` indicates these are compiled, not source models

## Solutions

### Option 1: Use FP16 Models As-Is (Recommended)

Your current FP16 models are already well-optimized:
- ✅ Good quality
- ✅ Reasonable size (~4.2GB)
- ✅ Works well on modern iPhones (iPhone 12+)
- ✅ Already chunked for memory efficiency

**Recommendation**: Keep using your FP16 models. The performance is good enough for most use cases.

### Option 2: Get Original .mlpackage Files

If you want to quantize, you need the **uncompiled** `.mlpackage` files:

1. **Re-download from Hugging Face** with original format:
   ```bash
   huggingface-cli download apple/coreml-stable-diffusion-v1-5 \
     --local-dir ./models_original \
     --include "*.mlpackage"
   ```

2. **Check if .mlpackage files are available** in the repository

3. **Then quantize the .mlpackage files** (not .mlmodelc)

### Option 3: Re-Convert from PyTorch with Quantization

Convert from the original PyTorch model with quantization built-in:

```bash
# Clone Apple's repository
git clone https://github.com/apple/ml-stable-diffusion.git
cd ml-stable-diffusion
pip install -e .

# Convert with quantization
python -m python_coreml_stable_diffusion.pipeline \
  --model-version runwayml/stable-diffusion-v1-5 \
  --convert-unet \
  --convert-text-encoder \
  --convert-vae-decoder \
  --quantize-nbits-per-weight 8 \
  --chunk-unet \
  -o ./quantized_models
```

This requires:
- Original PyTorch models
- Apple's conversion tools
- More setup time

### Option 4: Use Apple's Pre-Quantized Models (If Available)

Check if Apple provides quantized versions:
- Check Hugging Face: `apple/coreml-stable-diffusion-*`
- Look for `-quantized` or `-int8` in model names
- Note: As of now, Apple doesn't provide pre-quantized models

## Current Status

✅ **Your FP16 models are ready to use**
- All components present
- Properly structured
- Native code updated to handle them
- Good performance on modern devices

❌ **Direct quantization of .mlmodelc is not possible**
- Need source models (.mlpackage or .mlmodel)
- Or re-convert from PyTorch

## Performance Comparison

| Model Type | Size | Speed | Quality | Use Case |
|------------|------|-------|---------|----------|
| **FP16 (yours)** | 4.2GB | Good | Excellent | ✅ Recommended |
| INT8 (quantized) | ~2GB | Better | Very Good | If size is critical |

## Recommendation

**Use your FP16 models as-is.** They provide:
- Excellent image quality
- Good performance on modern devices
- No additional conversion work needed
- Already optimized with chunking

The size difference (4.2GB vs 2GB) is significant, but:
- Modern iPhones have plenty of storage
- You can download models on first launch (not bundle with app)
- FP16 quality is better than INT8

## If You Really Need Quantization

1. **Get original .mlpackage files** from Hugging Face
2. **Or re-convert from PyTorch** with quantization
3. **Or wait** for Apple to provide pre-quantized models

For now, your FP16 models are production-ready! 🚀
