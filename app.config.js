export default {
  expo: {
    name: "Image Generate",
    slug: "image-generate-app",
    version: "1.0.0",
    orientation: "portrait",
    icon: "./assets/icon.png",
    userInterfaceStyle: "automatic",
    splash: {
      image: "./assets/splash.png",
      resizeMode: "contain",
      backgroundColor: "#ffffff"
    },
    assetBundlePatterns: [
      "**/*"
    ],
    ios: {
      supportsTablet: true,
      bundleIdentifier: "com.imagegenerate.app",
      buildNumber: "1.0.0",
      infoPlist: {
        NSPhotoLibraryUsageDescription: "This app needs access to your photo library to save generated images.",
        NSPhotoLibraryAddUsageDescription: "This app needs access to save images to your photo library."
      }
    },
    android: {
      adaptiveIcon: {
        foregroundImage: "./assets/adaptive-icon.png",
        backgroundColor: "#ffffff"
      },
      package: "com.imagegenerate.app",
      versionCode: 1,
      permissions: [
        "READ_EXTERNAL_STORAGE",
        "WRITE_EXTERNAL_STORAGE"
      ]
    },
    web: {
      favicon: "./assets/favicon.png"
    },
    plugins: [
      [
        "expo-image-picker",
        {
          photosPermission: "The app accesses your photos to let you save generated images."
        }
      ],
      "expo-dev-client"
    ],
    extra: {
      eas: {
        projectId: "aa56809e-3992-4478-90cf-524149957186"
      }
    }
  }
};
