# Using Apple's Stable Diffusion Framework

Apple provides an official Swift package for Stable Diffusion that handles all the complexity of the diffusion pipeline, scheduler, and VAE decoding.

## Setup Steps

1. **Add Swift Package Dependency in Xcode:**
   - Open `ios/ImageGenerate.xcworkspace` in Xcode
   - Go to File → Add Package Dependencies
   - Enter: `https://github.com/apple/ml-stable-diffusion`
   - Select version: `0.3.0` or latest
   - Add to target: `ImageGenerate`

2. **Update ImageGenerationModule.swift:**
   - Replace manual implementation with Apple's `StableDiffusionPipeline`
   - This handles all the complexity automatically

3. **Model Path:**
   - Apple's framework expects models in a specific structure
   - Models should be in: `{modelPath}/compiled/{modelName}.mlmodelc`
   - Or use the framework's model loading utilities

## Benefits

- ✅ Proper scheduler implementation
- ✅ Correct classifier-free guidance
- ✅ Optimized for Apple Silicon
- ✅ Handles all edge cases
- ✅ Better error handling
- ✅ Production-ready code
