#!/usr/bin/env python3
"""
Script to download Stable Diffusion Core ML model from Hugging Face
Run this script to automatically download and set up the model for the app.
"""

import os
import sys
import shutil
from pathlib import Path

try:
    from huggingface_hub import snapshot_download
except ImportError:
    print("Installing huggingface-hub...")
    os.system(f"{sys.executable} -m pip install huggingface-hub")
    from huggingface_hub import snapshot_download

def main():
    print("=" * 60)
    print("Stable Diffusion Core ML Model Downloader")
    print("=" * 60)
    
    # Model options - Available Apple Core ML models on Hugging Face
    models = {
        "1": {
            "id": "apple/coreml-stable-diffusion-v1-4",
            "name": "Stable Diffusion v1.4 (Original)",
            "size": "~4GB",
            "precision": "FP16"
        },
        "2": {
            "id": "apple/coreml-stable-diffusion-v1-5",
            "name": "Stable Diffusion v1.5 (Recommended)",
            "size": "~4GB",
            "precision": "FP16"
        },
        "3": {
            "id": "apple/coreml-stable-diffusion-2-base",
            "name": "Stable Diffusion v2 Base",
            "size": "~4.5GB",
            "precision": "FP16"
        }
    }
    
    print("\n⚠️  Note: Apple doesn't provide pre-quantized (int8) models.")
    print("   All models are FP16 (half precision).")
    print("   To get int8 quantized models, you need to quantize them yourself.")
    print("   See MODEL_INFO.md for quantization instructions.\n")
    
    print("\nAvailable models:")
    for key, model in models.items():
        print(f"  {key}. {model['name']} ({model['size']})")
    
    choice = input("\nSelect model (1-3, default: 2): ").strip() or "2"
    
    if choice not in models:
        print(f"Invalid choice. Using default: v1.5")
        choice = "2"
    
    selected_model = models[choice]
    print(f"\nSelected: {selected_model['name']}")
    print(f"Model ID: {selected_model['id']}")
    
    # Create directories
    download_dir = Path("./downloaded_models")
    assets_dir = Path("./assets/models")
    
    download_dir.mkdir(exist_ok=True, parents=True)
    assets_dir.mkdir(exist_ok=True, parents=True)
    
    print(f"\nDownloading model to: {download_dir}")
    print("This may take a while depending on your internet connection...")
    
    try:
        # Download model
        model_path = snapshot_download(
            repo_id=selected_model['id'],
            local_dir=str(download_dir),
            local_dir_use_symlinks=False
        )
        
        print(f"\n✓ Model downloaded successfully!")
        print(f"  Location: {model_path}")
        
        # List downloaded files
        print("\nDownloaded files:")
        for root, dirs, files in os.walk(model_path):
            level = root.replace(model_path, '').count(os.sep)
            indent = ' ' * 2 * level
            print(f"{indent}{os.path.basename(root)}/")
            subindent = ' ' * 2 * (level + 1)
            for file in files:
                print(f"{subindent}{file}")
        
        # Check for model files
        model_files = list(Path(model_path).rglob("*.mlmodel*"))
        
        if model_files:
            print(f"\nFound {len(model_files)} model file(s):")
            for f in model_files:
                size_mb = f.stat().st_size / (1024 * 1024)
                print(f"  - {f.name} ({size_mb:.1f} MB)")
            
            # Ask if user wants to copy to assets
            copy = input("\nCopy model to assets/models/? (y/n, default: y): ").strip().lower()
            if copy != 'n':
                # For now, just copy the directory structure
                # User may need to manually select which files to use
                print("\nNote: Apple's Core ML models are typically in .mlmodelc format (packages)")
                print("You may need to:")
                print("  1. Use the .mlmodelc files directly in your native code")
                print("  2. Or convert them to .mlmodel format")
                print(f"\nModel files are in: {model_path}")
                print(f"Assets directory ready at: {assets_dir}")
        else:
            print("\n⚠ No .mlmodel files found in downloaded package")
            print("The model may be in a different format or structure")
            print(f"Check the downloaded files in: {model_path}")
        
        print("\n" + "=" * 60)
        print("Next Steps:")
        print("=" * 60)
        print("1. Review the downloaded model structure")
        print("2. Copy the appropriate model file(s) to assets/models/")
        print("3. Update ImageGenerationModule.ios.swift if using separate components")
        print("4. Build your app: npx expo run:ios")
        print("\nFor detailed instructions, see MODEL_SETUP.md")
        
    except Exception as e:
        print(f"\n✗ Error downloading model: {e}")
        print("\nTroubleshooting:")
        print("1. Check your internet connection")
        print("2. Verify you have enough disk space")
        print("3. Try logging in to Hugging Face: huggingface-cli login")
        sys.exit(1)

if __name__ == "__main__":
    main()
