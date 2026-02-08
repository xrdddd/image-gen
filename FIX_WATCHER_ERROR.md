# Fix "EMFILE: too many open files" Error

## The Problem

Even with high file limits, Node.js file watchers can still fail when watching too many files. This is common with large `node_modules` directories.

## Solutions (Try in Order)

### Solution 1: Install Watchman (Best)

Watchman is Facebook's file watching service, much more efficient:

```bash
brew install watchman
```

Then restart:
```bash
npm start
```

**Why this works:** Watchman uses a single process to watch files instead of opening thousands of file descriptors.

### Solution 2: Clear Caches and Restart

```bash
# Use the fix script
npm run fix-watcher

# Or manually:
rm -rf .expo
rm -rf node_modules/.cache
pkill -f "expo start"
npm start
```

### Solution 3: Use Clean Start Script

```bash
npm run start:clean
```

This clears all caches and restarts the dev server.

### Solution 4: Reduce Watched Files

The `.watchmanconfig` file I created will help, but you can also:

1. **Close other projects** that might be running file watchers
2. **Close VS Code/IDEs** that have file watchers running
3. **Use the Metro config** I created (`.metro.config.js`)

### Solution 5: Use Polling Instead of Watching (Last Resort)

If nothing else works, force Metro to use polling:

```bash
# Set environment variable
export EXPO_USE_FAST_REFRESH=false
export WATCHMAN_DISABLE_SINCE=0

# Or add to your shell profile
echo 'export WATCHMAN_DISABLE_SINCE=0' >> ~/.zshrc
```

Then restart.

## Quick Fix Commands

```bash
# Option 1: Install watchman (recommended)
brew install watchman && npm start

# Option 2: Clear and restart
npm run fix-watcher && npm start

# Option 3: Clean start
npm run start:clean
```

## Why This Happens

- Large `node_modules` directory (thousands of files)
- Multiple file watchers running (Metro, IDE, etc.)
- Node.js FSEvent watcher limitations
- macOS file system event limits

## Prevention

1. **Always use watchman** for React Native/Expo projects
2. **Keep `.watchmanconfig`** to ignore unnecessary directories
3. **Close unused projects** and IDEs
4. **Use `.gitignore`** properly to exclude build artifacts

## Verify Fix

After installing watchman:

```bash
watchman --version
# Should show version number

npm start
# Should work without EMFILE error
```

## If Still Failing

1. **Check for other watchers:**
   ```bash
   ps aux | grep -i watch
   ```

2. **Restart your Mac** (clears all file handles)

3. **Reduce node_modules:**
   ```bash
   rm -rf node_modules
   npm install --production
   ```

4. **Use EAS Build** instead of local development:
   ```bash
   npx eas-cli build --profile development --platform ios
   ```
