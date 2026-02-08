# Cloud Model Download Setup

## Overview

The app now downloads Core ML models from cloud storage instead of bundling them. This reduces the initial app size from **2.56 GB to just a few MB**.

## How It Works

1. **App Launch** → Checks for cached models in device storage
2. **No Cache Found** → Shows "Download Models" button
3. **User Downloads** → Models downloaded to `/Documents/models/`
4. **Models Cached** → Loaded from cache on subsequent launches

## Quick Setup

### 1. Configure Model Server URL

Create or update `.env` file:

```env
EXPO_PUBLIC_MODEL_BASE_URL=https://your-models-server.com/models
```

### 2. Upload Models to Cloud Storage

Upload your model files to your cloud storage:

**Required Models:**
- `TextEncoder.mlmodelc/` (directory)
- `UnetChunk1.mlmodelc/` (directory)
- `UnetChunk2.mlmodelc/` (directory)
- `VAEDecoder.mlmodelc/` (directory)
- `vocab.json`
- `merges.txt`

**Optional Models:**
- `SafetyChecker.mlmodelc/` (directory)
- `VAEEncoder.mlmodelc/` (directory)

### 3. Test the App

```bash
npx expo run:ios
```

The app will:
- Check for cached models on launch
- Show download button if models not found
- Download models when user taps button
- Cache models for future use

## Cloud Storage Options

### Option 1: AWS S3 (Recommended)

**Setup:**
1. Create S3 bucket
2. Upload model directories
3. Make bucket public or use signed URLs
4. Configure CORS

**URL Format:**
```
https://your-bucket.s3.amazonaws.com/models
```

**Upload Command:**
```bash
aws s3 sync assets/models/ s3://your-bucket/models/ \
  --exclude "*" \
  --include "*.mlmodelc" \
  --include "*.json" \
  --include "*.txt"
```

### Option 2: Google Cloud Storage

**URL Format:**
```
https://storage.googleapis.com/your-bucket/models
```

### Option 3: Azure Blob Storage

**URL Format:**
```
https://youraccount.blob.core.windows.net/models
```

### Option 4: Your Own Server

**URL Format:**
```
https://api.yourdomain.com/models
```

**Requirements:**
- Serve files over HTTPS
- Support direct file downloads
- Proper CORS headers if needed

## Model File Structure

Models should be accessible at:
```
https://your-server.com/models/TextEncoder.mlmodelc/
https://your-server.com/models/UnetChunk1.mlmodelc/
https://your-server.com/models/UnetChunk2.mlmodelc/
https://your-server.com/models/VAEDecoder.mlmodelc/
https://your-server.com/models/vocab.json
https://your-server.com/models/merges.txt
```

**Important:** `.mlmodelc` files are **directories**, not single files. Your server needs to:
- Serve them as downloadable directories (tar.gz/zip)
- Or allow recursive directory downloads
- Or provide a way to download the entire directory structure

## Implementation Details

### Download Service

Located in: `services/modelDownloadService.ts`

**Key Functions:**
- `areAllModelsCached()` - Check if all models are downloaded
- `downloadAllModels()` - Download all required models with progress
- `downloadModel()` - Download single model
- `clearModelCache()` - Clear cached models

### Model Path Resolution

The app checks in this order:
1. **Documents directory** (`/Documents/models/`) - Downloaded/cached models
2. **App bundle** (`assets/models/`) - Bundled models (fallback only)

### Native Module Updates

The Swift native module now:
- Checks documents directory first for cached models
- Falls back to app bundle if no cache found
- Logs which path is being used

## User Experience

### First Launch (No Cache):
1. App checks for cached models
2. Shows "Models not cached. Download required."
3. Shows "Download Models" button
4. User taps to download
5. Shows progress: "Downloading TextEncoder.mlmodelc: 45.2%"
6. Progress bar shows download status
7. After download: "✅ Download complete! Loading models..."
8. Models loaded and ready

### Subsequent Launches (Cached):
1. App checks for cached models
2. Finds cached models
3. Loads models immediately
4. Shows: "✅ Models loaded: 5 components"
5. Ready to generate images

## Storage Requirements

- **Download size**: ~2.56 GB (all models)
- **Cache location**: `/Documents/models/` (device storage)
- **Persistent**: Models remain cached until:
  - App is uninstalled
  - User clears app data
  - Cache is manually cleared

## Security Considerations

1. **HTTPS Only**: Always use HTTPS for model downloads
2. **Signed URLs**: Consider using signed URLs for private buckets
3. **Verification**: Add checksum verification (future enhancement)
4. **Authentication**: Add API key if needed (future enhancement)

## Troubleshooting

### Models Not Downloading

1. **Check URL**: Verify `EXPO_PUBLIC_MODEL_BASE_URL` is correct
2. **Test Access**: Try accessing URLs in browser
3. **CORS**: Check CORS settings if using S3
4. **Network**: Verify device has internet connection

### Download Fails

1. **Storage Space**: Check device has enough space (~3 GB)
2. **Network**: Check connection stability
3. **Server**: Check server logs for errors
4. **Permissions**: Verify file permissions on server

### Models Not Loading After Download

1. **File Structure**: Verify `.mlmodelc` directories are complete
2. **Paths**: Check console logs for model paths
3. **Permissions**: Verify app has file system permissions
4. **Corruption**: Re-download if files are corrupted

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

### Clear Cache:
```typescript
import { clearModelCache } from './services/modelDownloadService';

await clearModelCache();
```

## Benefits

✅ **Smaller App Size** - Initial download is just a few MB  
✅ **Faster Updates** - Update models without app update  
✅ **Flexible Deployment** - Easy to switch model versions  
✅ **Better UX** - Users download only when needed  
✅ **Cost Effective** - Pay for storage/bandwidth only when used  
✅ **Easy Updates** - Update models on server without app update  

## Next Steps

1. **Set up cloud storage** (S3, GCS, Azure, or your server)
2. **Upload model files** to cloud storage
3. **Configure `EXPO_PUBLIC_MODEL_BASE_URL`** in `.env`
4. **Test download** in the app
5. **Monitor performance** and optimize if needed

## Notes

- Models are downloaded as directories (`.mlmodelc` files)
- Server needs to support directory downloads or provide archives
- Consider compressing models for faster downloads (future enhancement)
- Add resume capability for interrupted downloads (future enhancement)
