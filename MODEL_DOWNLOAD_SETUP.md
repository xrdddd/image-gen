# Model Download Setup Guide

## Overview

The app now downloads Core ML models from cloud storage instead of bundling them. This significantly reduces the initial app size from ~2.56 GB to just a few MB.

## Architecture

1. **App starts** → Checks for cached models
2. **No cache found** → Shows download button
3. **User downloads** → Models downloaded to device storage
4. **Models cached** → Loaded from cache on subsequent launches

## Configuration

### 1. Set Model Server URL

Update `.env` file or environment variables:

```env
EXPO_PUBLIC_MODEL_BASE_URL=https://your-models-server.com/models
```

### 2. Model Server Options

#### Option A: AWS S3 (Recommended)

```env
EXPO_PUBLIC_MODEL_BASE_URL=https://your-bucket.s3.amazonaws.com/models
```

**Setup:**
1. Create S3 bucket
2. Upload model files (see below)
3. Make bucket public or use signed URLs
4. Configure CORS for web access

#### Option B: Google Cloud Storage

```env
EXPO_PUBLIC_MODEL_BASE_URL=https://storage.googleapis.com/your-bucket/models
```

#### Option C: Azure Blob Storage

```env
EXPO_PUBLIC_MODEL_BASE_URL=https://youraccount.blob.core.windows.net/models
```

#### Option D: Your Own Server

```env
EXPO_PUBLIC_MODEL_BASE_URL=https://api.yourdomain.com/models
```

## Model Files to Upload

Upload these files to your cloud storage:

### Required Models:
- `TextEncoder.mlmodelc.zip` (or directory)
- `UnetChunk1.mlmodelc.zip` (or directory)
- `UnetChunk2.mlmodelc.zip` (or directory)
- `VAEDecoder.mlmodelc.zip` (or directory)
- `vocab.json`
- `merges.txt`

### Optional Models:
- `SafetyChecker.mlmodelc.zip` (or directory)
- `VAEEncoder.mlmodelc.zip` (or directory)

## File Format Options

### Option 1: Compressed (.zip)

- Upload each `.mlmodelc` directory as a `.zip` file
- App downloads and extracts (requires zip extraction library)
- Smaller download size
- Requires: `react-native-zip-archive` or similar

### Option 2: Direct Download (Recommended)

- Upload `.mlmodelc` directories directly
- App downloads as-is
- Simpler implementation
- Larger download size

**Current implementation uses Option 2 (direct download).**

## Upload Script Example

```bash
#!/bin/bash
# upload_models.sh

BUCKET_URL="s3://your-bucket/models"
MODELS_DIR="./assets/models"

# Upload model directories
aws s3 sync "$MODELS_DIR" "$BUCKET_URL" \
  --exclude "*" \
  --include "*.mlmodelc" \
  --include "*.json" \
  --include "*.txt"

# Or for direct upload
for file in "$MODELS_DIR"/*.mlmodelc; do
  aws s3 cp "$file" "$BUCKET_URL/$(basename $file)" --recursive
done

aws s3 cp "$MODELS_DIR/vocab.json" "$BUCKET_URL/"
aws s3 cp "$MODELS_DIR/merges.txt" "$BUCKET_URL/"
```

## Implementation Details

### Model Download Service

Located in: `services/modelDownloadService.ts`

**Key Functions:**
- `areAllModelsCached()` - Check if models are downloaded
- `downloadAllModels()` - Download all required models
- `downloadModel()` - Download single model with progress
- `clearModelCache()` - Clear cached models

### Model Path Resolution

The app checks in this order:
1. **Documents directory** (`/Documents/models/`) - Downloaded models
2. **App bundle** (`assets/models/`) - Bundled models (fallback)

### Download Progress

The app shows:
- Current model being downloaded
- Download percentage
- Progress bar

## User Experience

### First Launch:
1. App checks for cached models
2. Shows "Download Models" button
3. User taps to download
4. Shows progress during download
5. Models cached for future use

### Subsequent Launches:
1. App checks for cached models
2. Finds cached models
3. Loads models immediately
4. Ready to generate images

## Storage Requirements

- **Download size**: ~2.56 GB (all models)
- **Cache location**: Device documents directory
- **Persistent**: Models remain cached until app is uninstalled or cache is cleared

## Security Considerations

1. **HTTPS Only**: Always use HTTPS for model downloads
2. **Signed URLs**: Consider using signed URLs for private buckets
3. **Verification**: Add checksum verification for downloaded files
4. **Authentication**: Add API key authentication if needed

## Error Handling

The app handles:
- Network errors during download
- Insufficient storage space
- Corrupted downloads
- Missing model files

## Testing

### Test Download:
```typescript
import { downloadAllModels } from './services/modelDownloadService';

await downloadAllModels((modelName, progress) => {
  console.log(`${modelName}: ${progress.percentage}%`);
});
```

### Test Cache:
```typescript
import { areAllModelsCached } from './services/modelDownloadService';

const cached = await areAllModelsCached();
console.log('All models cached:', cached);
```

## Troubleshooting

### Models Not Downloading

1. Check `EXPO_PUBLIC_MODEL_BASE_URL` is set correctly
2. Verify server is accessible
3. Check CORS settings if using S3
4. Verify file URLs are correct

### Download Fails

1. Check network connection
2. Verify sufficient storage space
3. Check server logs for errors
4. Verify file permissions

### Models Not Loading After Download

1. Check file paths in native code
2. Verify model files are complete
3. Check file permissions
4. Review console logs

## Next Steps

1. **Set up cloud storage** (S3, GCS, Azure, or your server)
2. **Upload model files** to cloud storage
3. **Configure `EXPO_PUBLIC_MODEL_BASE_URL`** in `.env`
4. **Test download** in the app
5. **Monitor download performance** and optimize if needed

## Benefits

✅ **Smaller app size** - Initial download is just a few MB  
✅ **Faster updates** - Update models without app update  
✅ **Flexible deployment** - Easy to switch model versions  
✅ **Better UX** - Users download models only when needed  
✅ **Cost effective** - Pay for storage/bandwidth only when used  
