# Fix Apple Developer Portal Authentication Error

## The Problem

When running `npx expo run:ios --device` or EAS builds, you may see:
```
✖ Logging in...
Authentication with Apple Developer Portal failed!
Received an internal server error from Apple's App Store Connect / Developer Portal servers
```

## Quick Fixes (Try in Order)

### Fix 1: Retry (Apple Server Issue)

This is often a temporary Apple server issue. Simply retry:

```bash
# Wait a few minutes and try again
npx expo run:ios --device
```

### Fix 2: Re-authenticate with Apple

```bash
# Clear Apple authentication
eas credentials

# Or specifically for iOS
eas credentials -p ios

# This will prompt you to log in again
```

### Fix 3: Check Xcode Authentication

1. **Open Xcode**
2. **Go to**: Xcode → Settings → Accounts
3. **Select your Apple ID**
4. **Click "Download Manual Profiles"** (or "Manage Certificates")
5. **Sign out and sign back in** if needed

### Fix 4: Use Xcode Directly (Bypass EAS Auth)

Instead of using EAS authentication, let Xcode handle it:

```bash
# This uses Xcode's built-in authentication
npx expo run:ios --device --no-build-cache
```

Or open the project in Xcode:

```bash
# Generate iOS project
npx expo prebuild --platform ios

# Open in Xcode
open ios/*.xcworkspace
```

Then in Xcode:
1. Select your development team in **Signing & Capabilities**
2. Xcode will handle authentication automatically
3. Build and run from Xcode

### Fix 5: Clear Expo/EAS Cache

```bash
# Clear EAS cache
rm -rf ~/.expo
rm -rf .expo

# Clear npm cache
npm cache clean --force

# Try again
npx expo run:ios --device
```

### Fix 6: Check Apple Developer Account Status

1. **Visit**: https://developer.apple.com/account
2. **Sign in** with your Apple ID
3. **Verify**:
   - Account is active
   - No payment issues
   - License agreement accepted
   - Account not suspended

### Fix 7: Use App-Specific Password (If 2FA Enabled)

If you have 2FA enabled, you might need an app-specific password:

1. **Go to**: https://appleid.apple.com
2. **Sign in** → **Security** → **App-Specific Passwords**
3. **Generate** a new password
4. **Use it** when prompted for password

### Fix 8: Check Network/Firewall

Apple's servers might be blocked:

```bash
# Test connectivity
curl -I https://developer.apple.com
curl -I https://appstoreconnect.apple.com

# If blocked, check:
# - VPN settings
# - Firewall rules
# - Corporate proxy
```

## Alternative: Use Local Development Without EAS

If EAS authentication continues to fail, use local development:

### Option A: Local Build with Xcode

```bash
# 1. Prebuild iOS project
npx expo prebuild --platform ios

# 2. Open in Xcode
open ios/*.xcworkspace

# 3. In Xcode:
#    - Select your team in Signing & Capabilities
#    - Connect your device
#    - Build and run (⌘R)
```

### Option B: Use Expo Development Build Locally

```bash
# Build development client locally
npx expo run:ios --device

# This bypasses EAS authentication
# Uses Xcode's built-in signing
```

## Troubleshooting Specific Errors

### "Internal Server Error"

**Cause**: Apple's servers are temporarily down

**Solution**:
1. Wait 10-15 minutes
2. Check Apple System Status: https://www.apple.com/support/systemstatus/
3. Retry the command

### "Authentication Failed"

**Cause**: Invalid credentials or expired session

**Solution**:
```bash
# Clear and re-authenticate
eas logout
eas login

# Or use Xcode authentication instead
```

### "Team Not Found"

**Cause**: Apple ID not associated with a developer team

**Solution**:
1. Verify you have an active Apple Developer account
2. Check team ID in Apple Developer Portal
3. Make sure you're using the correct Apple ID

### "Certificate Expired"

**Cause**: Development certificate expired

**Solution**:
1. Open Xcode → Settings → Accounts
2. Select your Apple ID
3. Click "Download Manual Profiles"
4. Or let Xcode automatically manage certificates

## Verify Authentication

### Check EAS Authentication

```bash
# Check if logged in
eas whoami

# If not logged in, login
eas login
```

### Check Xcode Authentication

1. Open Xcode → Settings → Accounts
2. Your Apple ID should appear
3. Status should show as "Active"

### Check Apple Developer Portal

1. Visit: https://developer.apple.com/account
2. Sign in
3. Should see your team and certificates

## Recommended Workflow

For local development, use Xcode directly:

```bash
# 1. Prebuild (one time)
npx expo prebuild --platform ios

# 2. Open in Xcode
open ios/*.xcworkspace

# 3. Configure signing in Xcode:
#    - Select your team
#    - Xcode handles certificates automatically

# 4. Build and run from Xcode
#    - Connect device
#    - Press ⌘R to build and run
```

This avoids EAS authentication issues entirely.

## For EAS Builds (Cloud)

If you need to use EAS Build:

```bash
# 1. Make sure you're logged in
eas login

# 2. Configure credentials
eas credentials -p ios

# 3. Build
eas build --platform ios --profile development
```

If authentication still fails:
- Wait for Apple servers to recover
- Check Apple System Status
- Try again later

## Quick Command Reference

```bash
# Check authentication
eas whoami

# Re-authenticate
eas logout
eas login

# Use Xcode instead (bypasses EAS auth)
npx expo prebuild --platform ios
open ios/*.xcworkspace

# Local build (uses Xcode auth)
npx expo run:ios --device
```

## Summary

**Most Common Solution:**
1. Wait 10-15 minutes (Apple server issue)
2. Retry the command
3. If still failing, use Xcode directly

**Best Practice:**
- Use Xcode for local development
- Use EAS Build only for cloud builds
- Let Xcode handle authentication automatically
