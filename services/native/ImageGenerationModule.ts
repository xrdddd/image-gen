/**
 * TypeScript interface for native ImageGenerationModule
 */

import { NativeModules, Platform } from 'react-native';

interface ImageGenerationModuleInterface {
  loadModel(modelPath: string): Promise<boolean | { success: boolean; message: string; models?: Record<string, boolean> }>;
  isModelLoaded(): Promise<boolean>;
  generateImage(
    prompt: string,
    steps: number,
    guidanceScale: number,
    seed: number,
    width: number,
    height: number
  ): Promise<string>; // Returns base64 string
  checkModelLocation(modelName: string): Promise<'bundle' | 'documents' | 'none'>;
}

// Get the native module
const { ImageGenerationModule } = NativeModules;

// Debug: Log available modules
if (__DEV__) {
  console.log('🔍 Available native modules:', Object.keys(NativeModules));
  console.log('🔍 ImageGenerationModule:', ImageGenerationModule);
  console.log('🔍 Platform:', Platform.OS);
}

export const ImageGenerationModuleNative: ImageGenerationModuleInterface | null =
  Platform.OS === 'ios' && ImageGenerationModule
    ? ImageGenerationModule
    : null;
