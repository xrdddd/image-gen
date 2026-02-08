# Quantization Guide: Converting FP16 to INT8

Since Apple doesn't provide pre-quantized Core ML Stable Diffusion models, this guide shows you how to quantize your existing FP16 models to INT8 for smaller size and faster inference.

## Why Quantize?

- **Size Reduction**: ~50% smaller (4.2GB → ~2GB)
- **Speed Improvement**: ~20-30% faster inference
- **Memory Usage**: Lower peak memory consumption
- **Trade-off**: Slight quality reduction (usually negligible)

## Prerequisites

```bash
pip install coremltools>=7.0
pip install torch torchvision
pip install diffusers transformers
```

## Method 1: Using Core ML Tools (Simpler)

### Step 1: Load Your Model

```python
import coremltools as ct
from pathlib import Path

# Path to your .mlmodelc file
model_path = "assets/models/UnetChunk1.mlmodelc"

# Load the compiled model
# Note: .mlmodelc files are compiled packages
# You may need to work with the original .mlpackage if available
model = ct.models.MLModel(model_path)
```

### Step 2: Quantize

```python
# Quantize weights to int8
quantized_model = ct.models.neural_network.quantization_utils.quantize_weights(
    model,
    nbits=8,  # 8-bit quantization
    quantization_mode="linear"  # or "kmeans" for better quality
)

# Save quantized model
quantized_model.save("UnetChunk1_quantized.mlmodelc")
```

### Limitations

- `.mlmodelc` files are compiled packages, which makes quantization more complex
- You may need the original `.mlpackage` or `.mlmodel` files
- Some models may not quantize well

## Method 2: Re-convert with Quantization (Recommended)

This method converts from the original PyTorch model with quantization built-in.

### Step 1: Clone Apple's Repository

```bash
git clone https://github.com/apple/ml-stable-diffusion.git
cd ml-stable-diffusion
pip install -e .
```

### Step 2: Convert with Quantization

```python
from python_coreml_stable_diffusion.pipeline import get_coreml_pipe
import coremltools as ct

# Convert with quantization
coreml_pipe = get_coreml_pipe(
    pytorch_pipe_or_path="runwayml/stable-diffusion-v1-5",
    output_path="./quantized_models",
    compute_unit=ct.ComputeUnit.ALL,
    # Quantization settings
    quantize="palettize",  # or "linear" for linear quantization
    bits=8,  # 8-bit quantization
    chunk_size=2  # For chunked Unet
)

# This will create quantized versions of all components
```

### Step 3: Use Apple's Conversion Script

```bash
python -m python_coreml_stable_diffusion.pipeline \
  --model-version runwayml/stable-diffusion-v1-5 \
  --convert-unet \
  --convert-text-encoder \
  --convert-vae-decoder \
  --quantize-nbits-per-weight 8 \
  --chunk-unet \
  -o ./quantized_models
```

## Method 3: Using Hugging Face Diffusers (Alternative)

If you have access to the original PyTorch model:

```python
from diffusers import StableDiffusionPipeline
import coremltools as ct
import torch

# Load original model
pipe = StableDiffusionPipeline.from_pretrained(
    "runwayml/stable-diffusion-v1-5",
    torch_dtype=torch.float16
)

# Convert to Core ML with quantization
# This is a simplified example - actual conversion is more complex
for component in ["text_encoder", "unet", "vae"]:
    model = getattr(pipe, component)
    
    # Convert to Core ML
    coreml_model = ct.convert(
        model,
        inputs=[...],  # Define inputs
        outputs=[...],  # Define outputs
        compute_units=ct.ComputeUnit.ALL
    )
    
    # Quantize
    quantized = ct.models.neural_network.quantization_utils.quantize_weights(
        coreml_model,
        nbits=8
    )
    
    # Save
    quantized.save(f"{component}_quantized.mlmodelc")
```

## Important Notes

### 1. Model Compatibility

- Quantized models may have slightly different input/output shapes
- Test thoroughly after quantization
- Some operations may not quantize well

### 2. Quality vs Size Trade-off

- **INT8**: Smallest, fastest, slight quality loss
- **FP16**: Good balance (what you have now)
- **FP32**: Best quality, largest, slowest

### 3. Chunked Models

If your Unet is chunked (UnetChunk1 + UnetChunk2):
- Quantize each chunk separately
- Ensure both chunks use the same quantization settings
- Test that chunks work together correctly

### 4. Performance Testing

After quantization, test:
- Image quality (compare with original)
- Generation speed
- Memory usage
- Device compatibility

## Recommended Approach

**For your current setup**, I recommend:

1. **Keep your FP16 models** - They're already a good balance
2. **Optimize the pipeline** - Better performance gains from code optimization
3. **Consider quantization later** - Only if app size is a concern

The FP16 models you have will work well on modern iPhones (iPhone 12 and newer). Quantization is more beneficial for:
- Older devices
- Smaller app size requirements
- Faster generation at the cost of quality

## Resources

- [Apple ML Stable Diffusion](https://github.com/apple/ml-stable-diffusion)
- [Core ML Tools Documentation](https://coremltools.readme.io/)
- [Quantization Best Practices](https://coremltools.readme.io/docs/quantization)

## Quick Reference

```python
# Quick quantization script
import coremltools as ct

def quantize_model(input_path, output_path, bits=8):
    """Quantize a Core ML model"""
    model = ct.models.MLModel(input_path)
    quantized = ct.models.neural_network.quantization_utils.quantize_weights(
        model, nbits=bits
    )
    quantized.save(output_path)
    print(f"Quantized model saved to {output_path}")

# Usage
quantize_model(
    "assets/models/UnetChunk1.mlmodelc",
    "assets/models/UnetChunk1_quantized.mlmodelc"
)
```
