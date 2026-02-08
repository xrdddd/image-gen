# EAS Build and Prebuild Behavior

## Does `npm run build:ios` Run Prebuild?

**Short Answer:** Yes, EAS Build automatically runs `prebuild` in the cloud, but it does **NOT** affect your local `ios/` directory.

## How EAS Build Works

### What Happens When You Run `npm run build:ios`

1. **Local**: Your code is packaged and sent to EAS servers
2. **Cloud**: EAS runs `expo prebuild` in a clean environment
3. **Cloud**: EAS builds the iOS app using the prebuilt project
4. **Local**: Your `ios/` directory is **NOT modified**

### Your Local `ios/` Directory is Safe

- ✅ EAS Build runs prebuild **in the cloud**, not locally
- ✅ Your local `ios/` directory remains unchanged
- ✅ Any custom modifications you made are preserved
- ✅ EAS Build uses a fresh prebuild for each build

## When Prebuild Runs Locally

Prebuild only runs locally when you explicitly run:

```bash
npx expo prebuild --platform ios
```

Or when you run:

```bash
npx expo run:ios --device
```

(Expo CLI runs prebuild automatically if `ios/` doesn't exist)

## Important: Local vs Cloud Prebuild

### Local Prebuild (`npx expo prebuild`)
- Runs on your machine
- Creates/updates `ios/` directory
- Can overwrite existing files
- Use when developing locally

### EAS Build Prebuild (Cloud)
- Runs on EAS servers
- Creates temporary `ios/` directory in cloud
- Does NOT touch your local `ios/` directory
- Happens automatically during `npm run build:ios`

## Your Custom iOS Code

If you've made custom modifications to files in `ios/`:

### ✅ Safe from EAS Build
- EAS Build won't modify your local `ios/` directory
- Your custom code is preserved
- EAS uses its own prebuild in the cloud

### ⚠️ Will Be Overwritten by Local Prebuild
- Running `npx expo prebuild --platform ios` locally will overwrite
- Use `--no-install` flag to preserve some changes
- Or use `npx expo prebuild --platform ios --clean` to force fresh build

## Best Practices

### For EAS Builds (Cloud)
```bash
# Your local ios/ directory is safe
npm run build:ios

# EAS handles prebuild in cloud
# Your local ios/ stays unchanged
```

### For Local Development
```bash
# Only run prebuild if ios/ doesn't exist
# Or if you want to regenerate it
npx expo prebuild --platform ios

# To preserve some custom files, use:
npx expo prebuild --platform ios --no-install
```

### To Preserve Custom iOS Code

1. **Use Config Plugins** (Recommended)
   - Create custom config plugins
   - They run during prebuild
   - Preserve your changes automatically

2. **Use `.gitignore` for Custom Files**
   - Add custom files to `.gitignore`
   - Prebuild won't overwrite ignored files

3. **Use `app.config.js` Hooks**
   - Use `withPlugins` to modify iOS project
   - Changes are applied during prebuild

## Checking Your iOS Directory

To see what's in your local `ios/` directory:

```bash
# List iOS directory
ls -la ios/

# Check if it exists
test -d ios/ && echo "ios/ exists" || echo "ios/ does not exist"

# See file count
find ios/ -type f 2>/dev/null | wc -l
```

## Summary

| Command | Runs Prebuild | Affects Local `ios/` |
|---------|--------------|---------------------|
| `npm run build:ios` | ✅ (in cloud) | ❌ No |
| `npx expo prebuild` | ✅ (local) | ✅ Yes (overwrites) |
| `npx expo run:ios` | ✅ (if needed) | ✅ Yes (if ios/ missing) |

**Your local `ios/` directory is safe when using EAS Build!**
