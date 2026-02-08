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
}
