import React, { useState } from 'react';
import {
  StyleSheet,
  View,
  TextInput,
  TouchableOpacity,
  Text,
  ScrollView,
  ActivityIndicator,
  Alert,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { Image } from 'expo-image';
import { LinearGradient } from 'expo-linear-gradient';
import { generateImageLocal, isLocalGenerationAvailable, preloadModel, testModelLoading } from './services/localImageGenerationService';
import { 
  areAllModelsCached, 
  downloadAllModels, 
  getTotalDownloadSize,
  clearModelCache 
} from './services/modelDownloadService';

export default function App() {
  const [prompt, setPrompt] = useState('');
  const [generatedImage, setGeneratedImage] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [localAvailable, setLocalAvailable] = useState(false);
  const [modelLoading, setModelLoading] = useState(false);
  const [modelStatus, setModelStatus] = useState<string>('');
  const [downloading, setDownloading] = useState(false);
  const [downloadProgress, setDownloadProgress] = useState<{currentModel: string; overallPercentage: number; loaded: number; total: number} | null>(null);
  const [generationProgress, setGenerationProgress] = useState<{step: number; totalSteps: number; progress: number; elapsed: number} | null>(null);

  // Check if local generation is available on mount
  React.useEffect(() => {
    checkLocalAvailability();
  }, []);

  // Auto-download models on startup if not cached
  React.useEffect(() => {
    autoDownloadModels();
  }, [localAvailable]); // Re-run when localAvailable changes

  const autoDownloadModels = async () => {
    try {
      // Wait a bit for app to initialize
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      if (!localAvailable) {
        console.log('⚠️ Native module not available, skipping auto-download');
        return;
      }
      
      // Check which models need downloading (not in bundle or documents)
      const { getModelsToDownload } = require('./services/modelDownloadService');
      const modelsToDownload = await getModelsToDownload();
      
      if (modelsToDownload.length === 0) {
        // All models available in bundle or documents - try to load them
        console.log('✅ All models available in bundle or Documents directory');
        try {
          const loaded = await preloadModel();
          if (loaded) {
            setModelStatus('Model is ready.');
            console.log('✅ Models loaded successfully');
          } else {
            setModelStatus('⚠️ Models found but failed to load');
          }
        } catch (error) {
          console.log('Error loading models:', error);
          setModelStatus('⚠️ Error loading models');
        }
        return;
      }
      
      // Some models are missing - auto-download them
      console.log(`📥 ${modelsToDownload.length} models need downloading: ${modelsToDownload.map((m: { name: string }) => m.name).join(', ')}`);
      setModelStatus(`Preparing to download ${modelsToDownload.length} missing models...`);
      
      // Start download automatically
      await handleDownloadModelsAuto();
    } catch (error) {
      console.log('Error in auto-download:', error);
    }
  };

  const handleDownloadModelsAuto = async () => {
    if (downloading) return;
    
    setDownloading(true);
    setModelStatus('Starting automatic download...');
    
    try {
      const totalSize = getTotalDownloadSize();
      const sizeGB = (totalSize / 1024 / 1024 / 1024).toFixed(2);
      
      console.log(`📦 Starting download of ${sizeGB} GB models...`);
      
      await downloadAllModels((overallProgress) => {
        setDownloadProgress(overallProgress);
        
        const loadedGB = (overallProgress.loaded / 1024 / 1024 / 1024).toFixed(2);
        const totalGB = (overallProgress.total / 1024 / 1024 / 1024).toFixed(2);
        
        // Don't set modelStatus during download - only show progress bar
        console.log(`📥 Downloading: ${overallProgress.overallPercentage.toFixed(1)}% (${loadedGB}GB / ${totalGB}GB)`);
      });
      
      setModelStatus('✅ Download complete! Loading models...');
      setDownloadProgress(null);
      console.log('✅ All models downloaded successfully');
      
      // Reload models after download
      await checkLocalAvailability();
    } catch (error: any) {
      console.error('❌ Download error:', error);
      setModelStatus(`❌ Download failed: ${error.message}`);
      Alert.alert(
        'Download Error', 
        `Failed to download models:\n\n${error.message}\n\nPlease check your internet connection.`
      );
    } finally {
      setDownloading(false);
    }
  };

  const checkLocalAvailability = async () => {
    try {
      setModelLoading(true);
      const available = await isLocalGenerationAvailable();
      setLocalAvailable(available);
      
      if (!available) {
        setModelStatus('Native module not available');
        setModelLoading(false);
        return;
      }
      
      // Try to load models from bundle or cache first
      // This checks bundle first (via native module), then cache
      try {
        const loaded = await preloadModel();
        if (loaded) {
          setModelStatus('✅ Model loaded.');
          setModelLoading(false);
          return; // Models loaded successfully
        }
      } catch (error: any) {
        console.log('Models not loaded from bundle/cache:', error?.message || error);
      }
      
      // If models couldn't be loaded, check if they're in Documents cache
      const allCached = await areAllModelsCached();
      
      if (!allCached) {
        // Models not in bundle and not in cache - need to download
        setModelStatus('Models not found in bundle or cache. Ready to download.');
        setModelLoading(false);
        // Don't auto-download - let user decide when to download
        return;
      }
      
      // Models are cached in Documents, try to load them
      setModelLoading(true);
      setModelStatus('Loading models...');
      
      const testResult = await testModelLoading();
      if (testResult.success) {
        setModelStatus(`✅ Models loaded: ${Object.keys(testResult.models || {}).filter(k => testResult.models?.[k]).length} components`);
      } else {
        setModelStatus(`⚠️ ${testResult.message}`);
      }
      
      setModelLoading(false);
    } catch (err: any) {
      console.log('Local generation not available:', err);
      setLocalAvailable(false);
      setModelStatus(`❌ ${err.message || 'Not available'}`);
    }
  };

  const handleDownloadModels = async () => {
    if (downloading) return;
    
    setDownloading(true);
    setModelStatus('Preparing download...');
    
    try {
      const totalSize = getTotalDownloadSize();
      const sizeGB = (totalSize / 1024 / 1024 / 1024).toFixed(2);
      
      Alert.alert(
        'Download Models',
        `Download ${sizeGB} GB of models?\n\nThis may take a while depending on your connection.`,
        [
          { text: 'Cancel', style: 'cancel', onPress: () => setDownloading(false) },
          {
            text: 'Download',
            onPress: async () => {
              try {
                setModelStatus('Starting download...');
                
                await downloadAllModels((overallProgress) => {
                  setDownloadProgress(overallProgress);
                  
                  const loadedGB = (overallProgress.loaded / 1024 / 1024 / 1024).toFixed(2);
                  const totalGB = (overallProgress.total / 1024 / 1024 / 1024).toFixed(2);
                  
                  // Don't set modelStatus during download - only show progress bar
                  console.log(`📥 Downloading: ${overallProgress.overallPercentage.toFixed(1)}% (${loadedGB}GB / ${totalGB}GB)`);
                });
                
                setModelStatus('✅ Download complete! Loading models...');
                setDownloadProgress(null);
                
                // Reload models after download
                await checkLocalAvailability();
              } catch (error: any) {
                console.error('Download error:', error);
                setModelStatus(`❌ Download failed: ${error.message}`);
                Alert.alert(
                  'Download Error', 
                  `Failed to download models:\n\n${error.message}\n\nPlease check your internet connection.`
                );
              } finally {
                setDownloading(false);
              }
            },
          },
        ]
      );
    } catch (error: any) {
      setModelStatus(`❌ Error: ${error.message}`);
      setDownloading(false);
    }
  };

  const handleGenerate = async () => {
    if (!prompt.trim()) {
      Alert.alert('Error', 'Please enter a prompt');
      return;
    }

    setLoading(true);
    setError(null);
    setGeneratedImage(null);

    try {
      setGenerationProgress(null);
      const imageDataUri = await generateImageLocal(prompt.trim(), {
        steps: 20,
        guidanceScale: 7.5,
        width: 512,
        height: 512,
        onProgress: (progress) => {
          setGenerationProgress(progress);
        },
      });
      setGeneratedImage(imageDataUri);
      setGenerationProgress(null);
    } catch (err: any) {
      setGenerationProgress(null);
      // Check if error is related to model not being ready
      const errorMessage = err.message || 'Failed to generate image';
      const isModelNotReady = errorMessage.toLowerCase().includes('not loaded') || 
                              errorMessage.toLowerCase().includes('model not') ||
                              errorMessage.toLowerCase().includes('not ready') ||
                              errorMessage.toLowerCase().includes('missing required models');
      
      const displayMessage = isModelNotReady 
        ? 'Model is not ready yet.'
        : errorMessage;
      
      setError(displayMessage);
      if (isModelNotReady) {
        Alert.alert('', 'Model is not ready yet.');
      } else {
        Alert.alert('Error', displayMessage);
      }
    } finally {
      setLoading(false);
    }
  };

  const handleClear = () => {
    setPrompt('');
    setGeneratedImage(null);
    setError(null);
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <StatusBar style="auto" />
      <LinearGradient
        colors={['#667eea', '#764ba2']}
        style={styles.gradient}
      >
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          keyboardShouldPersistTaps="handled"
        >
          <View style={styles.header}>
            <Text style={styles.title}>AI Image Generator</Text>
            <Text style={styles.subtitle}>Transform your ideas into images</Text>
            {localAvailable && (
              <View style={styles.badge}>
                <Text style={styles.badgeText}>📱 On-Device Generation</Text>
              </View>
            )}
            {modelLoading && (
              <Text style={styles.modelLoadingText}>Loading model...</Text>
            )}
            {modelStatus && !modelLoading && !modelStatus.includes('Models not found') && !modelStatus.includes('Starting automatic download') && (
              <Text style={styles.modelStatusText}>{modelStatus}</Text>
            )}
            {downloadProgress && (
              <View style={styles.downloadContainer}>
                <Text style={styles.downloadText}>
                  Model downloading {downloadProgress.overallPercentage.toFixed(1)}%
                </Text>
                <Text style={styles.downloadSubtext}>
                  {(downloadProgress.loaded / 1024 / 1024 / 1024).toFixed(2)}GB / {(downloadProgress.total / 1024 / 1024 / 1024).toFixed(2)}GB
                </Text>
                <View style={styles.progressBar}>
                  <View 
                    style={[
                      styles.progressFill, 
                      { width: `${downloadProgress.overallPercentage}%` }
                    ]} 
                  />
                </View>
              </View>
            )}
          </View>

          <View style={styles.inputContainer}>
            <TextInput
              style={styles.input}
              placeholder="Describe the image you want to generate..."
              placeholderTextColor="#999"
              value={prompt}
              onChangeText={setPrompt}
              multiline
              numberOfLines={4}
              textAlignVertical="top"
              editable={!loading}
            />
          </View>

          <View style={styles.buttonContainer}>
            <TouchableOpacity
              style={[styles.button, styles.generateButton]}
              onPress={handleGenerate}
              disabled={loading}
            >
              {loading ? (
                <ActivityIndicator color="#fff" />
              ) : (
                <Text style={styles.buttonText}>Generate Image</Text>
              )}
            </TouchableOpacity>

            {generatedImage && (
              <TouchableOpacity
                style={[styles.button, styles.clearButton]}
                onPress={handleClear}
                disabled={loading}
              >
                <Text style={styles.buttonText}>Clear</Text>
              </TouchableOpacity>
            )}
          </View>

          {error && (
            <View style={styles.errorContainer}>
              <Text style={styles.errorText}>{error}</Text>
            </View>
          )}

          {generatedImage && (
            <View style={styles.imageContainer}>
              <Image
                source={{ uri: generatedImage }}
                style={styles.image}
                contentFit="contain"
                transition={200}
              />
            </View>
          )}

          {loading && (
            <View style={styles.loadingContainer}>
              <ActivityIndicator size="large" color="#fff" />
              <Text style={styles.loadingText}>
                {generationProgress 
                  ? `Generating... Step ${generationProgress.step}/${generationProgress.totalSteps} (${generationProgress.progress}%)`
                  : 'Generating your image...'}
              </Text>
              {generationProgress && (
                <View style={styles.progressBar}>
                  <View 
                    style={[
                      styles.progressFill, 
                      { width: `${generationProgress.progress}%` }
                    ]} 
                  />
                </View>
              )}
            </View>
          )}
        </ScrollView>
      </LinearGradient>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  gradient: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
    padding: 20,
    paddingTop: 60,
  },
  header: {
    alignItems: 'center',
    marginBottom: 30,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#fff',
    opacity: 0.9,
  },
  inputContainer: {
    marginBottom: 20,
  },
  input: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    fontSize: 16,
    minHeight: 120,
    textAlignVertical: 'top',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  buttonContainer: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 20,
  },
  button: {
    flex: 1,
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 4,
    elevation: 3,
  },
  generateButton: {
    backgroundColor: '#4CAF50',
  },
  clearButton: {
    backgroundColor: '#f44336',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  errorContainer: {
    backgroundColor: 'rgba(244, 67, 54, 0.2)',
    padding: 12,
    borderRadius: 8,
    marginBottom: 20,
  },
  errorText: {
    color: '#fff',
    fontSize: 14,
    textAlign: 'center',
  },
  imageContainer: {
    marginTop: 20,
    borderRadius: 12,
    overflow: 'hidden',
    backgroundColor: '#fff',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 5,
  },
  image: {
    width: '100%',
    aspectRatio: 1,
  },
  loadingContainer: {
    alignItems: 'center',
    marginTop: 20,
  },
  loadingText: {
    color: '#fff',
    marginTop: 12,
    fontSize: 16,
  },
  badge: {
    backgroundColor: 'rgba(76, 175, 80, 0.3)',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 12,
    marginTop: 8,
    borderWidth: 1,
    borderColor: 'rgba(76, 175, 80, 0.5)',
  },
  badgeText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '600',
  },
  modelLoadingText: {
    color: '#fff',
    fontSize: 12,
    marginTop: 4,
    opacity: 0.8,
  },
  modelStatusText: {
    color: '#fff',
    fontSize: 11,
    marginTop: 4,
    opacity: 0.9,
    textAlign: 'center',
  },
  downloadContainer: {
    marginTop: 12,
    width: '100%',
  },
  downloadText: {
    color: '#fff',
    fontSize: 14,
    marginBottom: 4,
    textAlign: 'center',
    fontWeight: '600',
  },
  downloadSubtext: {
    color: 'rgba(255, 255, 255, 0.7)',
    fontSize: 11,
    marginBottom: 8,
    textAlign: 'center',
  },
  progressBar: {
    height: 4,
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
    borderRadius: 2,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: '#4CAF50',
  },
  downloadButton: {
    backgroundColor: '#2196F3',
    marginTop: 12,
  },
});
