# URGENT: Fix S3 Download - 0 Bytes Issue

## The Problem

Downloads are showing **0 bytes** because S3 cannot serve directories directly.

## Root Cause

`.mlmodelc` files are **directories**, not files. When S3 tries to serve a directory URL, it returns:
- 0-byte file
- HTML directory listing
- Error page

## Immediate Solution

You **MUST** upload the models as **tar.gz archives** to S3.

### Quick Fix Steps:

1. **Compress models locally:**
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

3. **Update code URLs** to use `.tar.gz` extension (I'll do this next)

4. **Add tar.gz extraction** after download (requires a library)

## Why This Happens

- S3 URLs like `https://bucket.s3.../TextEncoder.mlmodelc` point to a **directory**
- S3 cannot download directories - only files
- You need to compress directories as `.tar.gz` files first

## After Uploading tar.gz

The code will need to:
1. Download `.tar.gz` files
2. Extract them to get the `.mlmodelc` directories
3. Use the extracted directories

I'll update the code to handle this once you've uploaded the tar.gz files.
