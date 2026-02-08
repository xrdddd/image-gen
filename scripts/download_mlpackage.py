#!/usr/bin/env python3
"""
Download original .mlpackage files from Hugging Face
These are the uncompiled source models that can be quantized.
"""

import os
import sys
from pathlib import Path

try:
    from huggingface_hub import snapshot_download
except ImportError:
    print("=" * 60)
    print("ERROR: huggingface_hub is not installed")
    print("=" * 60)
    print("\nPlease install huggingface_hub first:")
    print('  pip install "huggingface-hub"')
    print("\nOr if you're in conda:")
    print('  conda install -c conda-forge huggingface_hub')
    print("\nOr with --user flag:")
    print('  pip install --user "huggingface-hub"')
    sys.exit(1)

def main():
    print("=" * 60)
    print("Downloading Original .mlpackage Files")
    print("=" * 60)
    
    base_dir = Path(__file__).parent.parent
    output_dir = base_dir / "assets" / "models_original"
    output_dir.mkdir(exist_ok=True, parents=True)
    
    model_id = "apple/coreml-stable-diffusion-v1-5"
    
    print(f"\nModel: {model_id}")
    print(f"Output directory: {output_dir}")
    print("\nDownloading... This may take a while...")
    
    try:
        # Download the model
        model_path = snapshot_download(
            repo_id=model_id,
            local_dir=str(output_dir),
            local_dir_use_symlinks=False
        )
        
        print(f"\n✓ Download complete!")
        print(f"  Location: {model_path}")
        
        # Check for .mlpackage files
        mlpackage_files = list(Path(model_path).rglob("*.mlpackage"))
        
        if mlpackage_files:
            print(f"\n✓ Found {len(mlpackage_files)} .mlpackage file(s):")
            for f in mlpackage_files:
                size_mb = f.stat().st_size / (1024 * 1024)
                print(f"  - {f.name} ({size_mb:.1f} MB)")
            print("\n✓ Original .mlpackage files are ready for quantization!")
        else:
            print("\n⚠️  No .mlpackage files found.")
            print("   The repository may only contain .mlmodelc files.")
            print("   Checking for other formats...")
            
            # List all files
            all_files = list(Path(model_path).rglob("*"))
            model_files = [f for f in all_files if f.is_file() and not f.name.startswith('.')]
            
            print(f"\nFound {len(model_files)} files:")
            for f in model_files[:20]:  # Show first 20
                rel_path = f.relative_to(model_path)
                print(f"  - {rel_path}")
            
            if len(model_files) > 20:
                print(f"  ... and {len(model_files) - 20} more files")
        
        print(f"\n{'='*60}")
        print("Next Steps:")
        print(f"{'='*60}")
        print("1. Check the downloaded files in:", output_dir)
        print("2. If .mlpackage files are found, run quantization:")
        print("   python3 scripts/quantize_mlpackage.py")
        print("3. Or update quantize_models.py to use .mlpackage files")
        
    except Exception as e:
        print(f"\n❌ Error downloading: {e}")
        print("\nTroubleshooting:")
        print("1. Check your internet connection")
        print("2. Verify the model ID is correct")
        print("3. Try logging in: huggingface-cli login")
        sys.exit(1)

if __name__ == "__main__":
    main()
