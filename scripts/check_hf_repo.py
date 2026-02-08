#!/usr/bin/env python3
"""
Check what files are actually available in the Hugging Face repository
"""

import sys
from pathlib import Path

try:
    from huggingface_hub import list_repo_files, hf_hub_download
    HAS_HF = True
except ImportError:
    print("ERROR: huggingface_hub not installed")
    print("Install with: pip install huggingface_hub")
    sys.exit(1)

def main():
    repo_id = "apple/coreml-stable-diffusion-v1-5"
    
    print("=" * 60)
    print(f"Checking Repository: {repo_id}")
    print("=" * 60)
    
    try:
        # List all files in the repository
        print("\n📁 Listing all files in repository...")
        files = list_repo_files(repo_id=repo_id, repo_type="model")
        
        print(f"\nFound {len(files)} files:")
        print("-" * 60)
        
        mlpackage_files = []
        mlmodelc_files = []
        other_files = []
        
        for file in files:
            if file.endswith('.mlpackage'):
                mlpackage_files.append(file)
                print(f"✅ {file} (.mlpackage)")
            elif file.endswith('.mlmodelc'):
                mlmodelc_files.append(file)
                print(f"📦 {file} (.mlmodelc - compiled)")
            else:
                other_files.append(file)
                print(f"📄 {file}")
        
        print("\n" + "=" * 60)
        print("Summary:")
        print("=" * 60)
        print(f"  .mlpackage files: {len(mlpackage_files)}")
        print(f"  .mlmodelc files: {len(mlmodelc_files)}")
        print(f"  Other files: {len(other_files)}")
        
        if mlpackage_files:
            print("\n✅ .mlpackage files found! These can be quantized.")
            print("\nFiles:")
            for f in mlpackage_files:
                print(f"  - {f}")
        else:
            print("\n⚠️  No .mlpackage files found!")
            print("   The repository only contains compiled .mlmodelc files.")
            print("\n   This means:")
            print("   1. Apple doesn't provide source .mlpackage files")
            print("   2. You need to convert from PyTorch yourself")
            print("   3. Or use the FP16 models as-is")
            
            if mlmodelc_files:
                print(f"\n   Available .mlmodelc files ({len(mlmodelc_files)}):")
                for f in mlmodelc_files[:10]:  # Show first 10
                    print(f"     - {f}")
                if len(mlmodelc_files) > 10:
                    print(f"     ... and {len(mlmodelc_files) - 10} more")
        
        print("\n" + "=" * 60)
        print("Recommendation:")
        print("=" * 60)
        
        if mlpackage_files:
            print("✅ You can download and quantize .mlpackage files")
            print("   Run: python3 scripts/quantize_to_int8.py")
        else:
            print("⚠️  Cannot quantize directly from Hugging Face")
            print("\n   Options:")
            print("   1. Convert from PyTorch with quantization")
            print("   2. Use FP16 models as-is (they work well)")
            print("   3. Check if there's a quantized version available")
            
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
