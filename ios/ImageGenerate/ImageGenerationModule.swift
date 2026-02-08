//
// ImageGenerationModule.swift
// Native iOS module using Apple's Stable Diffusion Swift package
// This replaces the manual implementation with Apple's official framework
//

import Foundation
import CoreML
import UIKit
import StableDiffusion

@objc(ImageGenerationModule)
class ImageGenerationModule: NSObject {
  
  private var pipeline: StableDiffusionPipeline?
  private var isModelReady = false
  private var modelsBasePath: String?
  
  @objc
  static func requiresMainQueueSetup() -> Bool {
    return false
  }
  
  /**
   * Load Stable Diffusion pipeline using Apple's framework
   */
  @objc
  func loadModel(_ modelPath: String, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
    let workItem = DispatchWorkItem {
      do {
        // Remove file:// prefix if present, as URL(fileURLWithPath:) expects a file path, not a URL string
        var cleanPath = modelPath
        if cleanPath.hasPrefix("file://") {
          cleanPath = String(cleanPath.dropFirst(7))  // Remove "file://" prefix
        }
        let baseURL = URL(fileURLWithPath: cleanPath)
        self.modelsBasePath = baseURL.path
        
        print("📦 Loading Stable Diffusion pipeline from: \(baseURL.path)")
        
        // Create configuration for the pipeline
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .cpuAndNeuralEngine  // Use Neural Engine if available
        
        // Initialize pipeline with model path
        // Apple's framework automatically loads:
        // - TextEncoder.mlmodelc
        // - UnetChunk1.mlmodelc, UnetChunk2.mlmodelc (or Unet.mlmodelc)
        // - VAEDecoder.mlmodelc
        // - vocab.json, merges.txt (for tokenizer)
        // controlNet expects an array of strings, not nil
        // Pass empty array [] if not using ControlNet
        self.pipeline = try StableDiffusionPipeline(
          resourcesAt: baseURL,
          controlNet: [],  // Empty array = no ControlNet for basic text-to-image
          configuration: configuration
        )
        
        self.isModelReady = true
        print("✅ Stable Diffusion pipeline loaded successfully")
        
        DispatchQueue.main.async {
          resolver(true)
        }
      } catch {
        print("❌ Failed to load pipeline: \(error.localizedDescription)")
        DispatchQueue.main.async {
          rejecter("LOAD_ERROR", error.localizedDescription, error)
        }
      }
    }
    DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
  }
  
  /**
   * Check if model is loaded
   */
  @objc
  func isModelLoaded(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
    resolver(isModelReady && pipeline != nil)
  }
  
  /**
   * Generate image using Apple's Stable Diffusion framework
   */
  @objc
  func generateImage(
    _ prompt: String,
    steps: NSNumber,
    guidanceScale: NSNumber,
    seed: NSNumber?,
    width: NSNumber,
    height: NSNumber,
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    guard let pipeline = pipeline, isModelReady else {
      rejecter("NOT_LOADED", "Model not loaded. Call loadModel first.", nil)
      return
    }
    
    let workItem = DispatchWorkItem {
      do {
        print("🎨 Generating image for prompt: \(prompt)")
        
        // Configure generation parameters
        let seedValue = seed?.intValue ?? -1
        // If seed is -1 or invalid, generate a random seed, otherwise use the provided seed
        let finalSeed: UInt32 = seedValue >= 0 ? UInt32(seedValue) : UInt32.random(in: 0...UInt32.max)
        
        // Generate image using Apple's framework
        // This handles the entire pipeline automatically:
        // - Tokenization
        // - Text encoding
        // - Diffusion loop with proper scheduler
        // - Classifier-free guidance
        // - VAE decoding
        // - Image normalization
        // Create generation configuration
        // Configuration requires prompt as initializer parameter
        var generationConfig = StableDiffusionPipeline.Configuration(prompt: prompt)
        generationConfig.imageCount = 1
        generationConfig.stepCount = steps.intValue
        generationConfig.seed = finalSeed  // Non-optional UInt32
        generationConfig.guidanceScale = Float(guidanceScale.doubleValue)  // Convert Double to Float
        generationConfig.disableSafety = false  // Enable safety checker if available
        
        let images = try pipeline.generateImages(configuration: generationConfig)
        
        guard let cgImageOptional = images.first, let cgImage = cgImageOptional else {
          throw NSError(domain: "ImageGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "No image generated"])
        }
        
        print("✅ Image generated successfully")
        print("  🔍 CGImage size: \(cgImage.width)x\(cgImage.height)")
        print("  🔍 CGImage color space: \(cgImage.colorSpace?.name as String? ?? "unknown")")
        
        // Convert CGImage to UIImage, then to PNG data
        let uiImage = UIImage(cgImage: cgImage)
        print("  🔍 UIImage size: \(uiImage.size)")
        
        // Check if image is valid (not all white/black)
        if let cgImageData = cgImage.dataProvider?.data,
           let pixelData = CFDataGetBytePtr(cgImageData) {
          let bytesPerPixel = cgImage.bitsPerPixel / 8
          let totalBytes = CFDataGetLength(cgImageData)
          print("  🔍 Image data: \(totalBytes) bytes, \(bytesPerPixel) bytes per pixel")
          
          // Sample pixels from different areas to check image content
          let sampleCount = min(20, totalBytes / bytesPerPixel)
          if totalBytes >= bytesPerPixel * sampleCount {
            var allWhite = true
            var allBlack = true
            var sampleValues: [(Int, Int, Int)] = []
            
            // Sample from center and corners
            let width = cgImage.width
            let height = cgImage.height
            let samplePositions = [
              (width / 4, height / 4),      // Top-left area
              (width / 2, height / 2),      // Center
              (width * 3 / 4, height / 4),  // Top-right
              (width / 4, height * 3 / 4),  // Bottom-left
              (width * 3 / 4, height * 3 / 4) // Bottom-right
            ]
            
            for (x, y) in samplePositions {
              let offset = (y * width + x) * bytesPerPixel
              if offset + 2 < totalBytes {
                let r = Int(pixelData[offset])
                let g = Int(pixelData[offset + 1])
                let b = Int(pixelData[offset + 2])
                sampleValues.append((r, g, b))
                
                if r != 255 || g != 255 || b != 255 {
                  allWhite = false
                }
                if r != 0 || g != 0 || b != 0 {
                  allBlack = false
                }
              }
            }
            
            print("  🔍 Image check: allWhite=\(allWhite), allBlack=\(allBlack)")
            print("  🔍 Sample pixel values (RGB): \(sampleValues.prefix(5))")
            
            // Check if image is mostly white (very light)
            let avgBrightness = sampleValues.map { ($0.0 + $0.1 + $0.2) / 3 }.reduce(0, +) / sampleValues.count
            print("  🔍 Average brightness: \(avgBrightness)/255")
          }
        }
        
        guard let imageData = uiImage.pngData() else {
          throw NSError(domain: "ImageGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to PNG"])
        }
        
        print("  🔍 PNG data size: \(imageData.count) bytes")
        
        let base64String = imageData.base64EncodedString()
        print("  🔍 Base64 string length: \(base64String.count)")
        print("  🔍 Base64 preview (first 50 chars): \(String(base64String.prefix(50)))")
        
        // Verify the base64 string is valid
        if let decodedData = Data(base64Encoded: base64String),
           let decodedImage = UIImage(data: decodedData) {
          print("  ✅ Base64 encoding verified - decoded image size: \(decodedImage.size)")
        } else {
          print("  ⚠️ Base64 encoding verification failed!")
        }
        
        DispatchQueue.main.async {
          // Return base64 string for React Native compatibility
          resolver("data:image/png;base64,\(base64String)")
        }
      } catch {
        print("❌ Generation error: \(error.localizedDescription)")
        DispatchQueue.main.async {
          rejecter("GENERATION_ERROR", error.localizedDescription, error)
        }
      }
    }
    DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
  }
  
  /**
   * Get model path (for compatibility)
   */
  @objc
  func getModelPath(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
    if let path = modelsBasePath {
      resolver(path)
    } else {
      rejecter("NO_PATH", "Model path not set", nil)
    }
  }
  
  /**
   * Check if a model file exists in bundle or Documents directory
   * Returns: "bundle", "documents", or "none"
   */
  @objc
  func checkModelLocation(_ modelName: String, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
    print("🔍 Checking location for: \(modelName)")
    
    // Check bundle first - models are in ios/ImageGenerate/model/ directory
    // Try multiple possible bundle paths
    var bundlePaths: [String] = []
    
    // Path 1: Direct resource path (ImageGenerate/model/)
    if let resourcePath = Bundle.main.resourcePath {
      let path1 = (resourcePath as NSString).appendingPathComponent("ImageGenerate/model/\(modelName)")
      bundlePaths.append(path1)
      print("  📍 Checking bundle path 1: \(path1)")
    }
    
    // Path 2: Using Bundle.main.path(forResource:ofType:inDirectory:)
    // For .mlmodelc directories, try different approaches
    if modelName.hasSuffix(".mlmodelc") {
      let modelBaseName = (modelName as NSString).deletingPathExtension
      if let bundlePath = Bundle.main.path(forResource: modelBaseName, ofType: "mlmodelc", inDirectory: "ImageGenerate/model") {
        bundlePaths.append(bundlePath)
        print("  📍 Checking bundle path 2: \(bundlePath)")
      }
      // Also try without directory
      if let bundlePath = Bundle.main.path(forResource: modelBaseName, ofType: "mlmodelc") {
        bundlePaths.append(bundlePath)
        print("  📍 Checking bundle path 3: \(bundlePath)")
      }
    } else {
      // For files like vocab.json, merges.txt
      if let bundlePath = Bundle.main.path(forResource: modelName, ofType: nil, inDirectory: "ImageGenerate/model") {
        bundlePaths.append(bundlePath)
        print("  📍 Checking bundle path 2: \(bundlePath)")
      }
    }
    
    // Path 3: Check if model directory exists directly in resource path (model/)
    // This matches the old resolveModelPath logic which checked "model/" not "ImageGenerate/model/"
    if let bundlePath = Bundle.main.resourcePath {
      let modelDir = (bundlePath as NSString).appendingPathComponent("model/\(modelName)")
      bundlePaths.append(modelDir)
      print("  📍 Checking bundle path 4: \(modelDir)")
    }
    
    // Path 4: Check ImageGenerate/model/ directly
    if let bundlePath = Bundle.main.resourcePath {
      let modelDir = (bundlePath as NSString).appendingPathComponent("ImageGenerate/model/\(modelName)")
      bundlePaths.append(modelDir)
      print("  📍 Checking bundle path 5: \(modelDir)")
    }
    
    // Path 5: List all files in bundle to debug (only for first model check)
    if modelName == "TextEncoder.mlmodelc" {
      if let resourcePath = Bundle.main.resourcePath {
        print("  🔍 Bundle resource path: \(resourcePath)")
        // Try to list model directory
        let modelDir = (resourcePath as NSString).appendingPathComponent("model")
        if FileManager.default.fileExists(atPath: modelDir) {
          if let contents = try? FileManager.default.contentsOfDirectory(atPath: modelDir) {
            print("  🔍 Contents of bundle/model/: \(contents.prefix(10))")
          }
        }
        let imageGenModelDir = (resourcePath as NSString).appendingPathComponent("ImageGenerate/model")
        if FileManager.default.fileExists(atPath: imageGenModelDir) {
          if let contents = try? FileManager.default.contentsOfDirectory(atPath: imageGenModelDir) {
            print("  🔍 Contents of bundle/ImageGenerate/model/: \(contents.prefix(10))")
          }
        }
      }
    }
    
    // Check all possible bundle paths
    for bundleModelPath in bundlePaths {
      var isDirectory: ObjCBool = false
      if FileManager.default.fileExists(atPath: bundleModelPath, isDirectory: &isDirectory) {
        // For directories (.mlmodelc), check if not empty
        if modelName.hasSuffix(".mlmodelc") && isDirectory.boolValue {
          if let contents = try? FileManager.default.contentsOfDirectory(atPath: bundleModelPath),
             !contents.isEmpty {
            print("✅ \(modelName) found in bundle at: \(bundleModelPath)")
            resolver("bundle")
            return
          }
        } else if !modelName.hasSuffix(".mlmodelc") {
          // Regular file (vocab.json, merges.txt)
          print("✅ \(modelName) found in bundle at: \(bundleModelPath)")
          resolver("bundle")
          return
        }
      }
    }
    
    print("  ❌ \(modelName) not found in bundle")
    
    // Check Documents directory
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let cachedModelPath = documentsPath.appendingPathComponent("models/\(modelName)")
    print("  📍 Checking Documents path: \(cachedModelPath.path)")
    
    var isDirectory: ObjCBool = false
    if FileManager.default.fileExists(atPath: cachedModelPath.path, isDirectory: &isDirectory) {
      // For directories (.mlmodelc), check if not empty
      if modelName.hasSuffix(".mlmodelc") && isDirectory.boolValue {
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: cachedModelPath.path),
           !contents.isEmpty {
          print("✅ \(modelName) found in Documents at: \(cachedModelPath.path)")
          resolver("documents")
          return
        }
      } else if !modelName.hasSuffix(".mlmodelc") {
        print("✅ \(modelName) found in Documents at: \(cachedModelPath.path)")
        resolver("documents")
        return
      }
    }
    
    // Not found in either location
    print("  ❌ \(modelName) not found in bundle or Documents - needs download")
    resolver("none")
  }
}
