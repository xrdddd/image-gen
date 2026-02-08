# Testing Guide for Core ML Stable Diffusion

This guide will help you test the model loading and image generation pipeline.

## Prerequisites

1. **Development Build**: You must use a development build (not Expo Go)
   ```bash
   npx expo run:ios
   ```

2. **Models in Place**: Ensure your Core ML models are in `assets/models/`:
   - TextEncoder.mlmodelc
   - UnetChunk1.mlmodelc
   - UnetChunk2.mlmodelc
   - VAEDecoder.mlmodelc
   - SafetyChecker.mlmodelc (optional)
   - vocab.json
   - merges.txt

## Testing Steps

### 1. Test Model Loading

The app automatically tests model loading on startup. You should see:

- ✅ **Success**: "Models loaded: 5 components" (or similar)
- ❌ **Failure**: Error message indicating what went wrong

**Manual Test**:
```typescript
import { testModelLoading } from './services/localImageGenerationService';

const result = await testModelLoading();
console.log('Model loading result:', result);
```

### 2. Test Image Generation

1. Enter a prompt in the app
2. Tap "Generate Image"
3. Wait for generation (may take 10-30 seconds depending on device)

**Expected Behavior**:
- Models load successfully
- Image generation starts
- Progress indicator shows
- Image appears when complete

### 3. Check Console Logs

Look for these log messages:

```
📦 Loading models from: [path]
✅ TextEncoder loaded
✅ Unet loaded (chunked: Chunk1 + Chunk2)
✅ VAEDecoder loaded
✅ SafetyChecker loaded
✅ Vocab loaded (X tokens)
✅ Merges loaded (X merges)
🎉 All models loaded successfully!
🎨 Generating image for prompt: [your prompt]
✅ Tokenized: 77 tokens
✅ Text encoded: shape [1, 77, 768]
✅ Noise generated: 64x64
✅ Diffusion complete
✅ Image decoded
```

### 4. Troubleshooting

#### Models Not Loading

**Error**: "TextEncoder.mlmodelc not found"

**Solution**:
1. Verify models are in `assets/models/` directory
2. Check file names match exactly (case-sensitive)
3. Ensure models are included in app bundle (check Xcode project)

#### Native Module Not Found

**Error**: "Native module not available"

**Solution**:
1. Ensure you're using a development build: `npx expo run:ios`
2. Check that Swift files are linked in Xcode project
3. Verify `expo-dev-client` is installed

#### Generation Fails

**Error**: "Failed to generate image"

**Possible Causes**:
1. Models not fully loaded
2. Memory issues (try reducing image size)
3. Unet chunking not properly implemented (see IMPLEMENTATION_NOTES.md)

**Solution**:
- Check console logs for specific error
- Try reducing steps (e.g., 10 instead of 20)
- Try smaller image size (256x256 instead of 512x512)

## Performance Expectations

- **Model Loading**: 2-5 seconds (first time)
- **Image Generation**: 
  - iPhone 14 Pro / 15 Pro: 10-20 seconds
  - iPhone 13 / 14: 20-40 seconds
  - Older devices: 40-60 seconds

## Next Steps

If everything works:
1. ✅ Models load successfully
2. ✅ Images generate (even if placeholder)
3. ✅ No crashes

Then you can:
- Optimize the Unet chunking implementation
- Improve tokenization (full BPE)
- Add proper scheduler (DDPM/DDIM)
- Fine-tune VAE decoding

See `IMPLEMENTATION_NOTES.md` for details on completing the pipeline.
