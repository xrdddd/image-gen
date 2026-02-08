# INT8 Quantization Guide

This guide will help you quantize your FP16 Core ML models to INT8 for:
- **~50% size reduction** (2.56 GB → ~1.3 GB)
- **~20-30% faster inference**
- **Lower memory usage** (~3 GB peak instead of ~4 GB)
- **Better compatibility** with iPhone 12 and newer (4+ GB RAM)

## Quick Start

### Option 1: Automated Script (Recommended)

```bash
python3 scripts/quantize_to_int8.py
```

This script will:
1. Download original `.mlpackage` files from Hugging Face (if needed)
2. Quantize each model component to INT8
3. Compile quantized models to `.mlmodelc` format
4. Replace original models (with backup)

### Option 2: Manual Steps

#### Step 1: Install Dependencies

```bash
pip install "coremltools>=7.0"
pip install huggingface_hub
```

Or use conda:
```bash
conda install -c conda-forge coremltools
pip install huggingface_hub
```

#### Step 2: Download Original .mlpackage Files

The `.mlmodelc` files you have are compiled and cannot be quantized directly. You need the original `.mlpackage` files.

**Option A: Download from Hugging Face**

```bash
python3 scripts/download_mlpackage.py
```

Or manually:
```python
from huggingface_hub import snapshot_download

snapshot_download(
    repo_id="apple/coreml-stable-diffusion-v1-5",
    local_dir="./downloads/mlpackage",
    allow_patterns=["*.mlpackage"],
)
```

**Option B: Use Existing .mlpackage Files**

If you already have `.mlpackage` files, place them in:
- `downloads/mlpackage/` or
- `assets/models/`

#### Step 3: Run Quantization

```bash
python3 scripts/quantize_to_int8.py
```

The script will:
- Find all `.mlpackage` files
- Quantize each to INT8
- Compile to `.mlmodelc` format
- Save to `assets/models_quantized/`

#### Step 4: Replace Models (Optional)

The script will ask if you want to replace the original models. If you say yes:
- Original models are backed up to `assets/models_backup/`
- Quantized models replace the originals in `assets/models/`

## Expected Results

### Size Reduction

| Component | FP16 Size | INT8 Size | Reduction |
|-----------|-----------|-----------|-----------|
| TextEncoder | 234.9 MB | ~117 MB | ~50% |
| UnetChunk1 | 846.9 MB | ~423 MB | ~50% |
| UnetChunk2 | 793.6 MB | ~397 MB | ~50% |
| VAEDecoder | 94.6 MB | ~47 MB | ~50% |
| SafetyChecker | 580.2 MB | ~290 MB | ~50% |
| **Total** | **2.56 GB** | **~1.3 GB** | **~50%** |

### Performance Improvements

- **Memory**: ~3 GB peak (down from ~4 GB)
- **Speed**: 20-30% faster inference
- **Compatibility**: Works on iPhone 12+ (4 GB RAM)

### Quality

- **Slight reduction** in image quality (usually negligible)
- **Still produces high-quality images**
- **Trade-off is worth it** for mobile devices

## Troubleshooting

### "coremltools not installed"

```bash
pip install "coremltools>=7.0"
```

If you get permission errors:
```bash
pip install --user "coremltools>=7.0"
# or
pip install --break-system-packages "coremltools>=7.0"
```

### "huggingface_hub not installed"

```bash
pip install huggingface_hub
```

### "Cannot find .mlpackage files"

1. Download them first:
   ```bash
   python3 scripts/download_mlpackage.py
   ```

2. Or place existing `.mlpackage` files in `downloads/mlpackage/`

### "Quantization failed"

- Make sure you have the original `.mlpackage` files (not `.mlmodelc`)
- Check that `coremltools>=7.0` is installed
- Some models may take 10-20 minutes to quantize (be patient)

### "Out of memory"

- Close other applications
- Quantize one model at a time
- Use a machine with more RAM (8+ GB recommended)

## After Quantization

### Update App Configuration

No changes needed! The app will automatically use the quantized models if they're in `assets/models/`.

### Test the Models

```bash
# Build and test
npx expo run:ios
```

The app should:
- Load models faster
- Use less memory
- Generate images faster
- Work on more devices

### Restore Original Models

If you need to restore the original FP16 models:

```bash
# Models are backed up to:
assets/models_backup/

# To restore:
cp -r assets/models_backup/*.mlmodelc assets/models/
```

## Benefits Summary

✅ **50% smaller** - Easier app distribution  
✅ **Faster inference** - Better user experience  
✅ **Lower memory** - Works on more devices  
✅ **Better compatibility** - iPhone 12+ support  
✅ **Still high quality** - Negligible quality loss  

## Next Steps

1. Run the quantization script
2. Test the quantized models
3. Update app if needed
4. Enjoy faster, smaller models!
