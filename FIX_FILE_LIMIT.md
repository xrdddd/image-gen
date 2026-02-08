# Fix "EMFILE: too many open files" Error

## Error
```
Error: EMFILE: too many open files, watch
```

## Cause

macOS has a default limit on the number of open file descriptors (usually 256). File watchers (Metro bundler, Expo, etc.) need to watch many files and can exceed this limit.

## Quick Fix (Temporary)

### Option 1: Increase Limit for Current Session

```bash
# Check current limit
ulimit -n

# Increase limit (to 4096 or higher)
ulimit -n 4096

# Then run your command again
npm start
# or
npx expo run:ios --device
```

### Option 2: Set in Shell Profile (Permanent)

Add to your `~/.zshrc` (since you're using zsh):

```bash
# Increase file descriptor limit
ulimit -n 4096
```

Then reload:
```bash
source ~/.zshrc
```

## Permanent Fix (Recommended)

### Method 1: Create launchd limit.plist

1. **Create limit file:**
   ```bash
   sudo nano /Library/LaunchDaemons/limit.maxfiles.plist
   ```

2. **Add this content:**
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
     <dict>
       <key>Label</key>
       <string>limit.maxfiles</string>
       <key>ProgramArguments</key>
       <array>
         <string>launchctl</string>
         <string>limit</string>
         <string>maxfiles</string>
         <string>65536</string>
         <string>200000</string>
       </array>
       <key>RunAtLoad</key>
       <true/>
       <key>ServiceIPC</key>
       <false/>
     </dict>
   </plist>
   ```

3. **Load it:**
   ```bash
   sudo launchctl load -w /Library/LaunchDaemons/limit.maxfiles.plist
   ```

4. **Verify:**
   ```bash
   launchctl limit maxfiles
   ```

### Method 2: Use watchman (Recommended for React Native)

Watchman is Facebook's file watching service, more efficient than native watchers:

```bash
# Install watchman
brew install watchman

# Verify installation
watchman --version
```

Expo/Metro will automatically use watchman if available.

### Method 3: Add to .zshrc (Easiest)

Add this to `~/.zshrc`:

```bash
# Increase file descriptor limit
ulimit -n 4096

# Or for even more files
ulimit -n 65536
```

Then:
```bash
source ~/.zshrc
```

## Verify Fix

```bash
# Check current limit
ulimit -n

# Should show 4096 or higher
```

## Alternative: Reduce Watched Files

If you can't increase the limit, reduce what's being watched:

1. **Add to `.gitignore` or `.watchmanconfig`:**
   ```
   node_modules/
   .expo/
   ios/build/
   android/build/
   ```

2. **Use `.watchmanconfig` in project root:**
   ```json
   {
     "ignore_dirs": [
       "node_modules",
       ".expo",
       "ios/build",
       "android/build",
       "ios/Pods"
     ]
   }
   ```

## Quick Commands

```bash
# Quick fix for current session
ulimit -n 4096 && npm start

# Or for build
ulimit -n 4096 && npx expo run:ios --device
```

## Recommended Solution

**Best approach:**
1. Install watchman: `brew install watchman`
2. Add to `~/.zshrc`: `ulimit -n 4096`
3. Reload: `source ~/.zshrc`

This gives you both better file watching and higher limits.
