//
// ImageGenerationModuleApple.swift
// Native iOS module using Apple's Stable Diffusion Swift package
// 
// IMPORTANT: This requires adding Apple's ml-stable-diffusion Swift package
// Add via Xcode: File → Add Package Dependencies → https://github.com/apple/ml-stable-diffusion
//

import Foundation
import CoreML
import UIKit

// Uncomment after adding the Swift package:
// import StableDiffusion

@objc(ImageGenerationModule)
class ImageGenerationModule: NSObject {
  
  // Uncomment after adding the Swift package:
  // private var pipeline: StableDiffusionPipeline?
  private var isModelReady = false
  private var modelsBasePath: String?
  
  @objc
  static func requiresMainQueueSetup() -> Bool {
    return false
  }
  
  /**
   * Load Stable Diffusion pipeline using Apple's framework
   * 
   * NOTE: This implementation requires:
   * 1. Adding Apple's ml-stable-diffusion Swift package via Xcode
   * 2. Uncommenting the import and pipeline code below
   */
  @objc
  func loadModel(_ modelPath: String, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let baseURL = URL(fileURLWithPath: modelPath)
        self.modelsBasePath = baseURL.path
        
        print("📦 Loading Stable Diffusion pipeline from: \(baseURL.path)")
        
        // TODO: Uncomment after adding Swift package:
        /*
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .cpuAndNeuralEngine
        
        // Apple's framework loads models automatically from the base URL
        // It expects: TextEncoder.mlmodelc, UnetChunk1.mlmodelc, UnetChunk2.mlmodelc, VAEDecoder.mlmodelc
        self.pipeline = try StableDiffusionPipeline(
          resourcesAt: baseURL,
          configuration: configuration
        )
        */
        
        // Temporary: Return success for now (will fail at generation until package is added)
        self.isModelReady = true
        print("⚠️ Apple's Stable Diffusion framework not yet integrated")
        print("   Please add the Swift package: https://github.com/apple/ml-stable-diffusion")
        
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
  }
  
  /**
   * Check if model is loaded
   */
  @objc
  func isModelLoaded(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
    resolver(isModelReady)
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
    // TODO: Uncomment after adding Swift package:
    /*
    guard let pipeline = pipeline, isModelReady else {
      rejecter("NOT_LOADED", "Model not loaded. Call loadModel first.", nil)
      return
    }
    
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        print("🎨 Generating image for prompt: \(prompt)")
        
        let seedValue = seed?.intValue ?? -1
        let randomSeed = seedValue >= 0 ? UInt32(seedValue) : nil
        
        // Generate using Apple's framework
        // API may vary - check Apple's documentation for exact method signature
        let images = try pipeline.generateImages(
          prompt: prompt,
          imageCount: 1,
          stepCount: steps.intValue,
          seed: randomSeed,
          guidanceScale: guidanceScale.doubleValue,
          disableSafety: false
        )
        
        guard let image = images.first else {
          throw NSError(domain: "ImageGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "No image generated"])
        }
        
        print("✅ Image generated successfully")
        
        guard let imageData = image.pngData() else {
          throw NSError(domain: "ImageGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to PNG"])
        }
        
        let base64String = imageData.base64EncodedString()
        
        DispatchQueue.main.async {
          resolver([
            "image": "data:image/png;base64,\(base64String)",
            "seed": seedValue >= 0 ? seedValue : Int.random(in: 0...Int.max)
          ])
        }
      } catch {
        print("❌ Generation error: \(error.localizedDescription)")
        DispatchQueue.main.async {
          rejecter("GENERATION_ERROR", error.localizedDescription, error)
        }
      }
    }
    */
    
    // Temporary error until package is added:
    rejecter("NOT_IMPLEMENTED", "Apple's Stable Diffusion framework not yet integrated. Please add the Swift package and uncomment the code.", nil)
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
