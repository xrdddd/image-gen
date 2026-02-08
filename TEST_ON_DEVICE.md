# Testing on iOS Device

## After `npm run build:ios`

The `npm run build:ios` command uses EAS Build to create a build in the cloud. Here's how to test it on your device:

## Option 1: EAS Build (Cloud Build)

### Step 1: Build Completes

After `npm run build:ios` finishes, EAS will:
- Build your app in the cloud
- Provide a download link
- Send you an email (if configured)

### Step 2: Download the Build

1. **Check Terminal Output**
   - EAS will show a URL like: `https://expo.dev/artifacts/...`
   - Or check: https://expo.dev/accounts/[your-account]/builds

2. **Download the .ipa file**
   - Click the download link
   - Save the `.ipa` file to your Mac

### Step 3: Install on Device

**Method A: Using Xcode (Easiest)**

1. Connect your iPhone to your Mac via USB
2. Open Xcode
3. Go to **Window → Devices and Simulators**
4. Select your device
5. Click **"+"** under "Installed Apps"
6. Select the downloaded `.ipa` file
7. Wait for installation
8. Trust the developer certificate on your device:
   - Settings → General → VPN & Device Management
   - Tap your developer certificate
   - Tap "Trust"

**Method B: Using Apple Configurator 2**

1. Download Apple Configurator 2 from Mac App Store
2. Connect your iPhone
3. Select your device
4. Click "Add" → "Apps"
5. Select the `.ipa` file
6. Install

**Method C: Using TestFlight (For Distribution)**

1. Upload build to App Store Connect
2. Add to TestFlight
3. Install TestFlight app on your device
4. Accept invitation and install

### Step 4: Run the App

1. Find the app icon on your device
2. Tap to open
3. If you see "Untrusted Developer":
   - Settings → General → VPN & Device Management
   - Trust your developer certificate

## Option 2: Local Build (Faster for Testing)

For faster iteration during development, use local build:

```bash
# This builds and installs directly on connected device
npx expo run:ios --device
```

**Requirements:**
- iPhone connected via USB
- Xcode installed
- Device registered in Xcode
- Development team configured

**Steps:**
1. Connect iPhone to Mac
2. Unlock iPhone and trust computer
3. Run: `npx expo run:ios --device`
4. Select your device when prompted
5. App installs and launches automatically

## Option 3: Development Build (Recommended for Native Modules)

Since you're using native modules, use a development build:

```bash
# Build development version
npx eas-cli build --profile development --platform ios

# Or build locally
npx expo run:ios --device
```

**Benefits:**
- Includes native modules
- Supports hot reload
- Can connect to Expo dev server
- Better for testing

## Quick Testing Workflow

### For Development (Recommended):

```bash
# 1. Start Expo dev server
npm start

# 2. In another terminal, build and install on device
npx expo run:ios --device
```

This will:
- Build the app with native modules
- Install on your connected iPhone
- Launch the app
- Connect to dev server for hot reload

### For Production Testing:

```bash
# 1. Build production version
npm run build:ios

# 2. Wait for build to complete
# 3. Download .ipa file
# 4. Install via Xcode (see Method A above)
```

## Troubleshooting

### "Device not found"

1. **Check connection:**
   ```bash
   xcrun xctrace list devices
   ```
   Should show your device

2. **Trust computer:**
   - Unlock iPhone
   - Tap "Trust This Computer" when prompted

3. **Register device in Xcode:**
   - Open Xcode
   - Window → Devices and Simulators
   - Device should appear

### "Untrusted Developer"

1. Settings → General → VPN & Device Management
2. Find your developer certificate
3. Tap "Trust [Your Name]"
4. Confirm trust

### "App won't launch"

1. Check device iOS version (needs iOS 13+)
2. Verify app is installed (check home screen)
3. Try reinstalling
4. Check console logs in Xcode

### "Native module not found"

1. Ensure you're using a **development build** (not Expo Go)
2. Run: `npx expo run:ios --device`
3. Check that native files are linked in Xcode

## Testing Checklist

- [ ] Device connected and trusted
- [ ] App installed successfully
- [ ] App launches without crashes
- [ ] Native module loads (check console logs)
- [ ] Models download (if using cloud downloads)
- [ ] Image generation works
- [ ] No errors in console

## Recommended Approach

**For initial testing:**
```bash
npx expo run:ios --device
```

**For production testing:**
```bash
npm run build:ios
# Then install .ipa via Xcode
```

## Next Steps After Installation

1. **Test model download** (if using cloud):
   - App should check for cached models
   - Show download button if needed
   - Download models on first use

2. **Test image generation**:
   - Enter a prompt
   - Generate an image
   - Verify it works

3. **Check console logs**:
   - Connect device to Mac
   - View logs in Xcode Console
   - Or use: `xcrun simctl spawn booted log stream`
