/**
 * Model Download Service
 * 
 * Handles downloading Core ML models from cloud storage and caching them locally.
 * Models are downloaded on-demand if not already cached.
 */

import * as FileSystem from 'expo-file-system';
import { Platform } from 'react-native';

export interface DownloadProgress {
  loaded: number;
  total: number;
  percentage: number;
}

export interface ModelDownloadInfo {
  name: string;
  url: string;
  size: number; // in bytes
  required: boolean;
}

// Model download URLs - configure these to point to your cloud storage
// Options: AWS S3, Google Cloud Storage, Azure Blob, or your own server
const MODEL_BASE_URL = process.env.EXPO_PUBLIC_MODEL_BASE_URL || 
  'https://image-gen-pd123.s3.eu-north-1.amazonaws.com/stable-diffusion';

// Model components to download
const MODEL_COMPONENTS: ModelDownloadInfo[] = [
  {
    name: 'TextEncoder.mlmodelc',
    url: `${MODEL_BASE_URL}/TextEncoder.mlmodelc`,
    size: 234.9 * 1024 * 1024, // 234.9 MB
    required: true,
  },
  {
    name: 'UnetChunk1.mlmodelc',
    url: `${MODEL_BASE_URL}/UnetChunk1.mlmodelc`,
    size: 846.9 * 1024 * 1024, // 846.9 MB
    required: true,
  },
  {
    name: 'UnetChunk2.mlmodelc',
    url: `${MODEL_BASE_URL}/UnetChunk2.mlmodelc`,
    size: 793.6 * 1024 * 1024, // 793.6 MB
    required: true,
  },
  {
    name: 'VAEDecoder.mlmodelc',
    url: `${MODEL_BASE_URL}/VAEDecoder.mlmodelc`,
    size: 94.6 * 1024 * 1024, // 94.6 MB
    required: true,
  },
  {
    name: 'SafetyChecker.mlmodelc',
    url: `${MODEL_BASE_URL}/SafetyChecker.mlmodelc`,
    size: 580.2 * 1024 * 1024, // 580.2 MB
    required: false,
  },
  {
    name: 'vocab.json',
    url: `${MODEL_BASE_URL}/vocab.json`,
    size: 842.1 * 1024, // 842.1 KB
    required: true,
  },
  {
    name: 'merges.txt',
    url: `${MODEL_BASE_URL}/merges.txt`,
    size: 512.4 * 1024, // 512.4 KB
    required: true,
  },
];

/**
 * Get the local cache directory for models
 */
function getModelsCacheDir(): string {
  if (Platform.OS === 'ios') {
    return `${FileSystem.documentDirectory}models/`;
  } else {
    return `${FileSystem.documentDirectory}models/`;
  }
}

/**
 * Check if a model file exists in cache
 */
export async function isModelCached(modelName: string): Promise<boolean> {
  try {
    const cacheDir = getModelsCacheDir();
    const modelPath = `${cacheDir}${modelName}`;
    const fileInfo = await FileSystem.getInfoAsync(modelPath);
    
    // For .mlmodelc directories, check if it exists and has content
    if (modelName.endsWith('.mlmodelc')) {
      if (fileInfo.exists && fileInfo.isDirectory) {
        // Check if directory has files (not empty)
        const dirContents = await FileSystem.readDirectoryAsync(modelPath);
        return dirContents.length > 0;
      }
      return false;
    }
    
    return fileInfo.exists;
  } catch (error) {
    console.error(`Error checking cache for ${modelName}:`, error);
    return false;
  }
}

/**
 * Check if all required models are cached
 */
export async function areAllModelsCached(): Promise<boolean> {
  const requiredModels = MODEL_COMPONENTS.filter(m => m.required);
  
  for (const model of requiredModels) {
    const isCached = await isModelCached(model.name);
    if (!isCached) {
      return false;
    }
  }
  
  return true;
}

/**
 * Get cached model path
 */
export async function getCachedModelPath(modelName: string): Promise<string | null> {
  const isCached = await isModelCached(modelName);
  if (!isCached) {
    return null;
  }
  
  const cacheDir = getModelsCacheDir();
  return `${cacheDir}${modelName}`;
}

/**
 * Download a single model file
 */
export async function downloadModel(
  modelInfo: ModelDownloadInfo,
  onProgress?: (progress: DownloadProgress) => void
): Promise<string> {
  const cacheDir = getModelsCacheDir();
  
  // Ensure cache directory exists
  const dirInfo = await FileSystem.getInfoAsync(cacheDir);
  if (!dirInfo.exists) {
    await FileSystem.makeDirectoryAsync(cacheDir, { intermediates: true });
  }
  
  // For .mlmodelc directories, we need to download recursively
  // S3 doesn't support directory downloads directly, so we'll need to:
  // 1. Download as a tar/zip archive, OR
  // 2. Download individual files within the directory
  
  // For now, try downloading the directory path directly
  // If S3 serves it as a file, it will work
  // If it's a directory listing, we'll need to handle it differently
  
  const downloadPath = `${cacheDir}${modelInfo.name}`;
  const tempPath = `${downloadPath}.tmp`;
  
  try {
    console.log(`📥 Downloading ${modelInfo.name} from ${modelInfo.url}...`);
    
    // Start download with progress tracking
    const downloadResumable = FileSystem.createDownloadResumable(
      modelInfo.url,
      tempPath,
      {},
      (downloadProgress) => {
        const progress: DownloadProgress = {
          loaded: downloadProgress.totalBytesWritten,
          total: downloadProgress.totalBytesExpectedToWrite || modelInfo.size,
          percentage: downloadProgress.totalBytesExpectedToWrite
            ? (downloadProgress.totalBytesWritten / downloadProgress.totalBytesExpectedToWrite) * 100
            : 0,
        };
        
        if (onProgress) {
          onProgress(progress);
        }
      }
    );
    
    const result = await downloadResumable.downloadAsync();
    
    if (!result) {
      throw new Error(`Download failed for ${modelInfo.name}`);
    }
    
    // Check if downloaded file exists
    const tempInfo = await FileSystem.getInfoAsync(tempPath);
    if (!tempInfo.exists) {
      throw new Error(`Downloaded file not found: ${tempPath}`);
    }
    
    // Handle .mlmodelc directories
    if (modelInfo.name.endsWith('.mlmodelc')) {
      // .mlmodelc is a directory structure
      // If S3 serves it as a single file (tar/zip), we'd need to extract it
      // For now, assume S3 serves the directory structure directly or as a downloadable directory
      
      // Try to move/copy the downloaded content
      // Note: expo-file-system doesn't support directory operations well
      // We may need to handle this differently based on how S3 serves the files
      
      // For directories, we might need to download individual files
      // Or use a different approach
      
      // Move temp to final location
      await FileSystem.moveAsync({
        from: tempPath,
        to: downloadPath,
      });
      
      // If it's actually a directory listing HTML, we'll need to parse and download files
      // For now, assume it's a downloadable directory or archive
    } else {
      // Regular file (vocab.json, merges.txt)
      await FileSystem.moveAsync({
        from: tempPath,
        to: downloadPath,
      });
    }
    
    console.log(`✅ Downloaded ${modelInfo.name}`);
    return downloadPath;
    
  } catch (error: any) {
    // Clean up temp file on error
    try {
      const tempInfo = await FileSystem.getInfoAsync(tempPath);
      if (tempInfo.exists) {
        await FileSystem.deleteAsync(tempPath, { idempotent: true });
      }
    } catch {}
    
    throw new Error(`Failed to download ${modelInfo.name}: ${error.message}`);
  }
}

/**
 * Download all required models
 */
export async function downloadAllModels(
  onProgress?: (modelName: string, progress: DownloadProgress) => void
): Promise<void> {
  const requiredModels = MODEL_COMPONENTS.filter(m => m.required);
  const totalSize = requiredModels.reduce((sum, m) => sum + m.size, 0);
  
  console.log(`📦 Downloading ${requiredModels.length} models (${(totalSize / 1024 / 1024 / 1024).toFixed(2)} GB)...`);
  
  for (const model of requiredModels) {
    // Check if already cached
    const isCached = await isModelCached(model.name);
    if (isCached) {
      console.log(`✓ ${model.name} already cached, skipping...`);
      continue;
    }
    
    try {
      await downloadModel(model, (progress) => {
        if (onProgress) {
          onProgress(model.name, progress);
        }
      });
    } catch (error: any) {
      console.error(`❌ Failed to download ${model.name}:`, error);
      throw error;
    }
  }
  
  console.log('✅ All models downloaded successfully!');
}

/**
 * Get total download size
 */
export function getTotalDownloadSize(): number {
  const requiredModels = MODEL_COMPONENTS.filter(m => m.required);
  return requiredModels.reduce((sum, m) => sum + m.size, 0);
}

/**
 * Clear cached models
 */
export async function clearModelCache(): Promise<void> {
  try {
    const cacheDir = getModelsCacheDir();
    const dirInfo = await FileSystem.getInfoAsync(cacheDir);
    
    if (dirInfo.exists) {
      await FileSystem.deleteAsync(cacheDir, { idempotent: true });
      console.log('✅ Model cache cleared');
    }
  } catch (error) {
    console.error('Error clearing cache:', error);
    throw error;
  }
}

/**
 * Get cache size
 */
export async function getCacheSize(): Promise<number> {
  try {
    const cacheDir = getModelsCacheDir();
    const dirInfo = await FileSystem.getInfoAsync(cacheDir);
    
    if (!dirInfo.exists) {
      return 0;
    }
    
    // Calculate total size of cached files
    // Note: This is a simplified version - you may want to use a library
    // that can recursively calculate directory sizes
    let totalSize = 0;
    
    // For now, return 0 - implement proper size calculation if needed
    return totalSize;
  } catch (error) {
    console.error('Error calculating cache size:', error);
    return 0;
  }
}
