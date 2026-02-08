# Fix Old Provisioning Profile Issue

## The Problem

The build is using an old provisioning profile with bundle ID `njd123imagegenerateapp` instead of the current bundle identifier.

## Quick Fix

### Step 1: Update Bundle Identifier

Make sure your `app.json` has the correct bundle identifier:

```json
{
  "expo": {
    "ios": {
      "bundleIdentifier": "com.imagegenerate.app"
    }
  }
}
```

### Step 2: Clear Old Provisioning Profiles

```bash
# Clear all provisioning profiles
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*

# Clear Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Clear Expo cache
rm -rf .expo

# Clear iOS build folder
rm -rf ios/build
```

### Step 3: Rebuild

```bash
# For EAS Build
npm run build:ios

# Or for local build
npx expo run:ios --device
```

## Detailed Solution

### Option 1: Use EAS Credentials (Recommended for EAS Build)

```bash
# Configure credentials for iOS
npx eas-cli credentials -p ios

# This will:
# - Show current bundle identifier
# - Let you update it
# - Generate new provisioning profiles
# - Remove old ones
```

### Option 2: Clear and Regenerate (Local Build)

1. **Clear provisioning profiles:**
   ```bash
   rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*
   ```

2. **Clear Xcode cache:**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```

3. **Clear Expo cache:**
   ```bash
   rm -rf .expo
   rm -rf ios/build
   ```

4. **Prebuild with correct bundle ID:**
   ```bash
   npx expo prebuild --platform ios --clean
   ```

5. **Open in Xcode and configure:**
   ```bash
   open ios/*.xcworkspace
   ```
   
   In Xcode:
   - Select your project in the navigator
   - Go to "Signing & Capabilities"
   - Select your team
   - Xcode will generate new provisioning profiles automatically

### Option 3: Update Bundle ID in Apple Developer Portal

If you need to keep the old bundle ID or create a new one:

1. **Visit**: https://developer.apple.com/account/resources/identifiers/list
2. **Find or create** App ID with your desired bundle identifier
3. **Create new provisioning profile** for that App ID
4. **Download and install** the new profile

## Verify Bundle Identifier

### Check app.json

```bash
# View current bundle identifier
cat app.json | grep -A 2 "bundleIdentifier"
```

### Check iOS Project

```bash
# Check Xcode project
grep -r "PRODUCT_BUNDLE_IDENTIFIER" ios/*.xcodeproj/project.pbxproj
```

### Check Provisioning Profiles

```bash
# List all provisioning profiles
ls -la ~/Library/MobileDevice/Provisioning\ Profiles/

# Check bundle IDs in profiles
security cms -D -i ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision 2>/dev/null | grep -A 1 "application-identifier" | head -20
```

## Common Issues

### Issue 1: Multiple Bundle IDs

**Problem**: Old bundle ID still in use

**Solution**:
```bash
# Clear everything
npm run clear-certificate

# Update app.json with correct bundle ID
# Then rebuild
npx expo prebuild --platform ios --clean
```

### Issue 2: Provisioning Profile Mismatch

**Problem**: Profile doesn't match bundle ID

**Solution**:
1. Delete old profiles (see Step 2 above)
2. Let Xcode regenerate automatically
3. Or use EAS credentials management

### Issue 3: Team ID Mismatch

**Problem**: Profile is for different team

**Solution**:
1. In Xcode → Settings → Accounts
2. Select correct team
3. Download manual profiles
4. Or let Xcode manage automatically

## Using EAS Credentials

The easiest way to fix this is using EAS:

```bash
# 1. Configure credentials
npx eas-cli credentials -p ios

# 2. Select "Set up new credentials"
# 3. Choose your bundle identifier
# 4. EAS will handle provisioning profiles automatically
```

## Manual Fix in Xcode

1. **Open project:**
   ```bash
   open ios/*.xcworkspace
   ```

2. **Select project** in navigator

3. **Select target** (ImageGenerate)

4. **Go to "Signing & Capabilities" tab**

5. **Uncheck "Automatically manage signing"** (temporarily)

6. **Select correct provisioning profile** from dropdown

7. **Or check "Automatically manage signing"** again to let Xcode fix it

8. **Select correct team**

9. **Xcode will generate new profile** automatically

## Verify Fix

After fixing, verify:

```bash
# Check bundle ID in project
grep "PRODUCT_BUNDLE_IDENTIFIER" ios/*.xcodeproj/project.pbxproj

# Should show: com.imagegenerate.app (or your desired ID)
```

## Prevention

To avoid this in the future:

1. **Always update `app.json`** before building
2. **Use EAS credentials** for cloud builds
3. **Clear caches** when changing bundle IDs
4. **Use consistent bundle IDs** across all configs

## Quick Command Reference

```bash
# Clear everything
npm run clear-certificate

# Update bundle ID in app.json, then:
npx expo prebuild --platform ios --clean

# Or use EAS
npx eas-cli credentials -p ios
```
