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
  clearModelCache,
  cleanupTempFiles
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
    // Clean up any temp files from previous sessions first
    cleanupTempFiles().catch(err => {
      console.log('Error cleaning temp files:', err);
    });
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
            setModelStatus('Model is ready. The first generation may take a while.');
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
      // Aggressive memory optimization for iPhone 13 (4GB RAM)
      // Use very low resolution (256x256) and minimal steps (10) to prevent crashes
      // 256x256 uses ~70% less memory than 512x512 and ~56% less than 384x384
      const imageDataUri = await generateImageLocal(prompt.trim(), {
        steps: 10,  // Minimal steps for 4GB devices (reduced from 15)
        guidanceScale: 7.0,  // Slightly reduced to save memory
        width: 256,  // Very low resolution for 4GB devices (256x256 = 65,536 pixels vs 262,144 for 512x512)
        height: 256,
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
        colors={['#1a1a2e', '#16213e', '#0f3460', '#533483']}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        locations={[0, 0.3, 0.7, 1]}
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
              placeholderTextColor="rgba(255, 255, 255, 0.5)"
              value={prompt}
              onChangeText={setPrompt}
              multiline
              numberOfLines={4}
              textAlignVertical="top"
              editable={!loading}
            />
          </View>

          <View style={styles.buttonContainer}>
            <LinearGradient
              colors={loading ? ['#667eea', '#764ba2', '#533483', '#4a2c7a'] : ['#667eea', '#764ba2', '#533483', '#4a2c7a']}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
              locations={[0, 0.3, 0.7, 1]}
              style={[styles.button, styles.generateButton]}
            >
              <TouchableOpacity
                style={styles.buttonInner}
                onPress={handleGenerate}
                disabled={loading}
                activeOpacity={0.8}
              >
                {loading ? (
                  <ActivityIndicator color="#fff" />
                ) : (
                  <Text style={styles.buttonText}>✨ Generate Image</Text>
                )}
              </TouchableOpacity>
            </LinearGradient>

            {generatedImage && (
              <LinearGradient
                colors={['#e94560', '#c73650', '#a01d3d', '#7a1530']}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 1 }}
                locations={[0, 0.3, 0.7, 1]}
                style={[styles.button, styles.clearButton]}
              >
                <TouchableOpacity
                  style={styles.buttonInner}
                  onPress={handleClear}
                  disabled={loading}
                  activeOpacity={0.8}
                >
                  <Text style={styles.buttonText}>🗑️ Clear</Text>
                </TouchableOpacity>
              </LinearGradient>
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
                  ? `Generating... ${generationProgress.progress}%`
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
    position: 'relative',
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
    fontSize: 36,
    fontWeight: '800',
    color: '#fff',
    marginBottom: 8,
    textShadowColor: 'rgba(0, 0, 0, 0.3)',
    textShadowOffset: { width: 0, height: 2 },
    textShadowRadius: 4,
    letterSpacing: 0.5,
  },
  subtitle: {
    fontSize: 16,
    color: '#fff',
    opacity: 0.95,
    textShadowColor: 'rgba(0, 0, 0, 0.2)',
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 2,
  },
  inputContainer: {
    marginBottom: 20,
  },
  input: {
    backgroundColor: 'rgba(26, 26, 46, 0.6)',
    borderRadius: 16,
    padding: 16,
    fontSize: 16,
    minHeight: 120,
    textAlignVertical: 'top',
    color: '#fff',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 12,
    elevation: 5,
    borderWidth: 1,
    borderColor: 'rgba(83, 52, 131, 0.5)',
  },
  buttonContainer: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 20,
    alignItems: 'center',
  },
  button: {
    flex: 1,
    paddingVertical: 14,
    paddingHorizontal: 20,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 50,
    maxHeight: 50,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.4,
    shadowRadius: 12,
    elevation: 8,
    overflow: 'hidden',
  },
  generateButton: {
    backgroundColor: '#00d4ff',
  },
  clearButton: {
    backgroundColor: '#ff6b9d',
  },
  buttonInner: {
    width: '100%',
    height: '100%',
    alignItems: 'center',
    justifyContent: 'center',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '700',
    letterSpacing: 0.5,
    textShadowColor: 'rgba(0, 0, 0, 0.3)',
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 2,
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
    borderRadius: 20,
    overflow: 'hidden',
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.5,
    shadowRadius: 16,
    elevation: 10,
    borderWidth: 2,
    borderColor: 'rgba(255, 255, 255, 0.2)',
    alignSelf: 'center',
    maxWidth: '85%',
  },
  image: {
    width: 300,
    height: 300,
    maxWidth: '100%',
    alignSelf: 'center',
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
