# Fix S3 Download Issue - 0 Bytes Downloaded

## The Problem

Downloads are showing:
- 0.00 MB file size
- Negative percentage
- File exists but is empty

## Root Cause

S3 is likely serving a **directory listing** or **error page** instead of the actual file. This happens when:
1. The URL points to a directory (`.mlmodelc` is a directory, not a file)
2. S3 doesn't support direct directory downloads
3. The file needs to be downloaded as a tar.gz archive

## Solution: Use tar.gz Archives

Since `.mlmodelc` files are **directories**, S3 cannot serve them directly. You need to:

### Option 1: Upload as tar.gz Archives (Recommended)

1. **Compress each .mlmodelc directory:**
   ```bash
   cd assets/models
   tar -czf TextEncoder.mlmodelc.tar.gz TextEncoder.mlmodelc/
   tar -czf UnetChunk1.mlmodelc.tar.gz UnetChunk1.mlmodelc/
   tar -czf UnetChunk2.mlmodelc.tar.gz UnetChunk2.mlmodelc/
   tar -czf VAEDecoder.mlmodelc.tar.gz VAEDecoder.mlmodelc/
   tar -czf SafetyChecker.mlmodelc.tar.gz SafetyChecker.mlmodelc/
   ```

2. **Upload tar.gz files to S3:**
   ```bash
   aws s3 cp TextEncoder.mlmodelc.tar.gz s3://image-gen-pd123/stable-diffusion/
   aws s3 cp UnetChunk1.mlmodelc.tar.gz s3://image-gen-pd123/stable-diffusion/
   aws s3 cp UnetChunk2.mlmodelc.tar.gz s3://image-gen-pd123/stable-diffusion/
   aws s3 cp VAEDecoder.mlmodelc.tar.gz s3://image-gen-pd123/stable-diffusion/
   aws s3 cp SafetyChecker.mlmodelc.tar.gz s3://image-gen-pd123/stable-diffusion/
   aws s3 cp vocab.json s3://image-gen-pd123/stable-diffusion/
   aws s3 cp merges.txt s3://image-gen-pd123/stable-diffusion/
   ```

3. **Update model URLs in code** to use `.tar.gz` extension

4. **Add extraction logic** to extract tar.gz after download

### Option 2: Use S3 Sync (Alternative)

If you want to keep directories:

```bash
# Sync entire directory structure
aws s3 sync assets/models/ s3://image-gen-pd123/stable-diffusion/ \
  --exclude "*" \
  --include "*.mlmodelc/**" \
  --include "*.json" \
  --include "*.txt"
```

But this creates individual file URLs, which is more complex to download.

## Quick Fix: Update URLs to tar.gz

Update `services/modelDownloadService.ts`:

```typescript
const MODEL_COMPONENTS: ModelDownloadInfo[] = [
  {
    name: 'TextEncoder.mlmodelc',
    url: `${MODEL_BASE_URL}/TextEncoder.mlmodelc.tar.gz`, // Add .tar.gz
    size: 234.9 * 1024 * 1024,
    required: true,
  },
  // ... etc
];
```

Then add tar.gz extraction after download.

## Why This Happens

- `.mlmodelc` is a **directory**, not a file
- S3 URLs to directories return directory listings (HTML) or 0-byte files
- You need to either:
  1. Compress as tar.gz and extract after download
  2. Download individual files within the directory
  3. Use a different storage solution that supports directory downloads

## Recommended Approach

**Use tar.gz archives** - it's the simplest and most reliable:
1. Smaller download size (compressed)
2. Single file per model
3. Easy to extract
4. Works with standard S3 URLs
