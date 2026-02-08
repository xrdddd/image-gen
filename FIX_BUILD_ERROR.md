# Fix Build Error: TARGET_IPHONE_SIMULATOR

## Error
```
❌ cannot find 'TARGET_IPHONE_SIMULATOR' in scope
(node_modules/expo-dev-menu/ios/DevMenuViewController.swift:64:23)
```

## Cause

The `expo-dev-menu` package uses `TARGET_IPHONE_SIMULATOR`, a C preprocessor macro that isn't available in Swift. This needs to be replaced with Swift's `#if targetEnvironment(simulator)`.

## Solution

### Option 1: Quick Fix (Temporary)

I've already patched the file directly. The fix replaces:
```swift
let isSimulator = TARGET_IPHONE_SIMULATOR > 0
```

With:
```swift
#if targetEnvironment(simulator)
let isSimulator = true
#else
let isSimulator = false
#endif
```

**Note:** This patch will be lost if you run `npm install` again.

### Option 2: Permanent Fix with patch-package (Recommended)

1. **Install patch-package:**
   ```bash
   npm install --save-dev patch-package
   ```

2. **Create the patch:**
   ```bash
   npx patch-package expo-dev-menu
   ```

3. **Add postinstall script to package.json:**
   ```json
   "scripts": {
     "postinstall": "patch-package"
   }
   ```

4. **The patch will be saved in `patches/` directory**

### Option 3: Update Dependencies

Try updating to the latest versions:

```bash
npx expo install --fix
npm install
```

This might include a fix for this issue in newer versions.

## After Fixing

1. **Clean build:**
   ```bash
   rm -rf ios/build
   rm -rf ios/Pods
   cd ios && pod install && cd ..
   ```

2. **Rebuild:**
   ```bash
   npx expo run:ios --device
   ```

## Verification

The build should now succeed. If you still see the error:

1. Check that the file was patched:
   ```bash
   grep -A 3 "isSimulator" node_modules/expo-dev-menu/ios/DevMenuViewController.swift
   ```

2. Should show:
   ```swift
   #if targetEnvironment(simulator)
   let isSimulator = true
   #else
   let isSimulator = false
   #endif
   ```

## Alternative: Remove expo-dev-client

If you don't need development builds, you can remove `expo-dev-client`:

1. Remove from `package.json`
2. Remove from `app.config.js` and `app.json` plugins
3. Run `npm install`
4. Rebuild

But this will disable native module support, so not recommended for your use case.
