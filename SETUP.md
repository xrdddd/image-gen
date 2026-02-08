# Quick Setup Guide

Follow these steps to get your Image Generate app up and running:

## Step 1: Install Dependencies

```bash
npm install
```

## Step 2: Configure Environment Variables

Create a `.env` file in the root directory:

```env
EXPO_PUBLIC_API_BASE_URL=https://api.openai.com/v1
EXPO_PUBLIC_API_KEY=sk-your-api-key-here
```

**Getting an API Key:**
- For OpenAI DALL-E: https://platform.openai.com/api-keys
- For Stability AI: https://platform.stability.ai/account/keys
- For Replicate: https://replicate.com/account/api-tokens

## Step 3: Add App Assets

Add the following files to the `assets/` directory:
- `icon.png` (1024x1024)
- `splash.png` (1242x2436)
- `adaptive-icon.png` (1024x1024)
- `favicon.png` (48x48)

See `assets/README.md` for details.

## Step 4: Start Development Server

```bash
npm start
```

Then:
- Press `i` to open iOS simulator
- Press `a` to open Android emulator
- Scan QR code with Expo Go app on your phone

## Step 5: Test Image Generation

1. Enter a prompt like "a beautiful sunset over mountains"
2. Tap "Generate Image"
3. Wait for the image to appear

## Next Steps for Production

### For iOS App Store:

1. **Update Bundle Identifier:**
   - Edit `app.json` and change `bundleIdentifier` to your unique identifier (e.g., `com.yourcompany.imagegenerate`)

2. **Install EAS CLI and Configure:**
   
   The scripts now use `npx eas-cli` which will automatically install EAS CLI when needed. However, if you prefer to install it globally:
   
   ```bash
   # Option 1: Use npx (recommended, no installation needed)
   npx eas-cli login
   npx eas-cli build:configure
   
   # Option 2: Install globally (if you have permissions)
   npm install -g eas-cli
   eas login
   eas build:configure
   
   # Option 3: Install locally (already in package.json)
   npm install
   npx eas-cli login
   npx eas-cli build:configure
   ```

3. **Build:**
   ```bash
   eas build --platform ios --profile production
   ```

4. **Submit:**
   ```bash
   eas submit --platform ios
   ```

### For Google Play Store:

1. **Update Package Name:**
   - Edit `app.json` and change `package` to your unique package name (e.g., `com.yourcompany.imagegenerate`)

2. **Build:**
   ```bash
   eas build --platform android --profile production
   ```

3. **Submit:**
   ```bash
   eas submit --platform android
   ```

## Troubleshooting

### "API key not configured" error
- Make sure your `.env` file exists in the root directory
- Restart the Expo server after creating/editing `.env`
- Check that the variable name starts with `EXPO_PUBLIC_`

### Build fails
- Make sure you're logged into EAS: `eas login`
- Check that your `eas.json` is properly configured
- Verify your Apple/Google developer accounts are set up

### Images not generating
- Verify your API key is valid and has credits
- Check your internet connection
- Review the error message in the app for details

## Need Help?

- Check the main `README.md` for detailed documentation
- Expo Docs: https://docs.expo.dev/
- EAS Build Docs: https://docs.expo.dev/build/introduction/
