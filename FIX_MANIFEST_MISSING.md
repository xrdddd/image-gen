# Fix: Missing Manifest.json in .mlmodelc Directory

## The Problem

The error indicates that `TextEncoder.mlmodelc` directory is missing `Manifest.json`, which is **required** for Core ML packages to load.

## Root Cause

The `.mlmodelc` directories in the bundle are incomplete - they're missing the `Manifest.json` file. This usually happens when:
1. The tar.gz files weren't fully extracted
2. The directories were copied incorrectly
3. The directories in the bundle are incomplete

## Solution: Re-extract tar.gz Files

The directories need to be properly extracted from the tar.gz files. Run:

```bash
cd ios/ImageGenerate/model

# Remove incomplete directories if they exist
rm -rf TextEncoder.mlmodelc UnetChunk1.mlmodelc UnetChunk2.mlmodelc VAEDecoder.mlmodelc

# Re-extract all tar.gz files
tar -xzf TextEncoder.mlmodelc.tar.gz
tar -xzf UnetChunk1.mlmodelc.tar.gz
tar -xzf UnetChunk2.mlmodelc.tar.gz
tar -xzf VAEDecoder.mlmodelc.tar.gz

# Verify Manifest.json exists in each directory
find . -name "Manifest.json" -type f
```

You should see 4 Manifest.json files (one in each .mlmodelc directory).

## Verify Directory Structure

Each `.mlmodelc` directory should have:
```
TextEncoder.mlmodelc/
├── Manifest.json          ← REQUIRED!
├── analytics/
├── coremldata.bin
├── metadata.json
├── model.mil
└── weights/
```

## Update Xcode

After re-extraction:

1. **Remove old incomplete directories from Xcode**:
   - In Xcode, select the incomplete `.mlmodelc` directories
   - Right-click → Delete → "Remove Reference"

2. **Add properly extracted directories**:
   - Right-click `ImageGenerate` → "Add Files to ImageGenerate..."
   - Navigate to `ios/ImageGenerate/model/`
   - Select the **directories** (with Manifest.json):
     - `TextEncoder.mlmodelc/`
     - `UnetChunk1.mlmodelc/`
     - `UnetChunk2.mlmodelc/`
     - `VAEDecoder.mlmodelc/`
   - Check "Copy items if needed" and "ImageGenerate" target
   - Select "Create folder references"
   - Click "Add"

3. **Rebuild**:
   ```bash
   npm run build:ios
   ```

## Code Changes

I've updated the code to:
1. ✅ Verify `Manifest.json` exists in bundle before copying
2. ✅ Verify `Manifest.json` exists after copying
3. ✅ Remove incomplete copies and re-copy if needed
4. ✅ Show clear error messages if Manifest.json is missing

## Expected Result

After proper extraction and adding to Xcode:
```
✅ Copied TextEncoder.mlmodelc from bundle (verified with Manifest.json)
✅ Copied UnetChunk1.mlmodelc from bundle (verified with Manifest.json)
✅ Copied UnetChunk2.mlmodelc from bundle (verified with Manifest.json)
✅ Copied VAEDecoder.mlmodelc from bundle (verified with Manifest.json)
📦 Loading models from: /path/to/Documents/models
✅ TextEncoder loaded
```

The models should now load successfully!
