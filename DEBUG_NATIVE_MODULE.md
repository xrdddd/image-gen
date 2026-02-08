# Debug Native Module Not Available

## Check List

### 1. Verify Module is Registered

The module name must match exactly:
- **Swift class**: `@objc(ImageGenerationModule)` 
- **RCT_EXTERN_MODULE**: `RCT_EXTERN_MODULE(ImageGenerationModule, NSObject)`
- **TypeScript**: `const { ImageGenerationModule } = NativeModules;`

### 2. Check Build Errors

In Xcode:
1. Open `ios/*.xcworkspace`
2. Build (⌘B)
3. Check for errors in:
   - Swift compilation errors
   - Linking errors
   - Missing frameworks

### 3. Verify Module is Compiled

In Xcode:
1. Project → Target "ImageGenerate" → Build Phases
2. Under "Compile Sources", verify:
   - `ImageGenerationModule.m` is listed
   - `ImageGenerationModule.swift` is listed

### 4. Check Console Logs

On device:
1. Connect device to Mac
2. Open Xcode → Window → Devices and Simulators
3. Select your device
4. View console logs
5. Look for:
   - "ImageGenerationModule registered"
   - Any errors about the module

### 5. Test Module Availability

Add this to `App.tsx` temporarily:

```typescript
import { NativeModules } from 'react-native';

console.log('Available modules:', Object.keys(NativeModules));
console.log('ImageGenerationModule:', NativeModules.ImageGenerationModule);
```

### 6. Verify Bridging Header

Check `ios/ImageGenerate/ImageGenerate-Bridging-Header.h`:
```objc
#import <React/RCTBridgeModule.h>
#import <React/RCTViewManager.h>
```

### 7. Check Module Name

The module name in Swift must match exactly:
```swift
@objc(ImageGenerationModule)
class ImageGenerationModule: NSObject {
```

And in the bridge:
```objc
RCT_EXTERN_MODULE(ImageGenerationModule, NSObject)
```

### 8. Rebuild Completely

```bash
# Clean everything
cd ios
rm -rf build
rm -rf Pods
pod install
cd ..

# Rebuild
npx expo run:ios --device
```

### 9. Check if Module is Actually Built

In Xcode:
1. Product → Build (⌘B)
2. Check build log for:
   - "Compiling ImageGenerationModule.swift"
   - "Compiling ImageGenerationModule.m"
   - No errors

### 10. Verify React Native Bridge

The module should be automatically registered. If not, check:
- React Native version compatibility
- Expo SDK version
- Native module setup
