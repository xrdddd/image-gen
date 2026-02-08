#!/bin/bash
# Fix file watcher issues

echo "🔧 Fixing file watcher issues..."

# Kill any existing Metro/Expo processes
echo "1. Killing existing processes..."
pkill -f "expo start" || true
pkill -f "metro" || true
pkill -f "react-native" || true

# Clear caches
echo "2. Clearing caches..."
rm -rf .expo
rm -rf node_modules/.cache
rm -rf $TMPDIR/metro-*
rm -rf $TMPDIR/haste-map-*

# Clear watchman if installed
if command -v watchman &> /dev/null; then
  echo "3. Clearing watchman..."
  watchman watch-del-all || true
fi

echo "✅ Done! Try running 'npm start' again."
