#!/usr/bin/env python3
"""
Complete INT8 Quantization Pipeline
Downloads original .mlpackage files, quantizes them to INT8, and compiles them.

IMPORTANT: Apple's Hugging Face repository may only contain .mlmodelc files.
If .mlpackage files are not available, you'll need to convert from PyTorch.
"""

import os
import sys
import shutil
from pathlib import Path

try:
    import coremltools as ct
    from coremltools.models import MLModel
except ImportError:
    print("=" * 60)
    print("ERROR: coremltools is not installed")
    print("=" * 60)
    print("\nPlease install coremltools first:")
    print('  pip install "coremltools>=7.0"')
    sys.exit(1)

try:
    from huggingface_hub import snapshot_download, list_repo_files
    HAS_HF = True
except ImportError:
    HAS_HF = False
    print("⚠️  huggingface_hub not installed. Will only quantize existing .mlpackage files.")

# Project paths
project_root = Path(__file__).parent.parent
models_dir = project_root / "assets" / "models"
quantized_dir = project_root / "assets" / "models_quantized"
backup_dir = project_root / "assets" / "models_backup"

# Model components to quantize
MODEL_COMPONENTS = [
    "TextEncoder",
    "UnetChunk1",
    "UnetChunk2",
    "VAEDecoder",
    "SafetyChecker",  # Optional
    "VAEEncoder",     # Optional
]

def get_model_size_mb(model_path):
    """Get size of model in MB"""
    if os.path.isdir(model_path):
        total = 0
        for dirpath, dirnames, filenames in os.walk(model_path):
            for filename in filenames:
                filepath = os.path.join(dirpath, filename)
                total += os.path.getsize(filepath)
        return total / (1024 * 1024)
    else:
        return os.path.getsize(model_path) / (1024 * 1024)

def check_repository_files():
    """Check what files are actually in the Hugging Face repository"""
    if not HAS_HF:
        return None, []
    
    repo_id = "apple/coreml-stable-diffusion-v1-5"
    
    print("\n" + "=" * 60)
    print("Checking Hugging Face Repository")
    print("=" * 60)
    print(f"Repository: {repo_id}")
    
    try:
        files = list_repo_files(repo_id=repo_id, repo_type="model")
        
        mlpackage_files = [f for f in files if f.endswith('.mlpackage')]
        mlmodelc_files = [f for f in files if '.mlmodelc' in f]
        
        print(f"\nFound {len(files)} total files")
        print(f"  .mlpackage files: {len(mlpackage_files)}")
        print(f"  .mlmodelc files: {len(mlmodelc_files)}")
        
        if mlpackage_files:
            print("\n✅ .mlpackage files found:")
            for f in mlpackage_files[:10]:
                print(f"   - {f}")
            if len(mlpackage_files) > 10:
                print(f"   ... and {len(mlpackage_files) - 10} more")
        else:
            print("\n⚠️  No .mlpackage files found in repository!")
            print("   The repository only contains compiled .mlmodelc files.")
            print("\n   This means you cannot quantize directly from Hugging Face.")
            print("   You need to convert from PyTorch with quantization.")
        
        return repo_id, mlpackage_files
        
    except Exception as e:
        print(f"❌ Error checking repository: {e}")
        return None, []

def download_mlpackage_files():
    """Download original .mlpackage files from Hugging Face"""
    if not HAS_HF:
        print("⚠️  Cannot download: huggingface_hub not installed")
        print("   Install with: pip install huggingface_hub")
        return None
    
    print("\n" + "=" * 60)
    print("Downloading from Hugging Face")
    print("=" * 60)
    
    # First check what's available
    repo_id, mlpackage_files = check_repository_files()
    
    if not mlpackage_files:
        print("\n❌ No .mlpackage files available in the repository!")
        print("\n" + "=" * 60)
        print("Alternative Solutions:")
        print("=" * 60)
        print("\n1. Convert from PyTorch with quantization:")
        print("   - Use Apple's ml-stable-diffusion repository")
        print("   - Convert with quantization built-in")
        print("   - See: https://github.com/apple/ml-stable-diffusion")
        print("\n2. Use FP16 models as-is:")
        print("   - Your current models work well")
        print("   - 2.56 GB is acceptable for modern devices")
        print("   - iPhone 13 Pro+ has sufficient RAM")
        print("\n3. Check for pre-quantized models:")
        print("   - Some community repositories may have INT8 models")
        print("   - Search Hugging Face for 'coreml-stable-diffusion-int8'")
        return None
    
    download_dir = project_root / "downloads" / "mlpackage"
    download_dir.mkdir(parents=True, exist_ok=True)
    
    try:
        print(f"\nDownloading to: {download_dir}")
        print("This may take a while (several GB)...")
        
        # Download without pattern restriction first to see structure
        snapshot_download(
            repo_id=repo_id,
            local_dir=str(download_dir),
            local_dir_use_symlinks=False,
        )
        
        # Check what was actually downloaded
        downloaded_files = list(download_dir.rglob("*.mlpackage"))
        downloaded_mlmodelc = list(download_dir.rglob("*.mlmodelc"))
        
        print(f"\n✅ Download complete!")
        print(f"   .mlpackage files found: {len(downloaded_files)}")
        print(f"   .mlmodelc files found: {len(downloaded_mlmodelc)}")
        
        if downloaded_files:
            print("\n   .mlpackage files:")
            for f in downloaded_files:
                size_mb = get_model_size_mb(f)
                print(f"     - {f.relative_to(download_dir)} ({size_mb:.1f} MB)")
            return download_dir
        else:
            print("\n⚠️  No .mlpackage files were downloaded!")
            print("   The repository only contains compiled .mlmodelc files.")
            print("\n   You cannot quantize .mlmodelc files directly.")
            print("   See alternative solutions above.")
            return None
        
    except Exception as e:
        print(f"❌ Download failed: {e}")
        import traceback
        traceback.print_exc()
        return None

def find_mlpackage_file(component_name, search_dirs):
    """Find .mlpackage file for a component"""
    for search_dir in search_dirs:
        if not search_dir or not search_dir.exists():
            continue
        
        # Try different naming patterns and directory structures
        patterns = [
            f"{component_name}.mlpackage",
            f"{component_name.lower()}.mlpackage",
            f"*{component_name}*.mlpackage",
            f"**/{component_name}.mlpackage",  # Nested directories
            f"**/*{component_name}*.mlpackage",
        ]
        
        for pattern in patterns:
            matches = list(search_dir.rglob(pattern))
            if matches:
                return matches[0]
    
    return None

def quantize_mlpackage(input_path, output_path, component_name):
    """Quantize a .mlpackage file from FP16 to INT8"""
    print(f"\n{'='*60}")
    print(f"Quantizing: {component_name}")
    print(f"{'='*60}")
    
    if not input_path or not input_path.exists():
        print(f"⚠️  {component_name}.mlpackage not found, skipping...")
        return False
    
    try:
        # Get original size
        original_size = get_model_size_mb(input_path)
        print(f"Original size: {original_size:.2f} MB")
        
        # Load .mlpackage file
        print(f"Loading: {input_path}")
        model = MLModel(str(input_path))
        print("✓ Model loaded successfully")
        
        # Quantize to INT8
        print("Quantizing to INT8 (this may take a few minutes)...")
        quantized_model = ct.models.neural_network.quantization_utils.quantize_weights(
            model,
            nbits=8,
            quantization_mode="linear"  # Use "kmeans" for potentially better quality
        )
        print("✓ Quantization successful")
        
        # Create output directory
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Save as .mlpackage first
        temp_mlpackage = output_path.parent / f"{component_name}_temp.mlpackage"
        quantized_model.save(str(temp_mlpackage))
        
        # Compile to .mlmodelc
        print(f"Compiling to .mlmodelc: {output_path}")
        compiled_path = ct.models.MLModel.compileModel(at=temp_mlpackage)
        
        # Move compiled model to final location
        if output_path.exists():
            shutil.rmtree(output_path)
        shutil.move(compiled_path.path, str(output_path))
        
        # Clean up temp file
        if temp_mlpackage.exists():
            shutil.rmtree(temp_mlpackage)
        
        # Get new size
        new_size = get_model_size_mb(output_path)
        reduction = ((original_size - new_size) / original_size) * 100
        
        print(f"✓ Quantized size: {new_size:.2f} MB")
        print(f"✓ Size reduction: {reduction:.1f}% ({original_size - new_size:.2f} MB saved)")
        
        return True
        
    except Exception as e:
        print(f"❌ Quantization failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """Main quantization pipeline"""
    print("=" * 60)
    print("INT8 Quantization Pipeline")
    print("=" * 60)
    print("\nThis will:")
    print("  1. Check Hugging Face repository for .mlpackage files")
    print("  2. Download them if available")
    print("  3. Quantize each model component to INT8")
    print("  4. Compile quantized models to .mlmodelc")
    print()
    
    # Step 1: Check repository first
    repo_id, mlpackage_files = check_repository_files()
    
    if not mlpackage_files:
        print("\n" + "=" * 60)
        print("⚠️  Cannot Quantize from Hugging Face")
        print("=" * 60)
        print("\nThe repository only contains compiled .mlmodelc files.")
        print("You cannot quantize compiled files directly.")
        print("\nAlternative Options:")
        print("\n1. Use FP16 models as-is (Recommended)")
        print("   - Your current 2.56 GB models work well")
        print("   - Compatible with iPhone 13 Pro+ (6+ GB RAM)")
        print("   - Good quality and performance")
        print("\n2. Convert from PyTorch with quantization")
        print("   - Clone: https://github.com/apple/ml-stable-diffusion")
        print("   - Convert with quantization built-in")
        print("   - More complex but gives you full control")
        print("\n3. Check for community quantized models")
        print("   - Search Hugging Face for pre-quantized versions")
        print("   - May be available from other sources")
        return
    
    response = input("\nContinue with download and quantization? (y/N): ")
    if response.lower() != 'y':
        print("Cancelled.")
        return
    
    # Step 2: Download .mlpackage files
    download_dir = download_mlpackage_files()
    
    if not download_dir:
        print("\n❌ Cannot proceed without .mlpackage files")
        return
    
    # Search directories for .mlpackage files
    search_dirs = [
        download_dir,
        project_root / "downloads" / "mlpackage",
        models_dir,
    ]
    
    # Step 3: Quantize each component
    print("\n" + "=" * 60)
    print("Quantizing Models")
    print("=" * 60)
    
    quantized_dir.mkdir(parents=True, exist_ok=True)
    
    results = {}
    total_original = 0
    total_quantized = 0
    
    for component in MODEL_COMPONENTS:
        # Find .mlpackage file
        mlpackage_path = find_mlpackage_file(component, search_dirs)
        
        if not mlpackage_path:
            print(f"\n⚠️  {component}.mlpackage not found")
            print("   You may need to download it first or it's optional")
            results[component] = False
            continue
        
        # Quantize
        output_path = quantized_dir / f"{component}.mlmodelc"
        success = quantize_mlpackage(mlpackage_path, output_path, component)
        results[component] = success
        
        if success:
            original_size = get_model_size_mb(mlpackage_path)
            quantized_size = get_model_size_mb(output_path)
            total_original += original_size
            total_quantized += quantized_size
    
    # Step 4: Copy tokenizer files
    print("\n" + "=" * 60)
    print("Copying Tokenizer Files")
    print("=" * 60)
    
    for file in ['vocab.json', 'merges.txt']:
        src = models_dir / file
        if src.exists():
            dest = quantized_dir / file
            shutil.copy2(src, dest)
            print(f"✓ Copied: {file}")
    
    # Step 5: Summary
    print("\n" + "=" * 60)
    print("Quantization Summary")
    print("=" * 60)
    
    successful = [k for k, v in results.items() if v]
    failed = [k for k, v in results.items() if not v]
    
    print(f"\n✅ Successfully quantized: {len(successful)}/{len(MODEL_COMPONENTS)}")
    for component in successful:
        print(f"   ✓ {component}")
    
    if failed:
        print(f"\n⚠️  Failed or skipped: {len(failed)}")
        for component in failed:
            print(f"   ✗ {component}")
    
    if total_original > 0:
        reduction = ((total_original - total_quantized) / total_original) * 100
        print(f"\n📊 Size Reduction:")
        print(f"   Original: {total_original:.1f} MB ({total_original/1024:.2f} GB)")
        print(f"   Quantized: {total_quantized:.1f} MB ({total_quantized/1024:.2f} GB)")
        print(f"   Saved: {total_original - total_quantized:.1f} MB ({reduction:.1f}%)")
    
    print("\n🎉 Process complete!")

if __name__ == "__main__":
    main()
