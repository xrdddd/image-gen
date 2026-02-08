# Adding Apple's Stable Diffusion Swift Package

## ⚠️ IMPORTANT: Required Step

The code has been migrated to use Apple's Stable Diffusion framework, but **you must add the Swift package in Xcode** before the project will build.

## Step-by-Step Instructions

### 1. Open Xcode Workspace

```bash
cd ios
open ImageGenerate.xcworkspace
```

Or use:
```bash
npm run open:xcode
```

### 2. Add Package Dependency

1. In Xcode, select the **ImageGenerate** project in the navigator (the blue icon at the top)
2. Select the **ImageGenerate** target
3. Go to **File → Add Package Dependencies...** (or right-click project → Add Package Dependencies...)
4. In the search field, paste: `https://github.com/apple/ml-stable-diffusion`
5. Click **Add Package**
6. Select version: **0.3.0** or **Up to Next Major Version: 0.3.0**
7. Ensure **ImageGenerate** target is checked
8. Click **Add Package**

### 3. Verify Package Added

After adding, you should see:
- **Package Dependencies** section in the project navigator
- `ml-stable-diffusion` listed under Package Dependencies
- No red errors in `ImageGenerationModule.swift` related to `import StableDiffusion`

### 4. Build

```bash
# Option 1: Build via Xcode
# Product → Build (Cmd+B)

# Option 2: Build via Expo
npm run build:ios

# Option 3: Build via command line
cd ios
xcodebuild -workspace ImageGenerate.xcworkspace -scheme ImageGenerate -configuration Debug
```

## Troubleshooting

### "No such module 'StableDiffusion'"

**Solution:** The package wasn't added correctly. Repeat Step 2 above.

**Verify:**
- Check Package Dependencies in Xcode project navigator
- Ensure `ml-stable-diffusion` is listed
- Clean build folder: Product → Clean Build Folder (Shift+Cmd+K)

### Build Errors After Adding Package

1. **Clean Derived Data:**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

2. **Clean Build Folder:**
   - In Xcode: Product → Clean Build Folder

3. **Restart Xcode**

4. **Re-add Package** if needed

### Package Version Issues

- Try a specific version: `0.3.0`
- Or use: `Up to Next Major Version: 0.3.0`
- Check Apple's repository for latest version: https://github.com/apple/ml-stable-diffusion

## What Happens After Adding

Once the package is added:
- ✅ `import StableDiffusion` will work
- ✅ `StableDiffusionPipeline` class will be available
- ✅ All pipeline steps handled automatically
- ✅ No more black images!
- ✅ Better performance with Neural Engine

## Verification

After adding the package and building, you should see:
- Successful build with no errors
- Models load successfully
- Images generate correctly (not black)

## Need Help?

- Check Apple's repository: https://github.com/apple/ml-stable-diffusion
- Review the README in the repository
- Check example code in the repository
