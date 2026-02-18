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

// Optional cache-busting version. Bump EXPO_PUBLIC_MODEL_VERSION when you update files in S3.
const MODEL_VERSION = process.env.EXPO_PUBLIC_MODEL_VERSION;

function withVersion(url: string): string {
  if (!MODEL_VERSION) {
    return url;
  }
  const separator = url.includes('?') ? '&' : '?';
  return `${url}${separator}v=${encodeURIComponent(MODEL_VERSION)}`;
}

// Model components to download
// IMPORTANT: .mlmodelc files are directories. S3 cannot serve directories directly.
// You MUST upload them as tar.gz archives to S3, then download and extract them.
// 
// To upload: tar -czf TextEncoder.mlmodelc.tar.gz TextEncoder.mlmodelc/
// Then upload the .tar.gz file to S3
const MODEL_COMPONENTS: ModelDownloadInfo[] = [
  {
    name: 'TextEncoder.mlmodelc',
    // Try tar.gz first, fallback to directory (won't work but shows better error)
    url: withVersion(`${MODEL_BASE_URL}/TextEncoder.mlmodelc.tar.gz`),
    size: 234.9 * 1024 * 1024, // 234.9 MB (uncompressed)
    required: true,
  },
  {
    name: 'UnetChunk1.mlmodelc',
    url: withVersion(`${MODEL_BASE_URL}/UnetChunk1.mlmodelc.tar.gz`),
    size: 846.9 * 1024 * 1024, // 846.9 MB (uncompressed)
    required: true,
  },
  {
    name: 'UnetChunk2.mlmodelc',
    url: withVersion(`${MODEL_BASE_URL}/UnetChunk2.mlmodelc.tar.gz`),
    size: 793.6 * 1024 * 1024, // 793.6 MB (uncompressed)
    required: true,
  },
  {
    name: 'VAEDecoder.mlmodelc',
    url: withVersion(`${MODEL_BASE_URL}/VAEDecoder.mlmodelc.tar.gz`),
    size: 94.6 * 1024 * 1024, // 94.6 MB (uncompressed)
    required: true,
  },
  {
    name: 'SafetyChecker.mlmodelc',
    url: withVersion(`${MODEL_BASE_URL}/SafetyChecker.mlmodelc.tar.gz`),
    size: 580.2 * 1024 * 1024, // 580.2 MB (uncompressed)
    required: false,
  },
  {
    name: 'vocab.json',
    url: withVersion(`${MODEL_BASE_URL}/vocab.json`),
    size: 842.1 * 1024, // 842.1 KB
    required: true,
  },
  {
    name: 'merges.txt',
    url: withVersion(`${MODEL_BASE_URL}/merges.txt`),
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
 * Check if all required models are cached OR available in bundle
 * 
 * This function checks both bundle and Documents directory for each model.
 * Returns true only if ALL required models are found in either location.
 */
export async function areAllModelsCached(): Promise<boolean> {
  const requiredModels = MODEL_COMPONENTS.filter(m => m.required);
  
  for (const model of requiredModels) {
    const location = await checkModelLocation(model.name);
    if (location === 'none') {
      // Model not found in bundle or Documents - needs download
      return false;
    }
  }
  
  // All models found in either bundle or Documents
  return true;
}

/**
 * Check where a model is located: 'bundle', 'documents', or 'none'
 * Uses native module to check bundle (which JS can't access directly)
 */
async function checkModelLocation(modelName: string): Promise<'bundle' | 'documents' | 'none'> {
  try {
    // Try to use native module to check bundle
    const { ImageGenerationModuleNative } = require('./native/ImageGenerationModule');
    if (ImageGenerationModuleNative && ImageGenerationModuleNative.checkModelLocation) {
      const location = await ImageGenerationModuleNative.checkModelLocation(modelName);
      console.log(`📍 ${modelName} location: ${location}`);
      return location;
    } else {
      console.log(`⚠️ Native module or checkModelLocation method not available for ${modelName}`);
    }
  } catch (error: any) {
    console.log(`❌ Error checking location for ${modelName}:`, error?.message || error);
  }
  
  // Fallback: only check Documents (can't check bundle from JS)
  const isCached = await isModelCached(modelName);
  const fallbackLocation = isCached ? 'documents' : 'none';
  console.log(`📍 ${modelName} fallback location: ${fallbackLocation}`);
  return fallbackLocation;
}

/**
 * Get list of models that need to be downloaded
 * Returns models that are neither in bundle nor in Documents
 */
export async function getModelsToDownload(): Promise<ModelDownloadInfo[]> {
  const requiredModels = MODEL_COMPONENTS.filter(m => m.required);
  const modelsToDownload: ModelDownloadInfo[] = [];
  
  for (const model of requiredModels) {
    const location = await checkModelLocation(model.name);
    if (location === 'none') {
      // Model not found in bundle or Documents - needs download
      modelsToDownload.push(model);
    } else {
      console.log(`✓ ${model.name} found in ${location}, skipping download`);
    }
  }
  
  return modelsToDownload;
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
    console.log(`📥 Downloading ${modelInfo.name} from S3...`);
    console.log(`   URL: ${modelInfo.url}`);
    console.log(`   Expected size: ${(modelInfo.size / 1024 / 1024).toFixed(2)} MB`);
    
    // Start download with progress tracking
    const downloadResumable = FileSystem.createDownloadResumable(
      modelInfo.url,
      tempPath,
      {},
      (downloadProgress) => {
        const loaded = downloadProgress.totalBytesWritten || 0;
        const expectedTotal = downloadProgress.totalBytesExpectedToWrite;
        
        // Use expected total if valid, otherwise use model info size, otherwise calculate from loaded
        let total = modelInfo.size;
        if (expectedTotal && expectedTotal > 0) {
          total = expectedTotal;
        } else if (total <= 0) {
          // If we don't know the total, estimate based on loaded bytes (assume we're at least 1% done)
          total = Math.max(loaded * 100, modelInfo.size);
        }
        
        // Calculate percentage safely
        let percentage = 0;
        if (total > 0 && loaded > 0) {
          percentage = Math.min((loaded / total) * 100, 100);
        } else if (loaded > 0) {
          // If we have loaded bytes but no total, show indeterminate progress
          percentage = Math.min((loaded / modelInfo.size) * 100, 99); // Cap at 99% if total unknown
        }
        
        const progress: DownloadProgress = {
          loaded: loaded,
          total: total,
          percentage: percentage,
        };
        
        // Log progress every 10% or when we have meaningful data
        if (percentage > 0 && (Math.floor(percentage) % 10 === 0 || loaded > 0)) {
          const loadedMB = (loaded / 1024 / 1024).toFixed(1);
          const totalMB = total > 0 ? (total / 1024 / 1024).toFixed(1) : '?';
          if (total > 0) {
            console.log(`   ${modelInfo.name}: ${percentage.toFixed(1)}% (${loadedMB}MB / ${totalMB}MB)`);
          } else {
            console.log(`   ${modelInfo.name}: ${loadedMB}MB downloaded (total size unknown)`);
          }
        }
        
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
    
    // Verify file size is reasonable (not 0 or suspiciously small)
    const fileSize = tempInfo.size || 0;
    console.log(`   Downloaded: ${(fileSize / 1024 / 1024).toFixed(2)} MB`);
    
    // Check if it's an HTML error page or directory listing (common S3 issue)
    if (fileSize > 0 && fileSize < 10000) {
      try {
        const content = await FileSystem.readAsStringAsync(tempPath, { 
          encoding: FileSystem.EncodingType.UTF8, 
          length: 1000 
        });
        if (content.includes('<html') || content.includes('<HTML') || content.includes('<?xml') || content.includes('ListBucketResult')) {
          throw new Error(
            `S3 returned HTML/XML instead of file. This usually means:\n` +
            `1. The URL points to a directory (${modelInfo.name} is a directory, not a file)\n` +
            `2. S3 is serving a directory listing or error page\n` +
            `3. Solution: Upload ${modelInfo.name} as a tar.gz archive to S3\n` +
            `   URL tried: ${modelInfo.url}`
          );
        }
      } catch (readError: any) {
        // If error is our custom error, re-throw it
        if (readError.message && readError.message.includes('S3 returned HTML')) {
          throw readError;
        }
        // Otherwise, it might be binary data which is fine
      }
    }
    
    if (fileSize === 0 && modelInfo.size > 1024) {
      throw new Error(
        `Downloaded file is 0 bytes but expected ${(modelInfo.size / 1024 / 1024).toFixed(2)} MB.\n` +
        `This usually means:\n` +
        `1. The file doesn't exist at: ${modelInfo.url}\n` +
        `2. Or ${modelInfo.name} is a directory and needs to be uploaded as tar.gz\n` +
        `3. Check S3 bucket and upload files correctly`
      );
    }
    
    // Warn if file size is much smaller than expected
    if (fileSize > 0 && modelInfo.size > 0 && fileSize < modelInfo.size * 0.1) {
      console.warn(`⚠️ Warning: Downloaded file is much smaller than expected. Expected: ${(modelInfo.size / 1024 / 1024).toFixed(2)} MB, Got: ${(fileSize / 1024 / 1024).toFixed(2)} MB`);
    }
    
    // Handle .mlmodelc directories (downloaded as tar.gz)
    if (modelInfo.name.endsWith('.mlmodelc')) {
      // Check if we downloaded a tar.gz file
      const isTarGz = tempPath.endsWith('.tar.gz') || modelInfo.url.endsWith('.tar.gz');
      
      if (isTarGz) {
        // We downloaded a tar.gz archive - need to extract it
        console.log(`   📦 ${modelInfo.name} downloaded as tar.gz archive, extracting...`);
        
        // Move tar.gz to final location (with .tar.gz extension) first
        const tarGzPath = `${downloadPath}.tar.gz`;
        await FileSystem.moveAsync({
          from: tempPath,
          to: tarGzPath,
        });
        
        // Extract using native module
        try {
          const { ImageGenerationModuleNative } = require('./native/ImageGenerationModule');
          if (ImageGenerationModuleNative && ImageGenerationModuleNative.extractTarGz) {
            const extractedPath = await ImageGenerationModuleNative.extractTarGz(tarGzPath);
            console.log(`   ✅ Extracted ${modelInfo.name} to: ${extractedPath}`);
            
            // Verify extraction
            const extractedInfo = await FileSystem.getInfoAsync(extractedPath);
            if (extractedInfo.exists && extractedInfo.isDirectory) {
              // Optionally remove tar.gz file to save space
              // await FileSystem.deleteAsync(tarGzPath, { idempotent: true });
              console.log(`   ✅ Extraction verified: ${extractedPath}`);
            } else {
              throw new Error(`Extraction failed: ${extractedPath} does not exist or is not a directory`);
            }
          } else {
            throw new Error('Native extractTarGz method not available');
          }
        } catch (extractError: any) {
          console.error(`   ❌ Extraction error: ${extractError.message}`);
          throw new Error(
            `Failed to extract ${modelInfo.name}: ${extractError.message}\n` +
            `The tar.gz file is saved at: ${tarGzPath}`
          );
        }
      } else {
        // Not tar.gz - try to move as-is (might be directory or file)
        await FileSystem.moveAsync({
          from: tempPath,
          to: downloadPath,
        });
      }
    } else {
      // Regular file (vocab.json, merges.txt)
      await FileSystem.moveAsync({
        from: tempPath,
        to: downloadPath,
      });
    }
    
    // Verify final file
    const finalInfo = await FileSystem.getInfoAsync(downloadPath);
    if (finalInfo.exists) {
      const finalSize = finalInfo.size || 0;
      console.log(`✅ Downloaded ${modelInfo.name}`);
      console.log(`   Path: ${downloadPath}`);
      console.log(`   Size: ${(finalSize / 1024 / 1024).toFixed(2)} MB`);
      console.log(`   Type: ${finalInfo.isDirectory ? 'Directory' : 'File'}`);
      
      // Final verification - file should have content
      if (finalSize === 0 && modelInfo.size > 1024) {
        throw new Error(`Downloaded file ${modelInfo.name} is 0 bytes. The file may not exist at URL: ${modelInfo.url}`);
      }
    } else {
      throw new Error(`Final file not found at ${downloadPath} after download`);
    }
    
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
 * Only downloads models that are neither in bundle nor in Documents directory
 * 
 * Logic:
 * 1. Check each required model location (bundle, documents, or none)
 * 2. Only download models that are "none" (not in bundle and not in documents)
 * 3. After download, models will be loaded from bundle first, then documents
 */
export async function downloadAllModels(
  onProgress?: (overallProgress: { currentModel: string; overallPercentage: number; loaded: number; total: number }) => void
): Promise<void> {
  // Get list of models that need downloading (not in bundle or documents)
  const modelsToDownload = await getModelsToDownload();
  
  if (modelsToDownload.length === 0) {
    console.log('✅ All required models are available in bundle or Documents directory - no download needed');
    return;
  }
  
  // Calculate total size
  const totalSize = modelsToDownload.reduce((sum, m) => sum + m.size, 0);
  
  console.log(`📦 Downloading ${modelsToDownload.length} missing models (${(totalSize / 1024 / 1024 / 1024).toFixed(2)} GB)...`);
  console.log(`   Models to download: ${modelsToDownload.map(m => m.name).join(', ')}`);
  
  let totalDownloaded = 0;
  
  for (let i = 0; i < modelsToDownload.length; i++) {
    const model = modelsToDownload[i];
    
    try {
      console.log(`📥 Starting download: ${model.name} (${(model.size / 1024 / 1024).toFixed(2)} MB)`);
      const downloadedPath = await downloadModel(model, (progress) => {
        if (onProgress) {
          // Calculate overall progress across all files
          // Progress = (files completed + current file progress) / total files
          const currentFileProgress = (progress.loaded / model.size) * model.size; // Bytes downloaded for current file
          const overallLoaded = totalDownloaded + progress.loaded;
          const overallPercentage = totalSize > 0 
            ? Math.min(100, Math.max(0, (overallLoaded / totalSize) * 100))
            : 0;
          
          onProgress({
            currentModel: model.name,
            overallPercentage: overallPercentage,
            loaded: overallLoaded,
            total: totalSize
          });
        }
      });
      
      // Update total downloaded after file completes
      totalDownloaded += model.size;
      
      // Send final progress for this file (100% of this file)
      if (onProgress) {
        const overallPercentage = totalSize > 0 
          ? Math.min(100, Math.max(0, (totalDownloaded / totalSize) * 100))
          : 0;
        onProgress({
          currentModel: model.name,
          overallPercentage: overallPercentage,
          loaded: totalDownloaded,
          total: totalSize
        });
      }
      
      console.log(`✅ Completed: ${model.name} -> ${downloadedPath}`);
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
