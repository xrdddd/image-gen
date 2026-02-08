# Implementation Notes for Core ML Stable Diffusion

## Current Status

The native module is set up to load your Core ML Stable Diffusion v1.5 models, but the **full Stable Diffusion pipeline is not yet implemented**. The current implementation:

✅ **Working:**
- Model loading (TextEncoder, UnetChunk1/Chunk2, VAEDecoder, SafetyChecker)
- Model path resolution from bundle
- Tokenizer file loading (vocab.json, merges.txt)
- Basic structure for the pipeline

⚠️ **Needs Implementation:**
- Full CLIP tokenization (currently simplified)
- TextEncoder inference with proper input/output handling
- Complete Unet diffusion loop with proper scheduler
- VAE decoder inference
- Proper model input/output structure handling

## Why Full Implementation is Complex

The Stable Diffusion pipeline requires:

1. **CLIP Tokenization**: Proper BPE (Byte Pair Encoding) using vocab.json and merges.txt
2. **TextEncoder**: Run with correct input shape and extract embeddings
3. **Diffusion Scheduler**: DDPM or DDIM scheduler for timestep management
4. **Unet Inference**: Multiple forward passes with proper input/output shapes
5. **VAE Decoder**: Convert latents (4x64x64) to image (3x512x512)

## Recommended Approach

### Option 1: Use Apple's Stable Diffusion Framework (Easiest)

Apple provides a Swift package for Stable Diffusion. Add it to your Xcode project:

1. **Add Swift Package**:
   - In Xcode: File → Add Packages
   - URL: `https://github.com/apple/ml-stable-diffusion`
   - Add `StableDiffusion` package

2. **Update Native Module**:
   ```swift
   import StableDiffusion
   
   let pipeline = StableDiffusionPipeline(
     resourceAt: modelURL,
     controlNet: nil,
     disableSafety: false,
     reduceMemory: true
   )
   
   let images = try pipeline.generateImages(
     prompt: prompt,
     imageCount: 1,
     stepCount: steps.intValue,
     seed: seed.intValue,
     guidanceScale: guidanceScale.floatValue
   )
   ```

### Option 2: Implement Full Pipeline Manually

This requires:
- Understanding Core ML model input/output structures
- Implementing CLIP tokenizer in Swift
- Implementing diffusion scheduler
- Properly chaining UnetChunk1 and UnetChunk2
- Handling all tensor operations

## Current Model Structure

Your models have this structure:
- **TextEncoder.mlmodelc**: Encodes text → embeddings
- **UnetChunk1.mlmodelc + UnetChunk2.mlmodelc**: Diffusion model (chunked)
- **VAEDecoder.mlmodelc**: Decodes latents → image
- **SafetyChecker.mlmodelc**: Content safety (optional)
- **vocab.json**: CLIP tokenizer vocabulary
- **merges.txt**: BPE merge rules

## Next Steps

1. **For Quick Implementation**: Use Apple's Stable Diffusion Swift package (Option 1)
2. **For Custom Control**: Implement full pipeline manually (Option 2)
3. **For Testing**: Current placeholder implementation works for testing model loading

## Model Input/Output Shapes

You'll need to inspect your models to get exact shapes:

```swift
// Inspect model inputs/outputs
if let model = textEncoder {
  print("TextEncoder inputs: \(model.modelDescription.inputDescriptionsByName)")
  print("TextEncoder outputs: \(model.modelDescription.outputDescriptionsByName)")
}
```

This will tell you the exact input/output names and shapes for your models.
