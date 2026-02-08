# Your Model Information

## Model Type: FP16 (Half Precision) - NOT Quantized

Based on the metadata analysis:

- **Precision**: Float16 (FP16) - Half precision
- **Quantization**: None (not int8)
- **Total Size**: ~4.2 GB
- **Structure**: Multi-component (chunked for memory efficiency)

## Model Components

Your model consists of these files:

1. **TextEncoder.mlmodelc** (235 MB)
   - Encodes text prompts into embeddings
   - Required for generation

2. **Unet.mlmodelc** (1.6 GB) OR **UnetChunk1.mlmodelc** (847 MB) + **UnetChunk2.mlmodelc** (794 MB)
   - Main diffusion model
   - Your model uses **chunked version** (UnetChunk1 + UnetChunk2)
   - This is a memory optimization technique
   - Required for generation

3. **VAEDecoder.mlmodelc** (95 MB)
   - Decodes latent representations to images
   - Required for generation

4. **VAEEncoder.mlmodelc** (65 MB)
   - Encodes images to latent space
   - Optional (used for img2img)

5. **SafetyChecker.mlmodelc** (580 MB)
   - Content safety filter
   - Optional but recommended

6. **vocab.json** and **merges.txt**
   - CLIP tokenizer vocabulary files
   - Required for text encoding

## Why Multiple Files?

Stable Diffusion is split into components for:
- **Memory efficiency**: Load only what you need
- **Modularity**: Update components independently
- **Mobile optimization**: Chunked Unet reduces peak memory usage

The **UnetChunk1 + UnetChunk2** structure means the UNet model is split into two parts that are loaded and executed sequentially, reducing memory pressure on mobile devices.

## Performance Characteristics

- **FP16 Precision**: Good balance between quality and size
- **Not Quantized**: Higher quality than int8, but larger size
- **Chunked Unet**: Better memory usage, slightly slower than single file
- **Expected Speed**: 
  - iPhone 14 Pro/15 Pro: 10-20 seconds per 512x512 image
  - iPhone 13/14: 15-30 seconds
  - Older devices: 30-60 seconds

## To Get a Smaller/Quantized Model

If you want a smaller, faster model (int8 quantized):

**Note**: Apple doesn't provide pre-quantized models on Hugging Face. You need to quantize them yourself.

1. **Convert your existing FP16 model to int8** (Recommended):
   ```python
   import coremltools as ct
   
   # Load model (note: .mlmodelc files are compiled packages)
   # You may need the original .mlpackage for quantization
   model = ct.models.MLModel("UnetChunk1.mlmodelc")
   
   # Quantize to int8
   quantized = ct.models.neural_network.quantization_utils.quantize_weights(
       model, nbits=8
   )
   
   # Save
   quantized.save("UnetChunk1_quantized.mlmodelc")
   ```
   
   **Note**: Quantizing `.mlmodelc` files directly can be complex. See `QUANTIZATION_GUIDE.md` for detailed instructions.

## Current Setup Status

✅ **Models are properly structured**
✅ **All required components present**
✅ **Native code updated to handle multi-file structure**
✅ **Ready for integration**

## Next Steps

1. The native module (`ImageGenerationModule.ios.swift`) has been updated to load all components
2. You need to implement the full Stable Diffusion pipeline:
   - Text tokenization (using vocab.json and merges.txt)
   - Text encoding (TextEncoder)
   - Diffusion loop (UnetChunk1 + UnetChunk2)
   - Image decoding (VAEDecoder)
   - Safety checking (SafetyChecker)

3. See `NATIVE_SETUP.md` for implementation details
