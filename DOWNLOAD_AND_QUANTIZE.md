# Download and Quantize .mlpackage Files

I've created scripts to download the original .mlpackage files and quantize them. Here's how to use them:

## Step 1: Install Dependencies

You need `huggingface_hub` to download models:

```bash
# Option 1: Using pip
pip install "huggingface-hub"

# Option 2: Using conda (since you're in conda environment)
conda install -c conda-forge huggingface_hub

# Option 3: With --user flag
pip install --user "huggingface-hub"
```

You also need `coremltools` (if not already installed):

```bash
pip install "coremltools>=7.0"
```

## Step 2: Download Original .mlpackage Files

```bash
npm run download-mlpackage
```

Or directly:
```bash
python3 scripts/download_mlpackage.py
```

This will:
- Download the original model from Hugging Face
- Look for .mlpackage files (uncompiled source models)
- Save them to `assets/models_original/`

**Note**: The download may take a while (several GB of data).

## Step 3: Quantize the .mlpackage Files

Once downloaded, quantize them:

```bash
npm run quantize-mlpackage
```

Or directly:
```bash
python3 scripts/quantize_mlpackage.py
```

This will:
- Load each .mlpackage file
- Quantize from FP16 to INT8
- Save quantized versions to `assets/models_quantized/`

## Expected Results

- **Download**: Original .mlpackage files (~4-5 GB)
- **Quantized**: INT8 versions (~2-2.5 GB)
- **Size reduction**: ~50%

## Important Notes

### If .mlpackage Files Are Not Available

Apple's Hugging Face repository may only contain .mlmodelc files (compiled). In that case:

1. **Check the downloaded files** - Look in `assets/models_original/`
2. **If only .mlmodelc files** - You'll need to use Option 2 (re-convert from PyTorch)
3. **Alternative**: Use your existing FP16 models (they work well!)

### After Quantization

1. **Test the quantized models** in your app
2. **Compare quality** with original FP16 models
3. **Update your app** to use quantized models if satisfied

## Quick Commands

```bash
# 1. Install dependencies
pip install "huggingface-hub" "coremltools>=7.0"

# 2. Download original models
npm run download-mlpackage

# 3. Quantize them
npm run quantize-mlpackage
```

## Troubleshooting

### "ModuleNotFoundError: No module named 'huggingface_hub'"
- Install it: `pip install "huggingface-hub"`

### "No .mlpackage files found"
- The repository may only have .mlmodelc files
- You'll need to use Option 2 (re-convert from PyTorch) instead

### Download is slow
- This is normal - models are several GB
- Be patient, or download during off-peak hours
