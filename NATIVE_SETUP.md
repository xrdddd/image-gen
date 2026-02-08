# Native Module Setup Guide

This app uses native modules for on-device image generation with optimized performance, especially on iOS using Core ML.

## Prerequisites

1. **Development Build Required**: This app requires a development build (not Expo Go) because it uses native modules.

2. **iOS Development**: 
   - Xcode 14+ installed
   - iOS 13+ deployment target
   - Core ML framework support

3. **Android Development** (optional):
   - Android Studio installed
   - Android SDK with API level 21+

## Setup Steps

### 1. Install Dependencies

```bash
npm install
```

### 2. Create Development Build

Since we're using native modules, you need to create a development build:

```bash
# For iOS
npx eas-cli build --profile development --platform ios

# For Android
npx eas-cli build --profile development --platform android
```

Or build locally:

```bash
# iOS (requires Xcode)
npx expo run:ios

# Android (requires Android Studio)
npx expo run:android
```

### 3. Add Core ML Model (iOS)

1. **Obtain a Stable Diffusion Core ML Model**:
   - Convert a Stable Diffusion model to Core ML format (.mlmodel)
   - You can use tools like `coremltools` or `apple/ml-stable-diffusion`
   - Recommended: Use Apple's optimized Stable Diffusion Core ML models

2. **Add Model to Project**:
   - Place your `.mlmodel` file in `assets/models/stable_diffusion.mlmodel`
   - The model will be bundled with the app

3. **Update Model Loading** (if needed):
   - Modify `services/localImageGenerationService.ts` if your model has a different name or location

### 4. Native Module Integration

The native modules are already set up:

- **iOS**: `services/native/ImageGenerationModule.ios.swift`
- **Bridge**: `services/native/ImageGenerationModule.m`

These files need to be linked to your Xcode project:

1. Open the iOS project: `npx expo run:ios` (this opens Xcode)
2. In Xcode, add the Swift files to your project:
   - Right-click on your project → "Add Files to [Project]"
   - Select `services/native/ImageGenerationModule.ios.swift`
   - Select `services/native/ImageGenerationModule.m`
   - Make sure "Copy items if needed" is checked
   - Add to target: [Your App Target]

3. Configure Swift/Objective-C bridging:
   - In Xcode, go to Build Settings
   - Search for "Objective-C Bridging Header"
   - Add: `$(SRCROOT)/[YourApp]/Bridging-Header.h` (create if needed)

### 5. Update Native Module Implementation

The current implementation in `ImageGenerationModule.ios.swift` is a placeholder. For production, you need to:

1. **Implement Full Stable Diffusion Pipeline**:
   - Text encoder (CLIP)
   - UNet diffusion model
   - VAE decoder
   - Scheduler (DDPM/DDIM)

2. **Use Apple's ML Stable Diffusion** (Recommended):
   ```swift
   import StableDiffusion
   
   // Use Apple's optimized implementation
   let pipeline = StableDiffusionPipeline()
   ```

3. **Optimize for Performance**:
   - Use Metal Performance Shaders for GPU acceleration
   - Implement model quantization (int8)
   - Cache model in memory
   - Use background queues for inference

### 6. Model Recommendations

For best iOS performance:

- **Apple's Stable Diffusion Core ML**: 
  - Download from: https://github.com/apple/ml-stable-diffusion
  - Optimized for Apple Silicon and Neural Engine
  - Supports quantization for smaller models

- **Model Size Considerations**:
  - Full precision: ~6GB (best quality)
  - Half precision: ~3GB (good quality)
  - Quantized (int8): ~1.5GB (acceptable quality, fastest)

### 7. Testing

1. **Build and Run**:
   ```bash
   npx expo run:ios
   ```

2. **Check Native Module**:
   - The app should show "🚀 On-Device Generation" badge if native module is loaded
   - If not, check console for errors

3. **Test Image Generation**:
   - Enter a prompt
   - Tap "Generate Image"
   - First generation may be slower (model loading)
   - Subsequent generations should be faster

## Performance Optimization

### iOS Optimizations

1. **Use Neural Engine**:
   - Core ML automatically uses Neural Engine on A12+ chips
   - Ensure model is quantized for Neural Engine compatibility

2. **Metal GPU Acceleration**:
   - Core ML uses Metal for GPU inference
   - No additional configuration needed

3. **Memory Management**:
   - Load model once and keep in memory
   - Use autoreleasepool for large operations
   - Monitor memory usage

4. **Background Processing**:
   - Run inference on background queue
   - Update UI on main queue

### Expected Performance

- **iPhone 14 Pro / 15 Pro**: 5-15 seconds per image (512x512)
- **iPhone 13 / 14**: 10-25 seconds per image
- **iPhone 12 / older**: 20-40 seconds per image

Performance depends on:
- Model size and quantization
- Image resolution
- Number of inference steps
- Device capabilities

## Troubleshooting

### Native Module Not Found

- Ensure you're using a development build (not Expo Go)
- Check that Swift files are added to Xcode project
- Verify bridging header is configured
- Rebuild the app: `npx expo run:ios --clean`

### Model Loading Fails

- Verify model file is in `assets/models/`
- Check model format is `.mlmodel` (Core ML)
- Ensure model is compatible with iOS version
- Check file size (may need to download on first use)

### Slow Performance

- Use quantized model (int8)
- Reduce image resolution
- Reduce number of steps
- Ensure using Neural Engine (check device compatibility)

### Build Errors

- Clean build folder: `npx expo run:ios --clean`
- Update CocoaPods: `cd ios && pod install`
- Check Xcode version compatibility
- Verify Swift version in project settings

## Production Considerations

1. **Model Distribution**:
   - Bundle model with app (increases app size)
   - Or download on first launch (requires network)

2. **App Size**:
   - Quantized models are smaller
   - Consider downloading models post-install

3. **Battery Usage**:
   - Image generation is computationally intensive
   - Warn users about battery usage
   - Consider offering lower quality/faster options

4. **Privacy**:
   - All processing happens on-device
   - No data sent to servers
   - Highlight this as a feature

## Resources

- [Apple ML Stable Diffusion](https://github.com/apple/ml-stable-diffusion)
- [Core ML Documentation](https://developer.apple.com/documentation/coreml)
- [Expo Development Builds](https://docs.expo.dev/development/introduction/)
- [React Native Native Modules](https://reactnative.dev/docs/native-modules-intro)
