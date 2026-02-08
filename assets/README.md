# Assets Directory

This directory should contain the following image assets for your app:

## Required Assets

### 1. `icon.png`
- **Size**: 1024x1024 pixels
- **Format**: PNG
- **Purpose**: Main app icon for iOS and Android
- **Requirements**: 
  - No transparency
  - Square format
  - High resolution

### 2. `splash.png`
- **Size**: 1242x2436 pixels (or 2048x2732 for iPad)
- **Format**: PNG
- **Purpose**: Splash screen shown when app launches
- **Requirements**:
  - Should match your app's branding
  - Center your logo/content as safe area may vary

### 3. `adaptive-icon.png`
- **Size**: 1024x1024 pixels
- **Format**: PNG
- **Purpose**: Android adaptive icon foreground
- **Requirements**:
  - Should work on various Android icon shapes
  - Keep important content in center 66% of image

### 4. `favicon.png`
- **Size**: 48x48 pixels (or 32x32)
- **Format**: PNG
- **Purpose**: Web favicon (if deploying web version)

## Generating Assets

You can use these tools to generate the required assets:

1. **Expo Asset Generator**: https://docs.expo.dev/guides/app-icons/
2. **App Icon Generator**: https://www.appicon.co/
3. **IconKitchen**: https://icon.kitchen/
4. **Figma**: Design your icons and export at required sizes

## Quick Setup

If you have a logo image, you can use ImageMagick or online tools to resize:

```bash
# Example with ImageMagick (if installed)
convert your-logo.png -resize 1024x1024 icon.png
convert your-logo.png -resize 1242x2436 splash.png
```

## Notes

- All images should be optimized for file size
- Use PNG format for transparency support where needed
- Test icons on actual devices to ensure they look good
- Consider creating different sizes for different device densities if needed
