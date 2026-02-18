/**
 * S3 Model Download Service
 * 
 * Handles downloading Core ML models from AWS S3.
 * Since .mlmodelc files are directories, this service handles downloading
 * them as tar.gz archives or individual files.
 */

import * as FileSystem from 'expo-file-system';
import { Platform } from 'react-native';

const S3_BASE_URL = 'https://image-gen-pd123.s3.eu-north-1.amazonaws.com/stable-diffusion';
// Cache-busting version. Update this when you update files in S3 to force clients to download new files.
// You can also set EXPO_PUBLIC_MODEL_VERSION environment variable to override this.
// Format: Use a version number (e.g., "2") or timestamp (e.g., "20240218") - bump it when files change.
const MODEL_VERSION = process.env.EXPO_PUBLIC_MODEL_VERSION || '1';

function buildVersionedUrl(path: string): string {
  const base = `${S3_BASE_URL}/${path}`;
  const separator = base.includes('?') ? '&' : '?';
  return `${base}${separator}v=${encodeURIComponent(MODEL_VERSION)}`;
}

export interface DownloadProgress {
  loaded: number;
  total: number;
  percentage: number;
}

/**
 * Download a file from S3
 */
export async function downloadFromS3(
  s3Path: string,
  localPath: string,
  onProgress?: (progress: DownloadProgress) => void
): Promise<string> {
  const url = buildVersionedUrl(s3Path);
  
  console.log(`📥 Downloading from S3: ${url}`);
  
  const downloadResumable = FileSystem.createDownloadResumable(
    url,
    localPath,
    {},
    (downloadProgress) => {
      const progress: DownloadProgress = {
        loaded: downloadProgress.totalBytesWritten,
        total: downloadProgress.totalBytesExpectedToWrite || 0,
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
    throw new Error(`Download failed for ${s3Path}`);
  }
  
  return result.uri;
}

/**
 * Download .mlmodelc directory from S3
 * 
 * Since .mlmodelc is a directory, S3 may serve it as:
 * 1. A tar.gz archive (if you uploaded it that way)
 * 2. Individual files (if you use S3 sync)
 * 
 * This function tries to download as a directory structure.
 */
export async function downloadModelDirectory(
  modelName: string,
  localDir: string,
  onProgress?: (progress: DownloadProgress) => void
): Promise<string> {
  // Ensure local directory exists
  const dirInfo = await FileSystem.getInfoAsync(localDir);
  if (!dirInfo.exists) {
    await FileSystem.makeDirectoryAsync(localDir, { intermediates: true });
  }
  
  // Try downloading the directory
  // Option 1: If S3 serves it as a tar.gz
  const tarUrl = `${S3_BASE_URL}/${modelName}.tar.gz`;
  const tarPath = `${localDir}.tar.gz`;
  
  try {
    // Try downloading as tar.gz first
    await downloadFromS3(`${modelName}.tar.gz`, tarPath, onProgress);
    
    // Note: expo-file-system doesn't extract archives
    // You would need react-native-zip-archive or similar
    // For now, we'll assume the files are served directly
    
    console.log(`✅ Downloaded ${modelName}.tar.gz`);
    return tarPath;
  } catch (error) {
    // If tar.gz doesn't exist, try downloading directory directly
    console.log(`⚠️  ${modelName}.tar.gz not found, trying direct download...`);
    
    // For .mlmodelc directories, we need to download the manifest and files
    // This is complex - for now, assume files are uploaded as individual downloads
    // or use a different method
    
    throw new Error(`Directory download not fully implemented. Please ensure ${modelName} is available as a downloadable file or archive.`);
  }
}

/**
 * Check if a file exists in S3 (by trying to download headers)
 */
export async function checkS3FileExists(s3Path: string): Promise<boolean> {
  try {
    const url = buildVersionedUrl(s3Path);
    const response = await fetch(url, { method: 'HEAD' });
    return response.ok;
  } catch {
    return false;
  }
}
