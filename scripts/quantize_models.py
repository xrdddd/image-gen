#!/usr/bin/env python3
"""
Quantize FP16 Core ML Stable Diffusion models to INT8
This script converts all model components from FP16 to INT8 for smaller size and faster inference.
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
    print("\nOr use a virtual environment:")
    print("  python3 -m venv venv")
    print("  source venv/bin/activate  # On macOS/Linux")
    print('  pip install "coremltools>=7.0"')
    print("\nOr install from requirements.txt:")
    print("  pip install -r requirements.txt")
    print("\nNote: On macOS, you may need to use:")
    print('  pip install --user "coremltools>=7.0"')
    print("  or")
    print('  pip install --break-system-packages "coremltools>=7.0"')
    print("\n⚠️  IMPORTANT: Use quotes around the package name with version!")
    print("   Without quotes, zsh will interpret >= as a redirection operator.")
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

def quantize_model(input_path, output_path, model_name):
    """
    Quantize a Core ML model from FP16 to INT8
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
        
        # Load model
        print(f"Loading model from: {input_path}")
        
        # Try to load as MLModel
        # Note: .mlmodelc files are compiled packages, which cannot be quantized directly
        try:
            model = MLModel(input_path)
            print("✓ Model loaded successfully")
        except Exception as e:
            print(f"⚠️  Error loading as MLModel: {e}")
            
            # .mlmodelc files are compiled packages - cannot be quantized
            if os.path.isdir(input_path) and input_path.endswith('.mlmodelc'):
                print(f"\n❌ Cannot quantize .mlmodelc files (compiled packages)")
                print(f"   These are runtime-optimized binaries, not source models.")
                print(f"\n   Solutions:")
                print(f"   1. Use FP16 models as-is (recommended - they work well)")
                print(f"   2. Get original .mlpackage files from Hugging Face")
                print(f"   3. Re-convert from PyTorch with quantization")
                print(f"\n   See QUANTIZATION_LIMITATION.md for details.")
                return False
            else:
                print(f"❌ Failed to load model: {e}")
                return False
        
        # Quantize to INT8
        print("Quantizing to INT8...")
        try:
            quantized_model = ct.models.neural_network.quantization_utils.quantize_weights(
                model,
                nbits=8,
                quantization_mode="linear"  # or "kmeans" for potentially better quality
            )
            print("✓ Quantization successful")
        except Exception as e:
            print(f"❌ Quantization failed: {e}")
            print("   This may happen if:")
            print("   - The model is already compiled (.mlmodelc)")
            print("   - The model structure doesn't support quantization")
            print("   - You need the original .mlpackage file")
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
    print("Core ML Model Quantization Tool")
    print("Converting FP16 models to INT8")
    print("=" * 60)
    
    # Paths
    base_dir = Path(__file__).parent.parent
    models_dir = base_dir / "assets" / "models"
    quantized_dir = base_dir / "assets" / "models_quantized"
    
    if not models_dir.exists():
        print(f"❌ Models directory not found: {models_dir}")
        print("   Please ensure your models are in assets/models/")
        sys.exit(1)
    
    # Create output directory
    quantized_dir.mkdir(exist_ok=True, parents=True)
    
    # Models to quantize (in order of importance)
    models_to_quantize = [
        {
            "input": "UnetChunk1.mlmodelc",
            "output": "UnetChunk1_quantized.mlmodelc",
            "name": "Unet Chunk 1",
            "required": True
        },
        {
            "input": "UnetChunk2.mlmodelc",
            "output": "UnetChunk2_quantized.mlmodelc",
            "name": "Unet Chunk 2",
            "required": True
        },
        {
            "input": "Unet.mlmodelc",
            "output": "Unet_quantized.mlmodelc",
            "name": "Unet (Full)",
            "required": False  # Only if you have full Unet instead of chunks
        },
        {
            "input": "TextEncoder.mlmodelc",
            "output": "TextEncoder_quantized.mlmodelc",
            "name": "Text Encoder",
            "required": True
        },
        {
            "input": "VAEDecoder.mlmodelc",
            "output": "VAEDecoder_quantized.mlmodelc",
            "name": "VAE Decoder",
            "required": True
        },
        {
            "input": "VAEEncoder.mlmodelc",
            "output": "VAEEncoder_quantized.mlmodelc",
            "name": "VAE Encoder",
            "required": False
        },
        {
            "input": "SafetyChecker.mlmodelc",
            "output": "SafetyChecker_quantized.mlmodelc",
            "name": "Safety Checker",
            "required": False
        }
    ]
    
    print(f"\nModels directory: {models_dir}")
    print(f"Output directory: {quantized_dir}")
    print(f"\nFound {len(models_to_quantize)} models to process\n")
    
    # Track results
    results = {
        "success": [],
        "failed": [],
        "skipped": []
    }
    
    total_original_size = 0
    total_quantized_size = 0
    
    # Process each model
    for model_info in models_to_quantize:
        input_path = models_dir / model_info["input"]
        output_path = quantized_dir / model_info["output"]
        
        if not input_path.exists():
            if model_info["required"]:
                print(f"⚠️  Required model not found: {model_info['input']}")
                results["failed"].append(model_info["name"])
            else:
                print(f"⊘ Skipping optional model: {model_info['input']}")
                results["skipped"].append(model_info["name"])
            continue
        
        # Get original size
        original_size = get_model_size_mb(str(input_path))
        total_original_size += original_size
        
        # Quantize
        success = quantize_model(
            str(input_path),
            str(output_path),
            model_info["name"]
        )
        
        if success:
            results["success"].append(model_info["name"])
            new_size = get_model_size_mb(str(output_path))
            total_quantized_size += new_size
        else:
            results["failed"].append(model_info["name"])
            # If quantization failed, copy original
            print(f"   Copying original model as fallback...")
            if os.path.isdir(str(input_path)):
                shutil.copytree(str(input_path), str(output_path), dirs_exist_ok=True)
            else:
                shutil.copy2(str(input_path), str(output_path))
            total_quantized_size += original_size
    
    # Copy tokenizer files
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
        else:
            print(f"⚠️  {token_file} not found")
    
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
    
    if results["skipped"]:
        print(f"\n⊘ Skipped (optional): {len(results['skipped'])}")
        for name in results["skipped"]:
            print(f"   - {name}")
    
    total_reduction = ((total_original_size - total_quantized_size) / total_original_size) * 100 if total_original_size > 0 else 0
    
    print(f"\n{'='*60}")
    print(f"Total original size: {total_original_size:.2f} MB")
    print(f"Total quantized size: {total_quantized_size:.2f} MB")
    print(f"Total reduction: {total_reduction:.1f}% ({total_original_size - total_quantized_size:.2f} MB saved)")
    print(f"{'='*60}")
    
    print(f"\n✓ Quantized models saved to: {quantized_dir}")
    print("\nNext steps:")
    print("1. Test the quantized models in your app")
    print("2. Compare quality with original FP16 models")
    print("3. If satisfied, replace assets/models/ with assets/models_quantized/")
    print("4. Update your app to use the quantized models")
    
    if results["failed"]:
        print("\n⚠️  Note: Some models failed to quantize.")
        print("   This is common with .mlmodelc files (compiled packages).")
        print("   You may need the original .mlpackage files for full quantization.")
        print("   See QUANTIZATION_GUIDE.md for alternative methods.")

if __name__ == "__main__":
    main()
