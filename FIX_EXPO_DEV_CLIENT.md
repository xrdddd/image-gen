# Fix expo-dev-client Plugin Error

## Error
```
Failed to resolve plugin for module "expo-dev-client"
```

## Solution

The `expo-dev-client` package is listed in `package.json` but not installed in `node_modules`. 

### Step 1: Install Dependencies

Run this command **outside the sandbox** (in your terminal):

```bash
cd /Users/peterdou/Documents/enterprise/image-generate-2
npm install
```

This will install all dependencies including `expo-dev-client`.

### Step 2: Verify Installation

Check if `expo-dev-client` is installed:

```bash
ls node_modules/expo-dev-client
```

You should see the directory exists.

### Step 3: Test Configuration

```bash
npx expo config --type public
```

This should work without errors now.

## Alternative: Remove expo-dev-client (If Not Needed)

If you don't need development builds and only want production builds with cloud downloads, you can remove `expo-dev-client`:

### Option A: Remove from Config Only

Edit `app.config.js` and `app.json` to remove `"expo-dev-client"` from the plugins array:

```javascript
plugins: [
  [
    "expo-image-picker",
    {
      photosPermission: "The app accesses your photos to let you save generated images."
    }
  ]
  // Remove "expo-dev-client" from here
],
```

### Option B: Remove Completely

1. Remove from `package.json`:
   ```bash
   npm uninstall expo-dev-client
   ```

2. Remove from `app.config.js` and `app.json` plugins array

3. Remove from `eas.json` development profile (if present)

## Note

Since you're using **cloud downloads** for models, you might not need `expo-dev-client` for production builds. However, you still need it if you want to:
- Test native modules during development
- Use development builds
- Hot reload with native code changes

## Recommendation

**Keep `expo-dev-client`** and just run `npm install` to fix the issue. It's useful for development and testing native modules.
