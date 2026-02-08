# Extract tar.gz Files Now

## Current Situation

You have **tar.gz files** in `ios/ImageGenerate/model/` but they need to be **extracted** before they can be used. iOS cannot extract tar.gz files automatically (sandboxed).

## Quick Fix: Extract Now

Run these commands:

```bash
cd ios/ImageGenerate/model

# Extract all tar.gz files
tar -xzf TextEncoder.mlmodelc.tar.gz
tar -xzf UnetChunk1.mlmodelc.tar.gz
tar -xzf UnetChunk2.mlmodelc.tar.gz
tar -xzf VAEDecoder.mlmodelc.tar.gz

# Verify extraction
ls -la
```

You should now see:
```
TextEncoder.mlmodelc/     (directory)
UnetChunk1.mlmodelc/      (directory)
UnetChunk2.mlmodelc/      (directory)
VAEDecoder.mlmodelc/      (directory)
vocab.json
merges.txt
```

## Update Xcode Project

After extraction:

1. **Remove tar.gz files from Xcode** (optional, to save space):
   - In Xcode, select the tar.gz files
   - Right-click → Delete → "Remove Reference" (not "Move to Trash")

2. **Add extracted directories to Xcode**:
   - Right-click `ImageGenerate` folder → "Add Files to ImageGenerate..."
   - Navigate to `ios/ImageGenerate/model/`
   - Select the **directories** (not tar.gz):
     - `TextEncoder.mlmodelc/`
     - `UnetChunk1.mlmodelc/`
     - `UnetChunk2.mlmodelc/`
     - `VAEDecoder.mlmodelc/`
   - **Important**: 
     - Check "Copy items if needed"
     - Ensure "ImageGenerate" target is selected
     - Select "Create folder references" (not "Create groups")
   - Click "Add"

3. **Rebuild**:
   ```bash
   npm run build:ios
   ```

## Expected Result

After extraction and adding to Xcode, you should see:
```
📁 Found pre-extracted models in bundle: /path/to/model
✅ Copied TextEncoder.mlmodelc from bundle
✅ Copied UnetChunk1.mlmodelc from bundle
✅ Copied UnetChunk2.mlmodelc from bundle
✅ Copied VAEDecoder.mlmodelc from bundle
✅ Copied vocab.json
✅ Copied merges.txt
📁 Using models from: /path/to/Documents/models
📦 Loading models from: /path/to/Documents/models
✅ TextEncoder loaded
✅ Unet loaded (chunked: Chunk1 + Chunk2)
✅ VAEDecoder loaded
🎉 All models loaded successfully!
```

## File Sizes

After extraction:
- `TextEncoder.mlmodelc/` - ~235 MB (directory)
- `UnetChunk1.mlmodelc/` - ~847 MB (directory)
- `UnetChunk2.mlmodelc/` - ~794 MB (directory)
- `VAEDecoder.mlmodelc/` - ~95 MB (directory)

Total: ~1.97 GB (uncompressed)

The tar.gz files can be kept as backup or removed to save space.
