# S3 Model Download Setup

## Configuration

Your app is now configured to download models from AWS S3:

**S3 Bucket:** `image-gen-pd123.s3.eu-north-1.amazonaws.com/stable-diffusion`

## S3 File Structure Required

Your S3 bucket should have this structure:

```
stable-diffusion/
├── TextEncoder.mlmodelc/          (or TextEncoder.mlmodelc.tar.gz)
├── UnetChunk1.mlmodelc/           (or UnetChunk1.mlmodelc.tar.gz)
├── UnetChunk2.mlmodelc/           (or UnetChunk2.mlmodelc.tar.gz)
├── VAEDecoder.mlmodelc/           (or VAEDecoder.mlmodelc.tar.gz)
├── SafetyChecker.mlmodelc/        (optional)
├── vocab.json
└── merges.txt
```

## Important: .mlmodelc Directory Handling

`.mlmodelc` files are **directories**, not single files. S3 has two options:

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

2. **Upload to S3:**
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

### Option 2: Upload Directories with Sync

1. **Sync entire directory structure:**
   ```bash
   aws s3 sync assets/models/ s3://image-gen-pd123/stable-diffusion/ \
     --exclude "*" \
     --include "*.mlmodelc/**" \
     --include "*.json" \
     --include "*.txt"
   ```

2. **Note:** This creates individual file URLs, which is more complex to download

## Current Implementation

The app is configured to download from:
- `https://image-gen-pd123.s3.eu-north-1.amazonaws.com/stable-diffusion/TextEncoder.mlmodelc`
- `https://image-gen-pd123.s3.eu-north-1.amazonaws.com/stable-diffusion/UnetChunk1.mlmodelc`
- etc.

## S3 Permissions

Make sure your S3 bucket has:

1. **Public Read Access** (for public downloads):
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "PublicReadGetObject",
         "Effect": "Allow",
         "Principal": "*",
         "Action": "s3:GetObject",
         "Resource": "arn:aws:s3:::image-gen-pd123/stable-diffusion/*"
       }
     ]
   }
   ```

2. **CORS Configuration** (if needed):
   ```json
   [
     {
       "AllowedHeaders": ["*"],
       "AllowedMethods": ["GET", "HEAD"],
       "AllowedOrigins": ["*"],
       "ExposeHeaders": []
     }
   ]
   ```

## Testing

1. **Test S3 URLs in browser:**
   - Visit: `https://image-gen-pd123.s3.eu-north-1.amazonaws.com/stable-diffusion/vocab.json`
   - Should download or display the file

2. **Test in app:**
   - Launch app
   - Tap "Download Models" button
   - Watch download progress
   - Models should download to device storage

## Troubleshooting

### "Download failed: 404"
- Check file exists in S3
- Verify URL is correct
- Check S3 bucket permissions

### "Download failed: Access Denied"
- Check S3 bucket policy
- Verify CORS settings
- Check IAM permissions

### ".mlmodelc download fails"
- Ensure directories are uploaded correctly
- Consider using tar.gz archives
- Check file structure in S3

## Next Steps

1. **Upload models to S3** using one of the methods above
2. **Test URLs** in browser to verify access
3. **Test download** in the app
4. **Monitor download progress** and fix any issues

## Model URLs

The app will download from:
- `https://image-gen-pd123.s3.eu-north-1.amazonaws.com/stable-diffusion/TextEncoder.mlmodelc`
- `https://image-gen-pd123.s3.eu-north-1.amazonaws.com/stable-diffusion/UnetChunk1.mlmodelc`
- `https://image-gen-pd123.s3.eu-north-1.amazonaws.com/stable-diffusion/UnetChunk2.mlmodelc`
- `https://image-gen-pd123.s3.eu-north-1.amazonaws.com/stable-diffusion/VAEDecoder.mlmodelc`
- `https://image-gen-pd123.s3.eu-north-1.amazonaws.com/stable-diffusion/vocab.json`
- `https://image-gen-pd123.s3.eu-north-1.amazonaws.com/stable-diffusion/merges.txt`
