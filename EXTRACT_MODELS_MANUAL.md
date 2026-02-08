# Extract Models Manually Before Adding to Xcode

## Why Manual Extraction?

iOS apps are **sandboxed** and cannot execute system commands like `tar`. Therefore, you need to extract the tar.gz files **before** adding them to the Xcode project.

## Quick Steps

### 1. Extract tar.gz Files

```bash
cd ios/ImageGenerate/model

# Extract all tar.gz files
tar -xzf TextEncoder.mlmodelc.tar.gz
tar -xzf UnetChunk1.mlmodelc.tar.gz
tar -xzf UnetChunk2.mlmodelc.tar.gz
tar -xzf VAEDecoder.mlmodelc.tar.gz

# Optional: Remove tar.gz files to save space (or keep them as backup)
# rm *.tar.gz
```

### 2. Verify Extraction

```bash
ls -la
```

You should see:
```
TextEncoder.mlmodelc/     (directory)
UnetChunk1.mlmodelc/      (directory)
UnetChunk2.mlmodelc/      (directory)
VAEDecoder.mlmodelc/      (directory)
vocab.json
merges.txt
```

### 3. Add to Xcode

1. **Open Xcode:**
   ```bash
   npm run open:xcode
   ```

2. **Add Files:**
   - Right-click `ImageGenerate` folder → "Add Files to ImageGenerate..."
   - Navigate to `ios/ImageGenerate/model/`
   - Select:
     - `TextEncoder.mlmodelc/` (directory)
     - `UnetChunk1.mlmodelc/` (directory)
     - `UnetChunk2.mlmodelc/` (directory)
     - `VAEDecoder.mlmodelc/` (directory)
     - `vocab.json`
     - `merges.txt`
   - **Important**: 
     - Check "Copy items if needed"
     - Ensure "ImageGenerate" target is selected
     - Select "Create folder references" (not "Create groups")
   - Click "Add"

### 4. Verify in Xcode

- In Project Navigator, you should see `model/` folder
- Inside `model/`, you should see:
  - `TextEncoder.mlmodelc/` (folder reference)
  - `UnetChunk1.mlmodelc/` (folder reference)
  - `UnetChunk2.mlmodelc/` (folder reference)
  - `VAEDecoder.mlmodelc/` (folder reference)
  - `vocab.json`
  - `merges.txt`

### 5. Build and Test

```bash
npm run build:ios
# Or in Xcode: Product → Run (⌘R)
```

## Expected Console Output

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
✅ Vocab loaded
✅ Merges loaded
🎉 All models loaded successfully!
```

## File Structure After Extraction

```
ios/ImageGenerate/model/
├── TextEncoder.mlmodelc/          ✅ Directory (extracted)
│   ├── Manifest.json
│   └── ... (model files)
├── UnetChunk1.mlmodelc/           ✅ Directory (extracted)
│   ├── Manifest.json
│   └── ... (model files)
├── UnetChunk2.mlmodelc/           ✅ Directory (extracted)
│   ├── Manifest.json
│   └── ... (model files)
├── VAEDecoder.mlmodelc/           ✅ Directory (extracted)
│   ├── Manifest.json
│   └── ... (model files)
├── vocab.json                     ✅ File
└── merges.txt                     ✅ File
```

## Troubleshooting

### Issue: "TextEncoder.mlmodelc not found"
**Solution**: 
- Verify files are extracted (should be directories, not tar.gz)
- Check files are added to Xcode target
- Rebuild the app

### Issue: "Cannot copy from bundle"
**Solution**: 
- Bundle is read-only, so models are copied to Documents directory
- This is expected behavior
- Models will be copied on first launch

### Issue: Models not appearing in bundle
**Solution**:
- Verify "Create folder references" is selected (not "Create groups")
- Check target membership in File Inspector
- Clean build folder: Product → Clean Build Folder (⇧⌘K)

## Alternative: Keep tar.gz and Extract at Build Time

If you want to keep tar.gz files and extract during build, you can add a "Run Script" build phase in Xcode:

1. Select project → Target "ImageGenerate" → Build Phases
2. Click "+" → "New Run Script Phase"
3. Add script:
   ```bash
   cd "${SRCROOT}/ImageGenerate/model"
   for file in *.tar.gz; do
     if [ -f "$file" ]; then
       tar -xzf "$file" -C "${SRCROOT}/ImageGenerate/model"
     fi
   done
   ```
4. Move this phase before "Compile Sources"

This extracts tar.gz files during build, so you can keep them in the project.
