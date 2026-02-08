#!/bin/bash
# Upload models to S3 bucket
# Usage: ./scripts/upload_to_s3.sh

BUCKET="image-gen-pd123"
S3_PATH="s3://${BUCKET}/stable-diffusion"
MODELS_DIR="./assets/models"

echo "📤 Uploading models to S3..."
echo "Bucket: ${BUCKET}"
echo "Path: ${S3_PATH}"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Install with: brew install awscli"
    exit 1
fi

# Check if models directory exists
if [ ! -d "$MODELS_DIR" ]; then
    echo "❌ Models directory not found: $MODELS_DIR"
    exit 1
fi

echo "Uploading model files..."

# Upload .mlmodelc directories (as tar.gz archives - recommended)
echo ""
echo "Option 1: Upload as tar.gz archives (Recommended)"
echo "This creates compressed archives for faster downloads."
echo ""

read -p "Create and upload tar.gz archives? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    cd "$MODELS_DIR"
    
    for dir in *.mlmodelc; do
        if [ -d "$dir" ]; then
            echo "📦 Creating archive: ${dir}.tar.gz"
            tar -czf "${dir}.tar.gz" "$dir"
            
            echo "📤 Uploading: ${dir}.tar.gz"
            aws s3 cp "${dir}.tar.gz" "${S3_PATH}/${dir}.tar.gz"
            
            # Clean up local tar.gz
            rm "${dir}.tar.gz"
        fi
    done
    
    cd - > /dev/null
fi

# Upload tokenizer files
echo ""
echo "📤 Uploading tokenizer files..."
aws s3 cp "${MODELS_DIR}/vocab.json" "${S3_PATH}/vocab.json"
aws s3 cp "${MODELS_DIR}/merges.txt" "${S3_PATH}/merges.txt"

echo ""
echo "✅ Upload complete!"
echo ""
echo "Files uploaded to:"
echo "  https://${BUCKET}.s3.eu-north-1.amazonaws.com/stable-diffusion/"
echo ""
echo "Verify by visiting:"
echo "  https://${BUCKET}.s3.eu-north-1.amazonaws.com/stable-diffusion/vocab.json"
