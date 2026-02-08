# Image Generate App

A cross-platform mobile application for generating images from text prompts using AI. Built with React Native and Expo, ready for deployment to both Apple App Store and Google Play Store.

## Features

- 🎨 Generate images from text prompts using on-device AI
- 📱 Native iOS and Android support
- 🚀 **On-Device Inference** - No API keys needed, all processing happens locally
- ⚡ Optimized for iOS using Core ML with Neural Engine acceleration
- 🎯 Modern, intuitive UI
- 🔒 Privacy-first - Your prompts never leave your device
- 💾 Model caching for faster subsequent generations

## Prerequisites

- Node.js (v18 or higher)
- npm or yarn
- Expo CLI (`npm install -g expo-cli`)
- EAS CLI for building (`npm install -g eas-cli`)
- Apple Developer account (for iOS deployment)
- Google Play Console account (for Android deployment)

## Setup

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Setup for Local Generation:**
   
   This app uses **on-device image generation** - no API keys needed!
   
   **Important**: This app requires a **development build** (not Expo Go) because it uses native modules.
   
   See [NATIVE_SETUP.md](./NATIVE_SETUP.md) for detailed setup instructions.
   
   Quick start:
   ```bash
   # Create a development build
   npx eas-cli build --profile development --platform ios
   # or build locally
   npx expo run:ios
   ```

3. **Start the development server:**
   ```bash
   npm start
   ```

4. **Run on device/simulator:**
   - Press `i` for iOS simulator
   - Press `a` for Android emulator
   - Scan QR code with Expo Go app on your physical device

## Image Generation

This app uses **on-device image generation** powered by:
- **iOS**: Core ML with Neural Engine acceleration for optimal performance
- **Android**: ONNX Runtime (coming soon)

### Model Requirements

You need to add a Stable Diffusion Core ML model to `assets/models/stable_diffusion.mlmodel`.

**Recommended**: Use Apple's optimized Stable Diffusion Core ML models from:
https://github.com/apple/ml-stable-diffusion

See [assets/models/README.md](./assets/models/README.md) for detailed instructions.

### Performance

- **iPhone 14 Pro / 15 Pro**: 5-15 seconds per 512x512 image
- **iPhone 13 / 14**: 10-25 seconds per image
- **Older devices**: 20-40 seconds per image

Performance depends on model size, quantization, and device capabilities.

## Building for Production

### Using EAS Build (Recommended)

1. **Install EAS CLI (if not already installed):**
   
   The project scripts use `npx eas-cli` which will automatically install EAS CLI when needed. You can also:
   
   ```bash
   # Option 1: Install locally (recommended)
   npm install
   
   # Option 2: Install globally
   npm install -g eas-cli
   ```

2. **Login to Expo:**
   ```bash
   npx eas-cli login
   # or if installed globally: eas login
   ```

3. **Configure your project:**
   ```bash
   npm run eas:configure
   # or: npx eas-cli build:configure
   ```

4. **Build for iOS:**
   ```bash
   eas build --platform ios
   ```

5. **Build for Android:**
   ```bash
   eas build --platform android
   ```

### iOS App Store Deployment

1. **Update app.json:**
   - Set your `bundleIdentifier` in `app.json`
   - Update app name, version, and other metadata

2. **Build and submit:**
   ```bash
   eas build --platform ios --profile production
   eas submit --platform ios
   ```

3. **Or build locally:**
   ```bash
   eas build --platform ios --local
   ```

### Android Play Store Deployment

1. **Update app.json:**
   - Set your `package` name in `app.json`
   - Update app name, version, and other metadata

2. **Create a keystore** (if not using EAS managed):
   ```bash
   keytool -genkeypair -v -storetype PKCS12 -keystore my-release-key.keystore -alias my-key-alias -keyalg RSA -keysize 2048 -validity 10000
   ```

3. **Build and submit:**
   ```bash
   eas build --platform android --profile production
   eas submit --platform android
   ```

## Project Structure

```
image-generate-2/
├── App.tsx                 # Main application component
├── app.json               # Expo configuration
├── package.json           # Dependencies
├── tsconfig.json          # TypeScript configuration
├── eas.json              # EAS build configuration
├── services/
│   └── imageGenerationService.ts  # Image generation API service
└── assets/               # App icons, splash screens, etc.
```

## Configuration

### App Metadata

Edit `app.json` to customize:
- App name and slug
- Bundle identifier (iOS) and package name (Android)
- Icons and splash screens
- Permissions
- Version numbers

### API Configuration

The image generation service is configured in `services/imageGenerationService.ts`. You can:
- Switch between different AI providers
- Adjust image size and quality settings
- Add custom generation parameters

## Assets Required

You'll need to add the following assets to the `assets/` directory:

- `icon.png` (1024x1024) - App icon
- `splash.png` (1242x2436) - Splash screen
- `adaptive-icon.png` (1024x1024) - Android adaptive icon
- `favicon.png` (48x48) - Web favicon

You can generate these using tools like:
- [App Icon Generator](https://www.appicon.co/)
- [Expo Asset Generator](https://docs.expo.dev/guides/app-icons/)

## Troubleshooting

### Native Module Not Found
- Ensure you're using a development build (not Expo Go)
- Run: `npx expo run:ios` to create a local development build
- Check that native Swift files are properly linked in Xcode

### Model Loading Issues
- Verify model file exists in `assets/models/stable_diffusion.mlmodel`
- Check model format is Core ML (.mlmodel)
- Ensure model is compatible with your iOS version
- See [NATIVE_SETUP.md](./NATIVE_SETUP.md) for detailed troubleshooting

### Build Issues
- Make sure you're logged into EAS: `eas login`
- Check that your `eas.json` is properly configured
- For iOS: Ensure your Apple Developer account is set up
- For Android: Verify your Google Play Console account is active

### Development Issues
- Clear cache: `expo start -c`
- Reinstall dependencies: `rm -rf node_modules && npm install`
- Check Expo SDK version compatibility

## License

This project is private and proprietary.

## Support

For issues related to:
- **Expo**: Check [Expo Documentation](https://docs.expo.dev/)
- **React Native**: Check [React Native Documentation](https://reactnative.dev/)
- **EAS Build**: Check [EAS Build Documentation](https://docs.expo.dev/build/introduction/)
# image-gen
