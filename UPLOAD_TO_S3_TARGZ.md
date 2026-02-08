# Upload Models to S3 as tar.gz Archives

## The Problem

S3 cannot serve directories directly. When you try to download a `.mlmodelc` directory from S3, it returns:
- 0 bytes (empty file)
- HTML directory listing
- Error page

## Solution: Upload as tar.gz Archives

### Step 1: Compress Models

On your local machine, compress each `.mlmodelc` directory:

```bash
cd assets/models

# Compress each directory
tar -czf TextEncoder.mlmodelc.tar.gz TextEncoder.mlmodelc/
tar -czf UnetChunk1.mlmodelc.tar.gz UnetChunk1.mlmodelc/
tar -czf UnetChunk2.mlmodelc.tar.gz UnetChunk2.mlmodelc/
tar -czf VAEDecoder.mlmodelc.tar.gz VAEDecoder.mlmodelc/
tar -czf SafetyChecker.mlmodelc.tar.gz SafetyChecker.mlmodelc/
```

### Step 2: Upload to S3

```bash
# Upload tar.gz files
aws s3 cp TextEncoder.mlmodelc.tar.gz s3://image-gen-pd123/stable-diffusion/
aws s3 cp UnetChunk1.mlmodelc.tar.gz s3://image-gen-pd123/stable-diffusion/
aws s3 cp UnetChunk2.mlmodelc.tar.gz s3://image-gen-pd123/stable-diffusion/
aws s3 cp VAEDecoder.mlmodelc.tar.gz s3://image-gen-pd123/stable-diffusion/
aws s3 cp SafetyChecker.mlmodelc.tar.gz s3://image-gen-pd123/stable-diffusion/

# Upload regular files
aws s3 cp vocab.json s3://image-gen-pd123/stable-diffusion/
aws s3 cp merges.txt s3://image-gen-pd123/stable-diffusion/
```

### Step 3: Update Code to Use tar.gz URLs

After uploading, the code needs to be updated to:
1. Download `.tar.gz` files
2. Extract them after download

**Note:** The code will need to be updated to handle tar.gz extraction. For now, the error messages will guide you.

## Quick Upload Script

I'll create a script to help with this.
