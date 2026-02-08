# Extract tar.gz Archives After Download

## Current Status

The app now downloads `.tar.gz` files from S3, but **extraction is not yet implemented**.

## Why tar.gz?

S3 cannot serve directories directly. When you try to download a `.mlmodelc` directory, S3 returns 0 bytes. The solution is to:
1. Compress directories as `.tar.gz` archives
2. Upload `.tar.gz` files to S3
3. Download `.tar.gz` files
4. Extract them to get the `.mlmodelc` directories

## Solution Options

### Option 1: Use react-native-zip-archive (Recommended)

This library supports tar.gz extraction:

```bash
npm install react-native-zip-archive
```

Then update `modelDownloadService.ts` to extract after download.

### Option 2: Use Native Module

Create a native iOS module to extract tar.gz using system libraries.

### Option 3: Upload Individual Files

Instead of directories, upload individual files from each `.mlmodelc` directory to S3, then download them one by one.

## Current Workaround

For now, the app will:
1. Download `.tar.gz` files successfully
2. Save them with `.tar.gz` extension
3. Show an error explaining extraction is needed

## Next Steps

1. **Upload tar.gz files to S3** (use the upload script)
2. **Install extraction library** or implement native extraction
3. **Update download service** to extract after download
4. **Test** the full pipeline

## Quick Test

After uploading tar.gz files to S3, the download should work and you'll see the extraction error, which confirms the download is working but extraction is needed.
