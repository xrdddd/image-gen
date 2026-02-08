# How to Get Stable Diffusion Core ML Model

This guide walks you through obtaining and setting up a Stable Diffusion Core ML model from Apple's repository for on-device image generation.

## Option 1: Download Pre-converted Models (Easiest)

### Step 1: Visit Apple's Repository

Go to Apple's Stable Diffusion repository:
**https://github.com/apple/ml-stable-diffusion**

### Step 2: Check Available Models

Apple provides several pre-converted Core ML models. Look for:
- **Stable Diffusion v1.4** - Original model
- **Stable Diffusion v1.5** - Improved version
- **Stable Diffusion v2.x** - Latest versions

### Step 3: Download Model Files

You can download models from:
1. **Hugging Face Hub** (Recommended):
   - Visit: https://huggingface.co/apple
   - Look for models like `coreml-stable-diffusion-v1-4` or `coreml-stable-diffusion-v1-5`
   - Download the `.mlpackage` or `.mlmodelc` files

2. **Direct from Apple's Releases**:
   - Check the Releases section of the GitHub repo
   - Download pre-built model packages

### Step 4: Convert to Single .mlmodel File (if needed)

If you downloaded a `.mlpackage` (which is a package containing multiple models), you may need to extract or convert it:

```python
import coremltools as ct

# Load the mlpackage
model = ct.models.MLModel("path/to/model.mlpackage")

# If you need a single file, you can save it
# Note: Some models are split into multiple files (text encoder, unet, vae)
model.save("stable_diffusion.mlmodel")
```

## Option 2: Convert Your Own Model (Advanced)

### Prerequisites

```bash
# Install Python dependencies
pip install coremltools
pip install torch torchvision
pip install diffusers transformers
pip install huggingface-hub
```

### Step 1: Clone Apple's Repository

```bash
git clone https://github.com/apple/ml-stable-diffusion.git
cd ml-stable-diffusion
```

### Step 2: Install Dependencies

```bash
pip install -e .
```

### Step 3: Convert Stable Diffusion to Core ML

Use Apple's conversion script:

```python
# convert.py
from coremltools.models import MLModel
from diffusers import StableDiffusionPipeline
import coremltools as ct

# Load the original Stable Diffusion model
pipe = StableDiffusionPipeline.from_pretrained(
    "runwayml/stable-diffusion-v1-5",
    torch_dtype=torch.float16
)

# Convert to Core ML
# This creates separate models for text encoder, unet, and vae
coreml_pipe = ct.convert(
    pipe,
    inputs=[
        ct.TensorType(name="text_embeddings", shape=(1, 77, 768)),
        ct.TensorType(name="timestep", shape=(1,)),
        ct.TensorType(name="latent_sample", shape=(1, 4, 64, 64)),
    ],
    outputs=[
        ct.TensorType(name="noise_pred"),
    ],
    compute_units=ct.ComputeUnit.ALL,  # Use Neural Engine + GPU + CPU
)

# Save the model
coreml_pipe.save("stable_diffusion.mlmodel")
```

Or use Apple's provided conversion script:

```bash
python -m python_coreml_stable_diffusion.pipeline --convert-unet --convert-text-encoder --convert-vae-decoder --convert-safety-checker -o ./models
```

### Step 4: Quantize for Mobile (Recommended)

For better performance and smaller size:

```python
import coremltools as ct

# Load the model
model = ct.models.MLModel("stable_diffusion.mlmodel")

# Quantize to int8
quantized_model = ct.models.neural_network.quantization_utils.quantize_weights(
    model, 
    nbits=8
)

# Save quantized model
quantized_model.save("stable_diffusion_quantized.mlmodel")
```

## Option 3: Use Hugging Face Models (Simplest)

### Step 1: Install Hugging Face CLI

```bash
pip install huggingface-hub
```

### Step 2: Download Pre-converted Model

```bash
# Login to Hugging Face (optional, for gated models)
huggingface-cli login

# Download Apple's Core ML Stable Diffusion model
huggingface-cli download apple/coreml-stable-diffusion-v1-4 --local-dir ./models
```

Or use Python:

```python
from huggingface_hub import snapshot_download

# Download the model
model_path = snapshot_download(
    repo_id="apple/coreml-stable-diffusion-v1-4",
    local_dir="./models"
)

print(f"Model downloaded to: {model_path}")
```

### Step 3: Extract Model Files

The downloaded model will contain:
- `TextEncoder.mlmodelc` - Text encoder
- `Unet.mlmodelc` - Main diffusion model
- `VAEDecoder.mlmodelc` - Image decoder
- `safety_checker.mlmodelc` - Safety checker (optional)

For a simpler integration, you may want to use a combined model or handle each component separately.

## Recommended Model Sizes

| Model Type | Size | Quality | Speed | Use Case |
|------------|------|---------|-------|----------|
| Full Precision (FP32) | ~6GB | Best | Slowest | High-end devices |
| Half Precision (FP16) | ~3GB | Very Good | Fast | Recommended |
| Quantized (INT8) | ~1.5GB | Good | Fastest | Mobile devices |

**For iOS mobile apps, we recommend INT8 quantized models** for:
- Smaller app size
- Faster inference
- Lower memory usage
- Better battery life

## Setting Up the Model in Your App

### Step 1: Place Model in Assets

Once you have your `.mlmodel` or `.mlmodelc` file:

```bash
# Copy to your assets directory
cp stable_diffusion.mlmodel assets/models/stable_diffusion.mlmodel
```

### Step 2: Update Model Loading (if needed)

If your model has a different name or structure, update `services/localImageGenerationService.ts`:

```typescript
const modelName = `your_model_name.mlmodel`; // Change this
```

### Step 3: Handle Multi-Component Models

If you downloaded separate models (TextEncoder, Unet, VAE), you'll need to:

1. Update the native Swift module to load all components
2. Modify the inference pipeline to use all components
3. See `NATIVE_SETUP.md` for implementation details

## Quick Start: Using Hugging Face (Recommended)

The easiest way to get started:

```bash
# 1. Install dependencies
pip install huggingface-hub

# 2. Download model
python3 << EOF
from huggingface_hub import snapshot_download
import shutil
import os

# Download model
print("Downloading Core ML Stable Diffusion model...")
model_path = snapshot_download(
    repo_id="apple/coreml-stable-diffusion-v1-4",
    local_dir="./downloaded_models"
)

# Find the main model file
# Note: Apple's models are in .mlmodelc format (packages)
# You may need to extract or use the package directly

print(f"Model downloaded to: {model_path}")
print("\nNext steps:")
print("1. Check the downloaded_models directory")
print("2. Copy the appropriate .mlmodelc or .mlmodel file to assets/models/")
print("3. Update the model loading code if needed")
EOF

# 3. Copy to assets (adjust path based on downloaded structure)
# mkdir -p assets/models
# cp downloaded_models/*.mlmodel assets/models/stable_diffusion.mlmodel
```

## Model Structure for Your App

Your app expects a single `.mlmodel` file at:
```
assets/models/stable_diffusion.mlmodel
```

If you have separate components, you have two options:

### Option A: Use Combined Model
Combine all components into one model (more complex setup)

### Option B: Update Native Module
Modify `ImageGenerationModule.ios.swift` to load and use separate models:
- TextEncoder.mlmodelc
- Unet.mlmodelc  
- VAEDecoder.mlmodelc

## Verification

After placing the model, verify it's accessible:

```typescript
// Test in your app
import { preloadModel } from './services/localImageGenerationService';

const loaded = await preloadModel();
console.log('Model loaded:', loaded);
```

## Troubleshooting

### Model Not Found
- Verify file is in `assets/models/stable_diffusion.mlmodel`
- Check file extension is `.mlmodel` or `.mlmodelc`
- Ensure file is included in app bundle (check Xcode project)

### Model Format Issues
- `.mlmodelc` files are packages - may need special handling
- Try converting to `.mlmodel` if having issues
- Check model compatibility with your iOS version

### Size Issues
- Use quantized models for smaller size
- Consider downloading model on first launch instead of bundling
- Use model compression tools

## Resources

- **Apple's Repository**: https://github.com/apple/ml-stable-diffusion
- **Hugging Face Models**: https://huggingface.co/apple
- **Core ML Tools Docs**: https://coremltools.readme.io/
- **Stable Diffusion**: https://github.com/Stability-AI/stablediffusion

## Next Steps

After obtaining your model:
1. Place it in `assets/models/stable_diffusion.mlmodel`
2. Build your development build: `npx expo run:ios`
3. Test model loading in the app
4. See `NATIVE_SETUP.md` for native module configuration
