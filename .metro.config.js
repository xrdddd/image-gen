// Learn more https://docs.expo.dev/guides/customizing-metro
const { getDefaultConfig } = require('expo/metro-config');

/** @type {import('expo/metro-config').MetroConfig} */
const config = getDefaultConfig(__dirname);

// Reduce file watcher load
config.watchFolders = [
  __dirname,
];

// Ignore patterns to reduce watched files
config.resolver = {
  ...config.resolver,
  blockList: [
    /node_modules\/.*\/node_modules\/react-native\/.*/,
  ],
};

// Reduce watcher overhead
config.server = {
  ...config.server,
  enhanceMiddleware: (middleware) => {
    return middleware;
  },
};

module.exports = config;
