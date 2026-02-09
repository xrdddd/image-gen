# Memory Optimization Guide

## Problem
The Stable Diffusion model consumes significant memory (2-3 GB), which can cause crashes on iOS devices, especially those with limited RAM (4-6 GB).

## Solutions Implemented

### 1. Runtime Memory Optimizations ✅

#### A. Compute Unit Selection
- **Changed from**: `.cpuAndNeuralEngine` (higher memory usage)
- **Changed to**: `.cpuAndGPU` (lower memory usage)
- **Why**: GPU compute units typically use less memory than Neural Engine for large models

#### B. Reduced Default Image Resolution
- **Changed from**: 512x512 pixels
- **Changed to**: 384x384 pixels
- **Memory savings**: ~44% less memory (384² vs 512² = 147,456 vs 262,144 pixels)
- **Trade-off**: Slightly lower image quality, but still good for most use cases

#### C. Reduced Default Steps
- **Changed from**: 20 steps
- **Changed to**: 15 steps
- **Memory savings**: Less intermediate state during generation
- **Trade-off**: Slightly faster generation, minimal quality difference

### 2. Memory Management Features ✅

**Note**: Automatic model unloading has been removed as it was considered too risky. The model will remain loaded once initialized. Memory is managed by iOS automatically through its memory management system.

### 3. Int8 Quantization (Requires Model Conversion) ⚠️

**Important**: Int8 quantization **cannot** be done at runtime. It must be done during model conversion.

#### Why Runtime Quantization Isn't Possible
- Apple's Stable Diffusion framework uses pre-compiled `.mlmodelc` files
- These are binary runtime files, not source models
- Quantization requires access to the original model weights

#### How to Get Int8 Models

**Option 1: Convert from PyTorch (Recommended)**
```bash
# Clone Apple's conversion tools
git clone https://github.com/apple/ml-stable-diffusion.git
cd ml-stable-diffusion

# Install dependencies
pip install -e .
pip install coremltools>=7.0

# Convert with INT8 quantization
python -c "
from python_coreml_stable_diffusion.pipeline import get_coreml_pipe
import coremltools as ct

coreml_pipe = get_coreml_pipe(
    pytorch_pipe_or_path='runwayml/stable-diffusion-v1-5',
    mlpackages_dir='./models_int8',
    model_version='v1.5',
    compute_unit=ct.ComputeUnit.ALL,
    quantize='int8'  # Enable INT8 quantization
)
"
```

**Option 2: Use Pre-Quantized Models**
- Search Hugging Face for "coreml-stable-diffusion-int8"
- Check community repositories
- Verify compatibility before use

**Memory Savings with Int8**
- Current FP16 models: ~2.56 GB
- Int8 models: ~1.3 GB (50% reduction)
- Requires devices with 4+ GB RAM (vs 6+ GB for FP16)

## Current Optimizations Summary

✅ **Already Implemented:**
1. CPU+GPU compute units (lower memory than Neural Engine)
2. 384x384 default resolution (44% less memory than 512x512)
3. 15 steps default (vs 20)
4. Automatic memory warning handling
5. Manual model unloading capability

⚠️ **Requires Model Conversion:**
- Int8 quantization (reduces model size by ~50%)

## Usage Recommendations

### For Devices with 4-6 GB RAM:
- ✅ Use current optimizations (384x384, 15 steps, CPU+GPU)
- ✅ Consider converting to Int8 models if crashes persist
- ✅ Unload model when app goes to background

### For Devices with 6+ GB RAM:
- ✅ Current optimizations should work well
- ✅ Can optionally use 512x512 resolution if quality is more important
- ✅ Can use 20 steps for slightly better quality


## Testing Memory Usage

To monitor memory usage:
1. Use Xcode Instruments → Allocations
2. Check memory warnings in console
3. Test on physical devices (simulators have more memory)

## Future Improvements

1. **Lazy Model Loading**: Only load models when first generation is requested
2. **Model Chunking**: Load only needed model parts
3. **Memory Pool Management**: Pre-allocate and reuse memory buffers

## Notes

- The current FP16 models work well on iPhone 13 Pro and newer (6+ GB RAM)
- For older devices (iPhone 12, 4 GB RAM), Int8 quantization is recommended
- Quality difference between FP16 and Int8 is minimal for most use cases
- The runtime optimizations (resolution, steps, compute units) provide immediate benefits without requiring model conversion
