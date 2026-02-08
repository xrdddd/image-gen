# How to Quantize Your Models

I've created a quantization script for you. Here's how to use it:

## Quick Start

### Step 1: Install Dependencies

You need `coremltools` installed. Choose one method:

**Option A: Using pip (recommended)**
```bash
pip install "coremltools>=7.0"
```
*Note: Use quotes around the package name with version to avoid shell errors*

**Option B: Using virtual environment (best practice)**
```bash
# Create virtual environment
python3 -m venv venv

# Activate it
source venv/bin/activate  # On macOS/Linux
# or
venv\Scripts\activate  # On Windows

# Install dependencies
pip install -r requirements.txt
```

**Option C: User installation (if system packages are protected)**
```bash
pip install --user coremltools>=7.0
```

**Option D: If you get "externally-managed-environment" error**
```bash
pip install --break-system-packages coremltools>=7.0
```

### Step 2: Run the Quantization Script

```bash
npm run quantize-models
```

Or directly:
```bash
python3 scripts/quantize_models.py
```

### Step 3: Review Results

The script will:
- Quantize all model components (UnetChunk1, UnetChunk2, TextEncoder, VAEDecoder, etc.)
- Save quantized models to `assets/models_quantized/`
- Show size reduction statistics
- Copy tokenizer files (vocab.json, merges.txt)

## What the Script Does

1. **Loads each model component** from `assets/models/`
2. **Quantizes from FP16 to INT8** (8-bit quantization)
3. **Saves quantized versions** to `assets/models_quantized/`
4. **Reports size savings** (typically ~50% reduction)

## Expected Results

- **Original size**: ~4.2 GB (FP16)
- **Quantized size**: ~2.1 GB (INT8)
- **Size reduction**: ~50%
- **Speed improvement**: ~20-30% faster inference
- **Quality**: Slight reduction (usually negligible)

## Important Notes

### .mlmodelc Files

Your models are in `.mlmodelc` format (compiled Core ML packages). Quantization may:
- ✅ Work directly (if Core ML Tools supports it)
- ⚠️ Require the original `.mlpackage` files (if compilation prevents quantization)

If quantization fails for some models, the script will:
- Copy the original model as a fallback
- Report which models failed
- Continue with other models

### Model Components

The script processes:
- ✅ **UnetChunk1** (required) - Main diffusion model part 1
- ✅ **UnetChunk2** (required) - Main diffusion model part 2
- ✅ **TextEncoder** (required) - Text prompt encoder
- ✅ **VAEDecoder** (required) - Image decoder
- ⚪ **VAEEncoder** (optional) - Image encoder (for img2img)
- ⚪ **SafetyChecker** (optional) - Content safety filter

## After Quantization

### Option 1: Test Quantized Models

1. Keep both versions:
   - `assets/models/` - Original FP16 models
   - `assets/models_quantized/` - New INT8 models

2. Update your app to use quantized models:
   ```typescript
   // In localImageGenerationService.ts
   const modelsDir = Platform.OS === 'ios' 
     ? `${FileSystem.documentDirectory}models_quantized/`
     : `${FileSystem.documentDirectory}models/`;
   ```

3. Test quality and performance

### Option 2: Replace Original Models

If quantized models work well:

```bash
# Backup original models
mv assets/models assets/models_fp16_backup

# Use quantized models
mv assets/models_quantized assets/models
```

## Troubleshooting

### "ModuleNotFoundError: No module named 'coremltools'"

Install coremltools:
```bash
pip install coremltools>=7.0
```

### "externally-managed-environment" Error

Your Python installation is protected. Use:
```bash
pip install --user coremltools>=7.0
# or
pip install --break-system-packages coremltools>=7.0
```

### Quantization Fails for Some Models

This is normal for `.mlmodelc` files. Options:
1. Use the original models for those components
2. Get the original `.mlpackage` files and quantize those
3. Re-convert from PyTorch with quantization (see QUANTIZATION_GUIDE.md)

### Models Don't Load After Quantization

- Verify quantized models are in the correct format
- Check that all required components were quantized
- Test with original models to isolate the issue

## Performance Comparison

After quantization, test:

1. **Image Quality**: Compare generated images
2. **Generation Speed**: Time the inference
3. **Memory Usage**: Monitor peak memory
4. **App Size**: Check final app bundle size

## Next Steps

1. Run the quantization script
2. Test quantized models in your app
3. Compare quality and performance
4. Decide whether to use quantized or original models

The script is ready to run! Just install `coremltools` and execute it.
