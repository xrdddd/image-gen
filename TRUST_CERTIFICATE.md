# Fix "Developer Certificate Not Trusted" on iOS Device

## The Problem

When installing an app on an iOS device, you may see:
- "Untrusted Developer" error
- App won't launch
- Certificate not trusted warning

## Solution: Trust the Developer Certificate

### Step 1: Install the App

First, install the app on your device using one of these methods:

**Option A: Via Xcode**
```bash
npx expo run:ios --device
```

**Option B: Via EAS Build**
```bash
npm run build:ios
# Then install the .ipa file via Xcode or TestFlight
```

**Option C: Via Expo Go (if applicable)**
```bash
npm start
# Scan QR code with Expo Go app
```

### Step 2: Trust the Developer Certificate

After installing, the app will appear on your home screen but won't launch. Follow these steps:

1. **Open iOS Settings** on your device
2. **Go to**: `General` → `VPN & Device Management` (or `Device Management` on older iOS)
3. **Find your developer account**:
   - Look for "Developer App" section
   - You'll see your Apple ID or team name
   - Example: "Apple Development: your.email@example.com"
4. **Tap on your developer account**
5. **Tap "Trust [Your Name]"**
6. **Confirm** by tapping "Trust" in the popup

### Step 3: Launch the App

After trusting:
1. Go back to your home screen
2. Tap the app icon
3. The app should now launch successfully

## Alternative: Check Certificate in Xcode

### View Certificates

1. Open **Xcode**
2. Go to **Xcode** → **Settings** (or **Preferences**)
3. Click **Accounts** tab
4. Select your Apple ID
5. Click **Manage Certificates...**
6. Verify you have:
   - **Apple Development** certificate (for development)
   - **Apple Distribution** certificate (for App Store)

### Fix Certificate Issues

If certificates are missing or expired:

1. **In Xcode Settings → Accounts**:
   - Select your Apple ID
   - Click **Download Manual Profiles**
   - Or click **+** to create new certificates

2. **Or use command line**:
   ```bash
   # Clear and regenerate certificates
   npm run clear-certificate
   
   # Rebuild
   npx expo run:ios --device
   ```

## Common Issues

### Issue 1: "No Developer Account Found"

**Solution:**
1. Make sure you're signed in to Xcode with your Apple ID
2. Go to Xcode → Settings → Accounts
3. Add your Apple ID if not present
4. Accept the license agreement

### Issue 2: "Provisioning Profile Mismatch"

**Solution:**
```bash
# Clear provisioning profiles
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*

# Clear Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Rebuild
npx expo run:ios --device
```

### Issue 3: "Certificate Expired"

**Solution:**
1. Open Xcode → Settings → Accounts
2. Select your Apple ID
3. Click **Manage Certificates...**
4. Delete expired certificates
5. Click **+** to create new ones
6. Rebuild the app

### Issue 4: Device Not Registered

**Solution:**
1. Open Xcode → Settings → Accounts
2. Select your Apple ID
3. Click **Manage Certificates...**
4. Make sure your device is registered in Apple Developer Portal
5. Or register it via Xcode:
   - Connect device via USB
   - Open Xcode → Window → Devices and Simulators
   - Your device should appear and be registered automatically

## Quick Fix Commands

```bash
# 1. Clear all caches and certificates
npm run clear-certificate

# 2. Rebuild for device
npx expo run:ios --device

# 3. If still failing, check Xcode signing
# Open ios/YourApp.xcworkspace in Xcode
# Go to Signing & Capabilities
# Select your team
```

## Verify Certificate Trust

After trusting, verify it worked:

1. **Check Settings**:
   - Go to Settings → General → VPN & Device Management
   - Your developer account should show as "Verified"

2. **Launch App**:
   - App should launch without warnings
   - No "Untrusted Developer" popup

## For Enterprise Distribution

If using enterprise certificates:

1. **Install Enterprise Profile**:
   - Download from your enterprise portal
   - Install via Settings → General → VPN & Device Management

2. **Trust Enterprise Developer**:
   - Same process as above
   - Look for your enterprise name instead of personal Apple ID

## Troubleshooting

### Still Not Working?

1. **Restart Device**: Sometimes iOS needs a restart after trusting
2. **Reinstall App**: Delete and reinstall the app
3. **Check Date/Time**: Make sure device date/time is correct
4. **Update iOS**: Make sure device is on latest iOS version
5. **Check Internet**: Device needs internet to verify certificates

### Check Logs

```bash
# View device logs
xcrun simctl spawn booted log stream --predicate 'process == "YourApp"'

# Or use Console.app on Mac
# Connect device, open Console.app, filter by your app name
```

## Prevention

To avoid this issue in the future:

1. **Use Automatic Signing** in Xcode (recommended)
2. **Keep Certificates Updated**: Check Xcode Settings regularly
3. **Register Devices Early**: Add devices to your developer account before building
4. **Use EAS Build**: EAS handles certificates automatically

## Summary

**Quick Steps:**
1. Install app on device
2. Settings → General → VPN & Device Management
3. Find your developer account
4. Tap "Trust"
5. Launch app

That's it! The certificate should now be trusted and the app will launch.
