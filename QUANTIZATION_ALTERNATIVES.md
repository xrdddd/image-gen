# INT8 Quantization Alternatives

## ⚠️ Important Discovery

The Apple Core ML Stable Diffusion repository on Hugging Face **only contains compiled `.mlmodelc` files**, not the source `.mlpackage` files needed for quantization.

**This means you cannot quantize directly from Hugging Face downloads.**

## Why This Happens

1. **Apple provides pre-compiled models** - They distribute `.mlmodelc` files (compiled, optimized)
2. **Source `.mlpackage` files are not published** - Apple doesn't upload the uncompiled source
3. **Compiled files cannot be quantized** - `.mlmodelc` files are runtime binaries, not source models

## Your Options

### Option 1: Use FP16 Models As-Is (Recommended) ✅

**Pros:**
- ✅ Already have the models (2.56 GB)
- ✅ Works well on iPhone 13 Pro+ (6+ GB RAM)
- ✅ Good quality and performance
- ✅ No additional work needed

**Cons:**
- ⚠️ Larger size (2.56 GB vs ~1.3 GB INT8)
- ⚠️ Requires 6+ GB RAM devices

**Recommendation:** This is the simplest and most reliable option.

### Option 2: Convert from PyTorch with Quantization

Convert the original PyTorch model to Core ML with INT8 quantization built-in.

**Steps:**

1. **Clone Apple's repository:**
   ```bash
   git clone https://github.com/apple/ml-stable-diffusion.git
   cd ml-stable-diffusion
   pip install -e .
   ```

2. **Install dependencies:**
   ```bash
   pip install coremltools>=7.0
   pip install torch torchvision diffusers transformers
   ```

3. **Convert with quantization:**
   ```python
   from python_coreml_stable_diffusion.pipeline import get_coreml_pipe
   import coremltools as ct
   
   # Convert with INT8 quantization
   coreml_pipe = get_coreml_pipe(
       pytorch_pipe_or_path="runwayml/stable-diffusion-v1-5",
       mlpackages_dir="./models_quantized",
       model_version="v1.5",
       compute_unit=ct.ComputeUnit.ALL,
       quantize="int8"  # Add quantization here
   )
   ```

**Pros:**
- ✅ Full control over quantization
- ✅ Can customize quantization settings
- ✅ Produces INT8 models directly

**Cons:**
- ⚠️ More complex setup
- ⚠️ Requires PyTorch model download (~4 GB)
- ⚠️ Conversion takes time (30-60 minutes)

### Option 3: Check for Pre-Quantized Models

Search for community-provided INT8 models:

1. **Search Hugging Face:**
   - Look for "coreml-stable-diffusion-int8"
   - Check community repositories
   - Verify model compatibility

2. **Check GitHub:**
   - Search for "coreml stable diffusion int8"
   - Look for conversion scripts
   - Check for pre-quantized releases

**Pros:**
- ✅ If available, ready to use
- ✅ No conversion needed

**Cons:**
- ⚠️ May not exist
- ⚠️ Need to verify quality and compatibility
- ⚠️ Trust third-party sources

### Option 4: Manual Quantization Workflow

If you have access to the original `.mlpackage` files from another source:

1. **Get `.mlpackage` files** (from conversion or other source)
2. **Run quantization script:**
   ```bash
   python3 scripts/quantize_to_int8.py
   ```
3. **Place `.mlpackage` files in `downloads/mlpackage/`** before running

## Recommendation

**For most users: Use Option 1 (FP16 models as-is)**

Your current 2.56 GB FP16 models:
- ✅ Work well on iPhone 13 Pro and newer
- ✅ Good quality and performance
- ✅ Already set up and working
- ✅ No additional conversion needed

The size reduction from INT8 quantization (2.56 GB → ~1.3 GB) is nice, but:
- The conversion process is complex
- Requires PyTorch model download
- Takes significant time
- Quality may be slightly reduced

**Only consider quantization if:**
- You need to support iPhone 12 (4 GB RAM)
- App size is critical
- You have time for conversion setup

## Current Status

✅ **Your models are ready to use!**
- 2.56 GB total size
- Compatible with iPhone 13 Pro+ (6+ GB RAM)
- Good performance and quality
- No quantization needed for most use cases

## Next Steps

1. **Test your current models:**
   ```bash
   npx expo run:ios
   ```

2. **If you need INT8 quantization:**
   - Follow Option 2 (convert from PyTorch)
   - Or search for pre-quantized models (Option 3)

3. **Monitor performance:**
   - Check memory usage
   - Test on target devices
   - Optimize if needed
