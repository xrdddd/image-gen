#!/usr/bin/env python3
"""
Quantize .mlpackage files (uncompiled Core ML models) to INT8
This script works with the original .mlpackage files from Hugging Face.
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

def quantize_mlpackage(input_path, output_path, model_name):
    """
    Quantize a .mlpackage file from FP16 to INT8
    """
    print(f"\n{'='*60}")
    print(f"Quantizing: {model_name}")
    print(f"{'='*60}")
    
    if not os.path.exists(input_path):
        print(f"⚠️  Warning: {input_path} not found, skipping...")
        return False
    
    try:
        # Get original size
        original_size = get_model_size_mb(input_path)
        print(f"Original size: {original_size:.2f} MB")
        
        # Load .mlpackage file
        print(f"Loading .mlpackage from: {input_path}")
        
        try:
            # Load the .mlpackage file
            model = MLModel(input_path)
            print("✓ Model loaded successfully")
        except Exception as e:
            print(f"❌ Failed to load .mlpackage: {e}")
            return False
        
        # Quantize to INT8
        print("Quantizing to INT8...")
        try:
            quantized_model = ct.models.neural_network.quantization_utils.quantize_weights(
                model,
                nbits=8,
                quantization_mode="linear"
            )
            print("✓ Quantization successful")
        except Exception as e:
            print(f"❌ Quantization failed: {e}")
            return False
        
        # Create output directory if needed
        output_dir = os.path.dirname(output_path)
        if output_dir and not os.path.exists(output_dir):
            os.makedirs(output_dir, exist_ok=True)
        
        # Save quantized model
        print(f"Saving quantized model to: {output_path}")
        quantized_model.save(output_path)
        
        # Get new size
        new_size = get_model_size_mb(output_path)
        reduction = ((original_size - new_size) / original_size) * 100
        
        print(f"✓ Quantized size: {new_size:.2f} MB")
        print(f"✓ Size reduction: {reduction:.1f}% ({original_size - new_size:.2f} MB saved)")
        
        return True
        
    except Exception as e:
        print(f"❌ Error quantizing {model_name}: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    print("=" * 60)
    print("Core ML .mlpackage Quantization Tool")
    print("Converting FP16 .mlpackage files to INT8")
    print("=" * 60)
    
    # Paths
    base_dir = Path(__file__).parent.parent
    models_dir = base_dir / "assets" / "models_original"
    quantized_dir = base_dir / "assets" / "models_quantized"
    
    if not models_dir.exists():
        print(f"❌ Original models directory not found: {models_dir}")
        print("   Please run: python3 scripts/download_mlpackage.py first")
        sys.exit(1)
    
    # Find all .mlpackage files
    mlpackage_files = list(models_dir.rglob("*.mlpackage"))
    
    if not mlpackage_files:
        print(f"❌ No .mlpackage files found in {models_dir}")
        print("   The downloaded files may only contain .mlmodelc files.")
        print("   Try downloading again or check the Hugging Face repository.")
        sys.exit(1)
    
    # Create output directory
    quantized_dir.mkdir(exist_ok=True, parents=True)
    
    print(f"\nFound {len(mlpackage_files)} .mlpackage file(s):")
    for f in mlpackage_files:
        size_mb = get_model_size_mb(str(f))
        print(f"  - {f.name} ({size_mb:.2f} MB)")
    
    # Process each .mlpackage file
    results = {
        "success": [],
        "failed": []
    }
    
    total_original_size = 0
    total_quantized_size = 0
    
    for mlpackage_file in mlpackage_files:
        model_name = mlpackage_file.stem
        output_path = quantized_dir / f"{model_name}_quantized.mlpackage"
        
        original_size = get_model_size_mb(str(mlpackage_file))
        total_original_size += original_size
        
        success = quantize_mlpackage(
            str(mlpackage_file),
            str(output_path),
            model_name
        )
        
        if success:
            results["success"].append(model_name)
            new_size = get_model_size_mb(str(output_path))
            total_quantized_size += new_size
        else:
            results["failed"].append(model_name)
            total_quantized_size += original_size  # Count original if failed
    
    # Copy tokenizer files if they exist
    print(f"\n{'='*60}")
    print("Copying tokenizer files...")
    print(f"{'='*60}")
    
    tokenizer_files = ["vocab.json", "merges.txt"]
    for token_file in tokenizer_files:
        src = models_dir / token_file
        dst = quantized_dir / token_file
        if src.exists():
            shutil.copy2(str(src), str(dst))
            print(f"✓ Copied {token_file}")
    
    # Summary
    print(f"\n{'='*60}")
    print("Quantization Summary")
    print(f"{'='*60}")
    print(f"✓ Successfully quantized: {len(results['success'])}")
    for name in results["success"]:
        print(f"   - {name}")
    
    if results["failed"]:
        print(f"\n❌ Failed: {len(results['failed'])}")
        for name in results["failed"]:
            print(f"   - {name}")
    
    total_reduction = ((total_original_size - total_quantized_size) / total_original_size) * 100 if total_original_size > 0 else 0
    
    print(f"\n{'='*60}")
    print(f"Total original size: {total_original_size:.2f} MB")
    print(f"Total quantized size: {total_quantized_size:.2f} MB")
    print(f"Total reduction: {total_reduction:.1f}% ({total_original_size - total_quantized_size:.2f} MB saved)")
    print(f"{'='*60}")
    
    if results["success"]:
        print(f"\n✓ Quantized models saved to: {quantized_dir}")
        print("\nNext steps:")
        print("1. Test the quantized models in your app")
        print("2. Compare quality with original FP16 models")
        print("3. If satisfied, update your app to use quantized models")
    else:
        print("\n⚠️  No models were successfully quantized.")
        print("   Check the error messages above for details.")

if __name__ == "__main__":
    main()
