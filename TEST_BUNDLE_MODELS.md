# Testing Models from Bundle (iOS Simulator)

## Setup Complete ✅

You've copied model files to `ios/ImageGenerate/model/`. The code has been updated to:
1. Check for models in the bundle at `ios/ImageGenerate/model`
2. Automatically extract tar.gz files if needed
3. Use extracted models for loading

## Important: Add Files to Xcode Project

**Critical Step**: The files in `ios/ImageGenerate/model/` must be added to the Xcode project target, otherwise they won't be included in the app bundle.

### Steps to Add Files to Xcode:

1. **Open Xcode:**
   ```bash
   npm run open:xcode
   # Or manually: open ios/ImageGenerate.xcworkspace
   ```

2. **In Xcode:**
   - Right-click on the `ImageGenerate` folder in the Project Navigator
   - Select "Add Files to ImageGenerate..."
   - Navigate to `ios/ImageGenerate/model/`
   - Select all files:
     - `TextEncoder.mlmodelc.tar.gz`
     - `UnetChunk1.mlmodelc.tar.gz`
     - `UnetChunk2.mlmodelc.tar.gz`
     - `VAEDecoder.mlmodelc.tar.gz`
     - `vocab.json`
     - `merges.txt`
   - **Important**: Check "Copy items if needed" and ensure "ImageGenerate" target is selected
   - Click "Add"

3. **Verify Files Are Added:**
   - In Xcode Project Navigator, you should see `model/` folder under `ImageGenerate`
   - All files should be listed

## How It Works

### Path Resolution Order:
1. **Documents directory** (`/Documents/models/`) - Downloaded/cached models
2. **Bundle model directory** (`ios/ImageGenerate/model`) - Your bundled files
3. **Bundle assets** (`assets/models`) - Fallback

### Automatic Extraction:
- If tar.gz files are found in bundle, they're automatically extracted to documents directory
- Extraction happens on first load
- Extracted models are reused on subsequent loads

## Testing

### 1. Build and Run:
```bash
npm run build:ios
# Or in Xcode: Product → Run (⌘R)
```

### 2. Check Console Logs:
Look for these messages:
```
📁 Found tar.gz files in bundle, extracting...
✅ Extracted TextEncoder.mlmodelc.tar.gz
✅ Extracted UnetChunk1.mlmodelc.tar.gz
✅ Extracted UnetChunk2.mlmodelc.tar.gz
✅ Extracted VAEDecoder.mlmodelc.tar.gz
✅ Copied vocab.json
✅ Copied merges.txt
📁 Using extracted models from: /path/to/Documents/models
📦 Loading models from: /path/to/Documents/models
✅ TextEncoder loaded
✅ Unet loaded (chunked: Chunk1 + Chunk2)
✅ VAEDecoder loaded
✅ Vocab loaded
✅ Merges loaded
🎉 All models loaded successfully!
```

### 3. Test Model Loading:
The app should automatically:
- Detect bundle models
- Extract tar.gz files (first time only)
- Load all models
- Be ready for image generation

## Troubleshooting

### Issue: "TextEncoder.mlmodelc not found"
**Solution**: 
- Verify files are added to Xcode target
- Check that files are in `ios/ImageGenerate/model/`
- Rebuild the app

### Issue: "Failed to extract tar.gz"
**Solution**:
- Ensure tar.gz files are valid (not corrupted)
- Check file permissions
- Verify files are in the bundle (check app bundle contents)

### Issue: Models not found in bundle
**Solution**:
1. In Xcode, select the file
2. Check "Target Membership" in File Inspector
3. Ensure "ImageGenerate" is checked

## Alternative: Pre-extract Models

If you prefer to extract models manually before adding to Xcode:

```bash
cd ios/ImageGenerate/model

# Extract all tar.gz files
tar -xzf TextEncoder.mlmodelc.tar.gz
tar -xzf UnetChunk1.mlmodelc.tar.gz
tar -xzf UnetChunk2.mlmodelc.tar.gz
tar -xzf VAEDecoder.mlmodelc.tar.gz

# Remove tar.gz files (optional)
rm *.tar.gz
```

Then add the extracted `.mlmodelc` directories to Xcode instead of tar.gz files.

## File Structure After Setup

```
ios/ImageGenerate/
├── model/
│   ├── TextEncoder.mlmodelc.tar.gz  ✅ Added to target
│   ├── UnetChunk1.mlmodelc.tar.gz   ✅ Added to target
│   ├── UnetChunk2.mlmodelc.tar.gz  ✅ Added to target
│   ├── VAEDecoder.mlmodelc.tar.gz   ✅ Added to target
│   ├── vocab.json                   ✅ Added to target
│   └── merges.txt                   ✅ Added to target
└── ImageGenerationModule.swift      (updated to handle bundle models)
```

## Next Steps

1. ✅ Add files to Xcode target
2. ✅ Build and run
3. ✅ Check console logs
4. ✅ Test model loading
5. ✅ Test image generation

The models should now load from the bundle on iOS simulator!
