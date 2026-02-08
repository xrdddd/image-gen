# How to Clear Certificate Selection

When running `npx expo run:ios --device`, Expo/Xcode remembers your certificate selection. Here's how to clear and reset it:

## Method 1: Clear Expo Cache (Recommended)

```bash
# Clear Expo cache
npx expo start --clear

# Or clear all caches
rm -rf node_modules/.cache
rm -rf .expo
```

## Method 2: Clear Xcode Derived Data

```bash
# Clear Xcode derived data (removes build cache and settings)
rm -rf ~/Library/Developer/Xcode/DerivedData

# Or use Xcode:
# Xcode → Preferences → Locations → Derived Data → Click arrow → Delete folder
```

## Method 3: Remove iOS Build Folder

```bash
# Remove the iOS build directory
rm -rf ios/build

# If you have an ios/ directory
rm -rf ios/
```

## Method 4: Clear Specific Expo Config

```bash
# Clear Expo's local configuration
rm -rf .expo
rm -rf node_modules/.cache/expo
```

## Method 5: Interactive Certificate Selection

When you run the build, you can interactively select a certificate:

```bash
# This will prompt you to select a certificate/team
npx expo run:ios --device
```

If prompted:
- Select your development team
- Choose a certificate
- Or create a new one

## Method 6: Specify Certificate Explicitly

You can specify the certificate in `app.json` or `app.config.js`:

```javascript
// app.config.js
export default {
  expo: {
    ios: {
      bundleIdentifier: "com.imagegenerate.app",
      // Force specific team ID
      config: {
        usesNonExemptEncryption: false
      }
    }
  }
};
```

Or use environment variables:

```bash
# Set team ID
export APPLE_TEAM_ID=your-team-id
npx expo run:ios --device
```

## Method 7: Clear Keychain (Advanced)

If you're having persistent certificate issues:

```bash
# List certificates
security find-identity -v -p codesigning

# Delete specific certificate (use with caution)
# security delete-identity -c "Apple Development: your@email.com"
```

## Method 8: Complete Reset

For a complete reset:

```bash
# 1. Clear Expo cache
rm -rf .expo
rm -rf node_modules/.cache

# 2. Clear Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# 3. Remove iOS build folder (if exists)
rm -rf ios/build
rm -rf ios/

# 4. Reinstall dependencies (optional)
npm install

# 5. Run again - will prompt for certificate
npx expo run:ios --device
```

## Quick Fix (Most Common)

The quickest way to reset certificate selection:

```bash
# Clear Expo cache and rebuild
rm -rf .expo
npx expo run:ios --device
```

This will prompt you to select a certificate/team again.

## Understanding Certificate Storage

Expo/Xcode stores certificate selections in:
- `~/.expo/` - Expo local configuration
- `ios/` directory - Xcode project settings (if exists)
- `~/Library/Developer/Xcode/DerivedData/` - Xcode build cache
- Keychain - System certificate storage

## When to Clear Certificate Selection

Clear certificate selection when:
- Switching between Apple Developer accounts
- Certificate expired or revoked
- Want to use a different team
- Getting "Invalid certificate" errors
- Certificate selection dialog not appearing

## After Clearing

When you run `npx expo run:ios --device` again:
1. Xcode will prompt you to select a development team
2. Choose your Apple Developer account
3. Select or create a certificate
4. Build will proceed with new selection

## Troubleshooting

### "No certificate found"
- Make sure you're logged into Xcode with your Apple ID
- Xcode → Preferences → Accounts → Add your Apple ID
- Ensure you have a valid development certificate

### "Certificate expired"
- Xcode → Preferences → Accounts
- Select your account → Download Manual Profiles
- Or let Xcode automatically manage certificates

### "Team ID not found"
- Check your Apple Developer account
- Verify team ID in Apple Developer portal
- Update in Xcode Preferences → Accounts
