#!/bin/bash
# Fix file watcher issues

echo "🔧 Fixing file watcher issues..."

# Increase file descriptor limit
echo "1. Increasing file descriptor limit..."
ulimit -n 4096 2>/dev/null || ulimit -n 10240 2>/dev/null || true

# Kill any existing Metro/Expo processes
echo "2. Killing existing processes..."
pkill -f "expo start" || true
pkill -f "metro" || true
pkill -f "react-native" || true
pkill -f "node.*expo" || true

# Clear caches
echo "3. Clearing caches..."
rm -rf .expo
rm -rf node_modules/.cache
rm -rf $TMPDIR/metro-*
rm -rf $TMPDIR/haste-map-*
rm -rf $TMPDIR/react-* 2>/dev/null || true

# Clear watchman if installed
if command -v watchman &> /dev/null; then
  echo "4. Clearing watchman..."
  watchman watch-del-all 2>/dev/null || true
  watchman shutdown-server 2>/dev/null || true
  sleep 1
  echo "   Watchman version: $(watchman --version 2>/dev/null || echo 'not available')"
fi

# Verify watchman is working
if command -v watchman &> /dev/null; then
  echo "5. Verifying watchman..."
  watchman get-sockname > /dev/null 2>&1 && echo "   ✅ Watchman is ready" || echo "   ⚠️ Watchman may need restart"
fi

echo ""
echo "✅ Done! Now run:"
echo "   ulimit -n 4096 && npm start"
echo "   or"
echo "   npm run start:ios"
