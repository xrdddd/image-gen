/**
 * Local Image Generation Service
 * 
 * This service handles on-device image generation using local ML models.
 * Optimized for iOS using Core ML with fallback to cross-platform solutions.
 */

import { Platform } from 'react-native';
import * as FileSystem from 'expo-file-system';
import { Asset } from 'expo-asset';

export interface GenerationOptions {
  steps?: number;
  guidanceScale?: number;
  seed?: number;
  width?: number;
  height?: number;
}

// Native module interface (will be implemented in native code)
interface NativeImageGeneration {
  generateImage(
    prompt: string,
    options: GenerationOptions
  ): Promise<string>; // Returns base64 image data
  isModelLoaded(): Promise<boolean>;
  loadModel(modelPath: string): Promise<boolean>;
}

// Try to import native module, fallback to null if not available
let NativeImageGen: NativeImageGeneration | null = null;

import { ImageGenerationModuleNative } from './native/ImageGenerationModule';

// Use the native module if available
if (ImageGenerationModuleNative) {
  NativeImageGen = {
    async loadModel(modelPath: string): Promise<boolean> {
      const result = await ImageGenerationModuleNative.loadModel(modelPath);
      // Handle both boolean and object return types
      if (typeof result === 'object' && result !== null) {
        return result.success === true;
      }
      return result === true;
    },
    async isModelLoaded(): Promise<boolean> {
      return await ImageGenerationModuleNative.isModelLoaded();
    },
    async generateImage(prompt: string, options: GenerationOptions): Promise<string> {
      return await ImageGenerationModuleNative.generateImage(
        prompt,
        options.steps || 20,
        options.guidanceScale || 7.5,
        options.seed || -1,
        options.width || 512,
        options.height || 512
      );
    },
  };
}

/**
 * Generate an image from a text prompt using on-device inference
 * 
 * @param prompt - The text description of the image to generate
 * @param options - Optional generation parameters
 * @returns Promise<string> - Base64 data URI of the generated image
 */
export async function generateImageLocal(
  prompt: string,
  options: GenerationOptions = {}
): Promise<string> {
  const {
    steps = 20,
    guidanceScale = 7.5,
    seed = -1, // -1 means random seed
    width = 512,
    height = 512,
  } = options;

  try {
    // Try to use native module first (best performance, especially on iOS)
    if (NativeImageGen) {
      const isLoaded = await NativeImageGen.isModelLoaded();
      
      if (!isLoaded) {
        // Load model if not already loaded
        const modelPath = await getModelPath();
        const loaded = await NativeImageGen.loadModel(modelPath);
        
        if (!loaded) {
          throw new Error('Failed to load ML model');
        }
      }

      // Generate image using native module
      const base64Image = await NativeImageGen.generateImage(prompt, {
        steps,
        guidanceScale,
        seed,
        width,
        height,
      });

      return `data:image/png;base64,${base64Image}`;
    }

    // Fallback: Use JavaScript-based generation (slower but works everywhere)
    return await generateImageFallback(prompt, {
      steps,
      guidanceScale,
      seed,
      width,
      height,
    });
  } catch (error: any) {
    console.error('Local image generation error:', error);
    throw new Error(
      error.message || 'Failed to generate image on device'
    );
  }
}

/**
 * Get the path to the ML model directory
 * Models are downloaded from cloud and cached locally
 */
async function getModelPath(): Promise<string> {
  try {
    if (Platform.OS === 'ios') {
      // Check if models are cached locally
      const { areAllModelsCached, getCachedModelPath } = await import('./modelDownloadService');
      
      const allCached = await areAllModelsCached();
      
      if (allCached) {
        // Use cached models from documents directory
        const cacheDir = `${FileSystem.documentDirectory}models/`;
        return cacheDir;
      } else {
        // Fallback: try bundled assets (for initial app or if download fails)
        // Native code will resolve this to the actual bundle path
        return "assets/models";
      }
    } else {
      // Android: single ONNX file
      const modelName = 'stable_diffusion.onnx';
      const modelPath = `${FileSystem.documentDirectory}models/${modelName}`;
      
      const fileInfo = await FileSystem.getInfoAsync(modelPath);
      if (fileInfo.exists) {
        return modelPath;
      }
      
      throw new Error(
        `Android model not found. Please download models first.`
      );
    }
  } catch (error: any) {
    throw new Error(
      `Failed to get model path: ${error.message}. Please ensure models are downloaded or bundled.`
    );
  }
}

/**
 * Fallback JavaScript-based image generation
 * This is slower but works without native modules
 * Uses a simplified approach for demonstration
 */
async function generateImageFallback(
  prompt: string,
  options: GenerationOptions
): Promise<string> {
  // This is a placeholder implementation
  // In a real scenario, you would:
  // 1. Use a WebAssembly-based model runner
  // 2. Or use a simpler generative approach
  // 3. Or prompt the user to use native builds for better performance
  
  console.warn(
    'Using fallback image generation. For best performance, use a development build with native modules.'
  );

  // For now, return a placeholder
  // In production, you should implement a proper fallback or require native modules
  throw new Error(
    'Native image generation module required. Please build the app with expo-dev-client for on-device inference.'
  );
}

/**
 * Check if local image generation is available
 */
export async function isLocalGenerationAvailable(): Promise<boolean> {
  // Debug logging
  console.log('🔍 Checking local generation availability...');
  console.log('🔍 ImageGenerationModuleNative:', ImageGenerationModuleNative);
  console.log('🔍 NativeImageGen:', NativeImageGen);
  
  // First check if the native module exists at all
  if (!ImageGenerationModuleNative) {
    console.log('❌ ImageGenerationModuleNative is null - module not registered');
    return false;
  }
  
  // Module exists, check if wrapper is set up
  if (!NativeImageGen) {
    console.log('❌ NativeImageGen wrapper is null');
    return false;
  }
  
  // Module is available - try to call a method to verify it works
  try {
    // Just check if we can call the method - don't care about the result
    await NativeImageGen.isModelLoaded();
    console.log('✅ Native module is available and working');
    return true;
  } catch (error: any) {
    // If we get here, module exists but there's an error
    // This could be a registration issue or the method doesn't exist
    console.log('⚠️ Native module exists but error calling method:', error?.message || error);
    // Still return true if module exists - the error might be expected (e.g., model not loaded)
    return true;
  }
}

/**
 * Preload the ML model for faster generation
 */
export async function preloadModel(): Promise<boolean> {
  if (!NativeImageGen) {
    return false;
  }

  try {
    const isLoaded = await NativeImageGen.isModelLoaded();
    if (isLoaded) {
      console.log('✅ Models already loaded');
      return true;
    }

    const modelPath = await getModelPath();
    console.log('📦 Loading models from:', modelPath);
    const result = await NativeImageGen.loadModel(modelPath);
    console.log('✅ Model loading result:', result);
    return result;
  } catch (error) {
    console.error('❌ Failed to preload model:', error);
    return false;
  }
}

/**
 * Test model loading and return detailed status
 */
export async function testModelLoading(): Promise<{
  success: boolean;
  message: string;
  models?: Record<string, boolean>;
}> {
  if (!NativeImageGen) {
    return {
      success: false,
      message: 'Native module not available. Please use a development build.',
    };
  }

  try {
    const modelPath = await getModelPath();
    console.log('🧪 Testing model loading from:', modelPath);
    
    const result = await NativeImageGen.loadModel(modelPath);
    
    if (typeof result === 'object' && result !== null) {
      return {
        success: result.success === true,
        message: result.message || 'Models loaded',
        models: result.models,
      };
    }
    
    return {
      success: result === true,
      message: result ? 'Models loaded successfully' : 'Failed to load models',
    };
  } catch (error: any) {
    return {
      success: false,
      message: error.message || 'Failed to load models',
    };
  }
}
