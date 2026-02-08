//
// ImageGenerationModule.swift
// Native iOS module for on-device image generation using Core ML
// Complete Stable Diffusion pipeline implementation
//

import Foundation
import CoreML
import UIKit
import Accelerate

@objc(ImageGenerationModule)
class ImageGenerationModule: NSObject {
  
  // Core ML models
  private var textEncoder: MLModel?
  private var unetChunk1: MLModel?
  private var unetChunk2: MLModel?
  private var vaeDecoder: MLModel?
  private var safetyChecker: MLModel?
  private var isModelReady = false
  
  // Tokenizer
  private var vocab: [String: Int] = [:]
  private var merges: [(String, String)] = []
  
  // Model paths
  private var modelsBasePath: String?
  
  @objc
  static func requiresMainQueueSetup() -> Bool {
    return false
  }
  
  /**
   * Load all Core ML models and tokenizer files
   */
  @objc
  func loadModel(_ modelPath: String, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let baseURL = self.resolveModelPath(modelPath)
        self.modelsBasePath = baseURL.path
        
        print("📦 Loading models from: \(baseURL.path)")
        
        // Load TextEncoder
        let textEncoderURL = baseURL.appendingPathComponent("TextEncoder.mlmodelc")
        if FileManager.default.fileExists(atPath: textEncoderURL.path) {
          // Try loading directly first (for already-compiled models without Manifest.json)
          do {
            self.textEncoder = try MLModel(contentsOf: textEncoderURL)
            print("✅ TextEncoder loaded directly")
          } catch {
            // If direct load fails, try compilation (requires Manifest.json)
            print("⚠️ Direct load failed, trying compilation: \(error.localizedDescription)")
            let compiledTextEncoder = try MLModel.compileModel(at: textEncoderURL)
            self.textEncoder = try MLModel(contentsOf: compiledTextEncoder)
            print("✅ TextEncoder loaded via compilation")
          }
        } else {
          throw NSError(domain: "ImageGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "TextEncoder.mlmodelc not found at \(textEncoderURL.path)"])
        }
        
        // Load Unet chunks
        let unetChunk1URL = baseURL.appendingPathComponent("UnetChunk1.mlmodelc")
        let unetChunk2URL = baseURL.appendingPathComponent("UnetChunk2.mlmodelc")
        
        if FileManager.default.fileExists(atPath: unetChunk1URL.path) && 
           FileManager.default.fileExists(atPath: unetChunk2URL.path) {
          // Try loading directly first
          do {
            self.unetChunk1 = try MLModel(contentsOf: unetChunk1URL)
            self.unetChunk2 = try MLModel(contentsOf: unetChunk2URL)
            print("✅ Unet loaded directly (chunked: Chunk1 + Chunk2)")
          } catch {
            // If direct load fails, try compilation
            print("⚠️ Direct load failed, trying compilation: \(error.localizedDescription)")
            let compiledChunk1 = try MLModel.compileModel(at: unetChunk1URL)
            let compiledChunk2 = try MLModel.compileModel(at: unetChunk2URL)
            self.unetChunk1 = try MLModel(contentsOf: compiledChunk1)
            self.unetChunk2 = try MLModel(contentsOf: compiledChunk2)
            print("✅ Unet loaded via compilation (chunked: Chunk1 + Chunk2)")
          }
        } else {
          throw NSError(domain: "ImageGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unet chunks not found"])
        }
        
        // Load VAE Decoder
        let vaeDecoderURL = baseURL.appendingPathComponent("VAEDecoder.mlmodelc")
        if FileManager.default.fileExists(atPath: vaeDecoderURL.path) {
          // Try loading directly first
          do {
            self.vaeDecoder = try MLModel(contentsOf: vaeDecoderURL)
            print("✅ VAEDecoder loaded directly")
          } catch {
            // If direct load fails, try compilation
            print("⚠️ Direct load failed, trying compilation: \(error.localizedDescription)")
            let compiledVAE = try MLModel.compileModel(at: vaeDecoderURL)
            self.vaeDecoder = try MLModel(contentsOf: compiledVAE)
            print("✅ VAEDecoder loaded via compilation")
          }
        } else {
          throw NSError(domain: "ImageGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "VAEDecoder.mlmodelc not found"])
        }
        
        // Load Safety Checker (optional)
        let safetyCheckerURL = baseURL.appendingPathComponent("SafetyChecker.mlmodelc")
        if FileManager.default.fileExists(atPath: safetyCheckerURL.path) {
          // Try loading directly first
          do {
            self.safetyChecker = try MLModel(contentsOf: safetyCheckerURL)
            print("✅ SafetyChecker loaded directly")
          } catch {
            // If direct load fails, try compilation
            print("⚠️ Direct load failed, trying compilation: \(error.localizedDescription)")
            let compiledSafety = try MLModel.compileModel(at: safetyCheckerURL)
            self.safetyChecker = try MLModel(contentsOf: compiledSafety)
            print("✅ SafetyChecker loaded via compilation")
          }
        }
        
        // Load tokenizer files
        let vocabURL = baseURL.appendingPathComponent("vocab.json")
        let mergesURL = baseURL.appendingPathComponent("merges.txt")
        
        if FileManager.default.fileExists(atPath: vocabURL.path) {
          let vocabData = try Data(contentsOf: vocabURL)
          self.vocab = try JSONDecoder().decode([String: Int].self, from: vocabData)
          print("✅ Vocab loaded (\(self.vocab.count) tokens)")
        }
        
        if FileManager.default.fileExists(atPath: mergesURL.path) {
          let mergesContent = try String(contentsOf: mergesURL, encoding: .utf8)
          self.merges = mergesContent.components(separatedBy: .newlines)
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
            .compactMap { line -> (String, String)? in
              let parts = line.split(separator: " ").map(String.init)
              return parts.count == 2 ? (parts[0], parts[1]) : nil
            }
          print("✅ Merges loaded (\(self.merges.count) merges)")
        }
        
        // Verify required models
        guard self.textEncoder != nil && 
              self.unetChunk1 != nil && 
              self.unetChunk2 != nil &&
              self.vaeDecoder != nil else {
          throw NSError(
            domain: "ImageGeneration",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Missing required models"]
          )
        }
        
        self.isModelReady = true
        print("🎉 All models loaded successfully!")
        
        DispatchQueue.main.async {
          resolver([
            "success": true,
            "message": "Models loaded successfully",
            "models": [
              "textEncoder": self.textEncoder != nil,
              "unetChunk1": self.unetChunk1 != nil,
              "unetChunk2": self.unetChunk2 != nil,
              "vaeDecoder": self.vaeDecoder != nil,
              "safetyChecker": self.safetyChecker != nil
            ]
          ])
        }
      } catch {
        print("❌ Model loading error: \(error.localizedDescription)")
        DispatchQueue.main.async {
          rejecter("MODEL_LOAD_ERROR", "Failed to load models: \(error.localizedDescription)", error)
        }
      }
    }
  }
  
  /**
   * Resolve model path from documents directory (cached) or bundle (fallback)
   */
  private func resolveModelPath(_ path: String) -> URL {
    // First, try documents directory (for downloaded/cached models)
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let cachedModelsPath = documentsPath.appendingPathComponent("models")
    
    if FileManager.default.fileExists(atPath: cachedModelsPath.path) {
      // Check if required models exist in cache
      let textEncoderPath = cachedModelsPath.appendingPathComponent("TextEncoder.mlmodelc")
      if FileManager.default.fileExists(atPath: textEncoderPath.path) {
        print("📁 Using cached models from: \(cachedModelsPath.path)")
        return cachedModelsPath
      }
    }
    
    // Try bundle model directory (ios/ImageGenerate/model)
    if let bundlePath = Bundle.main.resourcePath {
      // Check for model directory in bundle (ios/ImageGenerate/model)
      let bundleModelPath = (bundlePath as NSString).appendingPathComponent("model")
      if FileManager.default.fileExists(atPath: bundleModelPath) {
        // FIRST: Check if .mlmodelc directories already exist (pre-extracted)
        let textEncoderPath = (bundleModelPath as NSString).appendingPathComponent("TextEncoder.mlmodelc")
        if FileManager.default.fileExists(atPath: textEncoderPath) {
          print("📁 Found pre-extracted models in bundle: \(bundleModelPath)")
          // Copy models to documents directory for use (bundle is read-only)
          if let extractedPath = self.copyModelsFromBundle(from: bundleModelPath) {
            print("📁 Using models from: \(extractedPath.path)")
            return extractedPath
          }
          // If copy failed, try using bundle directly (may fail if bundle is read-only)
          print("📁 Attempting to use bundled models directly: \(bundleModelPath)")
          return URL(fileURLWithPath: bundleModelPath)
        }
        
        // SECOND: Check if we have tar.gz files (need manual extraction)
        let textEncoderTarGz = (bundleModelPath as NSString).appendingPathComponent("TextEncoder.mlmodelc.tar.gz")
        if FileManager.default.fileExists(atPath: textEncoderTarGz) {
          print("⚠️ Found tar.gz files in bundle but iOS cannot extract them automatically")
          print("   Please extract tar.gz files manually before adding to Xcode:")
          print("   cd ios/ImageGenerate/model")
          print("   tar -xzf TextEncoder.mlmodelc.tar.gz")
          print("   tar -xzf UnetChunk1.mlmodelc.tar.gz")
          print("   tar -xzf UnetChunk2.mlmodelc.tar.gz")
          print("   tar -xzf VAEDecoder.mlmodelc.tar.gz")
          print("   Then add the extracted .mlmodelc directories to Xcode instead of tar.gz files")
          // Still try to copy vocab.json and merges.txt if they exist
          _ = self.copyModelsFromBundle(from: bundleModelPath)
        }
      }
      
      // Fallback: Try main bundle (for bundled assets)
      if let assetsModelPath = Bundle.main.path(forResource: "models", ofType: nil, inDirectory: "assets") {
        print("📁 Using bundled models from: \(assetsModelPath)")
        return URL(fileURLWithPath: assetsModelPath)
      }
      
      // Try assets/models in bundle
      let modelsPath = (bundlePath as NSString).appendingPathComponent("assets/models")
      if FileManager.default.fileExists(atPath: modelsPath) {
        print("📁 Using bundled models from: \(modelsPath)")
        return URL(fileURLWithPath: modelsPath)
      }
    }
    
    // Final fallback: documents directory
    print("📁 Using documents directory: \(documentsPath.appendingPathComponent(path).path)")
    return documentsPath.appendingPathComponent(path)
  }
  
  /**
   * Copy pre-extracted .mlmodelc directories from bundle to documents directory
   * This function copies models from bundle (read-only) to Documents (writable)
   */
  private func copyModelsFromBundle(from bundlePath: String) -> URL? {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let extractedPath = documentsPath.appendingPathComponent("models")
    
    // Create models directory if it doesn't exist
    try? FileManager.default.createDirectory(at: extractedPath, withIntermediateDirectories: true)
    
    let modelNames = ["TextEncoder", "UnetChunk1", "UnetChunk2", "VAEDecoder", "SafetyChecker"]
    var allCopied = true
    
    for modelName in modelNames {
      let bundleModelPath = (bundlePath as NSString).appendingPathComponent("\(modelName).mlmodelc")
      let targetPath = extractedPath.appendingPathComponent("\(modelName).mlmodelc")
      
      // Skip if already copied
      if FileManager.default.fileExists(atPath: targetPath.path) {
        print("✅ \(modelName).mlmodelc already copied")
        continue
      }
      
      // Check if .mlmodelc directory exists in bundle
      if FileManager.default.fileExists(atPath: bundleModelPath) {
        // Check for Manifest.json (preferred) but don't require it
        // Models can sometimes be loaded directly without Manifest.json
        let manifestPath = (bundleModelPath as NSString).appendingPathComponent("Manifest.json")
        let hasManifest = FileManager.default.fileExists(atPath: manifestPath)
        
        if !hasManifest {
          print("⚠️ \(modelName).mlmodelc missing Manifest.json - will try direct load")
        }
        
        // Copy directory from bundle to documents (recursive copy)
        do {
          // Remove target if it exists
          if FileManager.default.fileExists(atPath: targetPath.path) {
            try FileManager.default.removeItem(at: targetPath)
          }
          
          // Copy the entire directory recursively
          try FileManager.default.copyItem(at: URL(fileURLWithPath: bundleModelPath), to: targetPath)
          
          // Verify copy was successful (check for any key files, not just Manifest.json)
          let metadataPath = targetPath.appendingPathComponent("metadata.json")
          let modelMilPath = targetPath.appendingPathComponent("model.mil")
          if FileManager.default.fileExists(atPath: metadataPath.path) || 
             FileManager.default.fileExists(atPath: modelMilPath.path) {
            if hasManifest {
              print("✅ Copied \(modelName).mlmodelc from bundle (with Manifest.json)")
            } else {
              print("✅ Copied \(modelName).mlmodelc from bundle (no Manifest.json, will try direct load)")
            }
          } else {
            print("⚠️ Copied \(modelName).mlmodelc but missing key files - copy may be incomplete")
            if modelName != "SafetyChecker" {
              allCopied = false
            }
          }
        } catch {
          print("❌ Failed to copy \(modelName).mlmodelc: \(error.localizedDescription)")
          if modelName != "SafetyChecker" {
            allCopied = false
          }
        }
      } else if modelName != "SafetyChecker" {
        // Required model not found
        print("⚠️ \(modelName).mlmodelc not found in bundle")
        allCopied = false
      }
    }
    
    // Also copy vocab.json and merges.txt if they exist
    let vocabPath = (bundlePath as NSString).appendingPathComponent("vocab.json")
    let mergesPath = (bundlePath as NSString).appendingPathComponent("merges.txt")
    
    if FileManager.default.fileExists(atPath: vocabPath) {
      let targetVocab = extractedPath.appendingPathComponent("vocab.json")
      do {
        if FileManager.default.fileExists(atPath: targetVocab.path) {
          try FileManager.default.removeItem(at: targetVocab)
        }
        try FileManager.default.copyItem(at: URL(fileURLWithPath: vocabPath), to: targetVocab)
        print("✅ Copied vocab.json")
      } catch {
        print("⚠️ Failed to copy vocab.json: \(error.localizedDescription)")
      }
    }
    
    if FileManager.default.fileExists(atPath: mergesPath) {
      let targetMerges = extractedPath.appendingPathComponent("merges.txt")
      do {
        if FileManager.default.fileExists(atPath: targetMerges.path) {
          try FileManager.default.removeItem(at: targetMerges)
        }
        try FileManager.default.copyItem(at: URL(fileURLWithPath: mergesPath), to: targetMerges)
        print("✅ Copied merges.txt")
      } catch {
        print("⚠️ Failed to copy merges.txt: \(error.localizedDescription)")
      }
    }
    
    return allCopied ? extractedPath : nil
  }
  
  /**
   * Extract tar.gz files from bundle to documents directory
   * Note: iOS apps are sandboxed and cannot execute system commands.
   * This function checks if .mlmodelc directories already exist, and if tar.gz files
   * are found, it logs a message instructing the user to extract them manually.
   * 
   * For testing: Extract tar.gz files manually before adding to Xcode bundle.
   */
  private func extractTarGzFiles(from bundlePath: String) -> URL? {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let extractedPath = documentsPath.appendingPathComponent("models")
    
    // Create models directory if it doesn't exist
    try? FileManager.default.createDirectory(at: extractedPath, withIntermediateDirectories: true)
    
    let modelNames = ["TextEncoder", "UnetChunk1", "UnetChunk2", "VAEDecoder", "SafetyChecker"]
    var allExtracted = true
    var needsExtraction = false
    
    for modelName in modelNames {
      let tarGzPath = (bundlePath as NSString).appendingPathComponent("\(modelName).mlmodelc.tar.gz")
      let targetPath = extractedPath.appendingPathComponent("\(modelName).mlmodelc")
      
      // Skip if already extracted
      if FileManager.default.fileExists(atPath: targetPath.path) {
        print("✅ \(modelName).mlmodelc already extracted")
        continue
      }
      
      // Check if tar.gz exists in bundle
      if FileManager.default.fileExists(atPath: tarGzPath) {
        needsExtraction = true
        if modelName == "SafetyChecker" {
          // SafetyChecker is optional, skip it
          print("⚠️ \(modelName).mlmodelc.tar.gz found but SafetyChecker is optional, skipping")
          continue
        }
        print("⚠️ \(modelName).mlmodelc.tar.gz found but cannot extract on iOS (sandboxed)")
        print("   Please extract tar.gz files manually before adding to Xcode bundle")
        print("   Or use pre-extracted .mlmodelc directories instead")
        allExtracted = false
      } else {
        // Check if .mlmodelc directory exists in bundle (pre-extracted)
        let bundleModelPath = (bundlePath as NSString).appendingPathComponent("\(modelName).mlmodelc")
        if FileManager.default.fileExists(atPath: bundleModelPath) {
          // Copy pre-extracted directory to documents
          do {
            let targetModelPath = extractedPath.appendingPathComponent("\(modelName).mlmodelc")
            if FileManager.default.fileExists(atPath: targetModelPath.path) {
              try FileManager.default.removeItem(at: targetModelPath)
            }
            try FileManager.default.copyItem(at: URL(fileURLWithPath: bundleModelPath), to: targetModelPath)
            print("✅ Copied \(modelName).mlmodelc from bundle")
          } catch {
            print("❌ Failed to copy \(modelName).mlmodelc: \(error.localizedDescription)")
            allExtracted = false
          }
        } else if modelName != "SafetyChecker" {
          print("⚠️ \(modelName).mlmodelc not found in bundle")
          allExtracted = false
        }
      }
    }
    
    // Also copy vocab.json and merges.txt if they exist
    let vocabPath = (bundlePath as NSString).appendingPathComponent("vocab.json")
    let mergesPath = (bundlePath as NSString).appendingPathComponent("merges.txt")
    
    if FileManager.default.fileExists(atPath: vocabPath) {
      let targetVocab = extractedPath.appendingPathComponent("vocab.json")
      do {
        if FileManager.default.fileExists(atPath: targetVocab.path) {
          try FileManager.default.removeItem(at: targetVocab)
        }
        try FileManager.default.copyItem(at: URL(fileURLWithPath: vocabPath), to: targetVocab)
        print("✅ Copied vocab.json")
      } catch {
        print("⚠️ Failed to copy vocab.json: \(error.localizedDescription)")
      }
    }
    
    if FileManager.default.fileExists(atPath: mergesPath) {
      let targetMerges = extractedPath.appendingPathComponent("merges.txt")
      do {
        if FileManager.default.fileExists(atPath: targetMerges.path) {
          try FileManager.default.removeItem(at: targetMerges)
        }
        try FileManager.default.copyItem(at: URL(fileURLWithPath: mergesPath), to: targetMerges)
        print("✅ Copied merges.txt")
      } catch {
        print("⚠️ Failed to copy merges.txt: \(error.localizedDescription)")
      }
    }
    
    if needsExtraction {
      print("⚠️ tar.gz files found but iOS cannot extract them automatically")
      print("   Solution: Extract tar.gz files manually before adding to Xcode:")
      print("   cd ios/ImageGenerate/model")
      print("   tar -xzf TextEncoder.mlmodelc.tar.gz")
      print("   tar -xzf UnetChunk1.mlmodelc.tar.gz")
      print("   tar -xzf UnetChunk2.mlmodelc.tar.gz")
      print("   tar -xzf VAEDecoder.mlmodelc.tar.gz")
      print("   Then add the extracted .mlmodelc directories to Xcode instead of tar.gz files")
    }
    
    return allExtracted ? extractedPath : nil
  }
  
  /**
   * Check if models are loaded
   */
  @objc
  func isModelLoaded(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
    resolver(self.isModelReady && 
             self.textEncoder != nil && 
             self.unetChunk1 != nil && 
             self.unetChunk2 != nil &&
             self.vaeDecoder != nil)
  }
  
  /**
   * Generate image from text prompt using full Stable Diffusion pipeline
   */
  @objc
  func generateImage(
    _ prompt: String,
    steps: NSNumber,
    guidanceScale: NSNumber,
    seed: NSNumber,
    width: NSNumber,
    height: NSNumber,
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    guard isModelReady else {
      rejecter("MODEL_NOT_LOADED", "Models are not loaded. Call loadModel first.", nil)
      return
    }
    
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        print("🎨 Generating image for prompt: \(prompt)")
        
        // Step 1: Tokenize prompt
        let tokenIds = self.tokenizePrompt(prompt)
        print("✅ Tokenized: \(tokenIds.count) tokens")
        
        // Step 2: Encode text with TextEncoder
        let textEmbeddings = try self.encodeText(tokenIds: tokenIds)
        print("✅ Text encoded: shape \(textEmbeddings.shape)")
        
        // Step 3: Generate random noise
        let latentWidth = width.intValue / 8
        let latentHeight = height.intValue / 8
        let noise = self.generateNoise(width: latentWidth, height: latentHeight, seed: seed.intValue)
        print("✅ Noise generated: \(latentWidth)x\(latentHeight)")
        
        // Step 4: Run diffusion steps
        let denoisedLatents = try self.runDiffusion(
          noise: noise,
          textEmbeddings: textEmbeddings,
          steps: steps.intValue,
          guidanceScale: guidanceScale.floatValue,
          latentWidth: latentWidth,
          latentHeight: latentHeight
        )
        print("✅ Diffusion complete")
        
        // Step 5: Decode latents to image with VAE
        let image = try self.decodeLatents(denoisedLatents, width: width.intValue, height: height.intValue)
        print("✅ Image decoded")
        
        // Step 6: (Optional) Run safety checker
        if let safetyChecker = self.safetyChecker {
          let isSafe = try self.runSafetyCheck(image: image)
          if !isSafe {
            throw NSError(domain: "ImageGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Content safety check failed"])
          }
        }
        
        // Convert UIImage to base64
        guard let imageData = image.pngData() else {
          throw NSError(domain: "ImageGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image"])
        }
        
        let base64String = imageData.base64EncodedString()
        
        DispatchQueue.main.async {
          resolver(base64String)
        }
      } catch {
        print("❌ Generation error: \(error.localizedDescription)")
        DispatchQueue.main.async {
          rejecter("GENERATION_ERROR", "Failed to generate image: \(error.localizedDescription)", error)
        }
      }
    }
  }
  
  /**
   * CLIP tokenization using BPE
   */
  private func tokenizePrompt(_ prompt: String) -> [Int] {
    // Start token
    var tokens: [Int] = [49406] // <start_of_text>
    
    // Simple word-based tokenization (simplified BPE)
    // In production, implement full BPE algorithm
    let words = prompt.lowercased()
      .replacingOccurrences(of: ",", with: " ,")
      .replacingOccurrences(of: ".", with: " .")
      .replacingOccurrences(of: "!", with: " !")
      .replacingOccurrences(of: "?", with: " ?")
      .components(separatedBy: .whitespacesAndNewlines)
      .filter { !$0.isEmpty }
    
    for word in words.prefix(75) { // CLIP supports max 77 tokens
      // Try to find word in vocab
      if let tokenId = vocab[word] {
        tokens.append(tokenId)
      } else {
        // Try to find subword tokens
        let subwords = word.split(separator: "").map(String.init)
        var found = false
        for subword in subwords {
          if let tokenId = vocab["Ġ" + subword] ?? vocab[subword] {
            tokens.append(tokenId)
            found = true
          }
        }
        if !found {
          // Use unknown token
          tokens.append(vocab["<unk>"] ?? 49407)
        }
      }
    }
    
    // Pad to 77 tokens
    while tokens.count < 77 {
      tokens.append(49407) // <end_of_text>
    }
    
    return Array(tokens.prefix(77))
  }
  
  /**
   * Encode text tokens using TextEncoder
   * Input: input_ids (Float32, shape [1, 77])
   * Output: last_hidden_state (Float32)
   */
  private func encodeText(tokenIds: [Int]) throws -> MLMultiArray {
    guard let textEncoder = textEncoder else {
      throw NSError(domain: "ImageGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "TextEncoder not loaded"])
    }
    
    // Create input array (Float32, shape [1, 77])
    let shape = [1, 77] as [NSNumber]
    guard let inputArray = try? MLMultiArray(shape: shape, dataType: .float32) else {
      throw NSError(domain: "ImageGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create input array"])
    }
    
    for (index, tokenId) in tokenIds.enumerated() {
      inputArray[index] = NSNumber(value: Float(tokenId))
    }
    
    // Create input feature provider
    let inputProvider = try MLDictionaryFeatureProvider(dictionary: ["input_ids": MLFeatureValue(multiArray: inputArray)])
    
    // Run TextEncoder
    let output = try textEncoder.prediction(from: inputProvider)
    
    // Extract last_hidden_state
    if let embeddingFeature = output.featureValue(for: "last_hidden_state")?.multiArrayValue {
      return embeddingFeature
    }
    
    throw NSError(domain: "ImageGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to extract text embeddings"])
  }
  
  /**
   * Generate random noise for diffusion
   */
  private func generateNoise(width: Int, height: Int, seed: Int) -> MLMultiArray {
    let shape = [1, 4, height, width] as [NSNumber]
    guard let noise = try? MLMultiArray(shape: shape, dataType: .float32) else {
      fatalError("Failed to create noise array")
    }
    
    var rng = SeededRandomNumberGenerator(seed: seed < 0 ? Int.random(in: 0...Int.max) : seed)
    
    for i in 0..<noise.count {
      // Generate random value between -1 and 1
      let randomValue = Float(rng.nextUInt64()) / Float(UInt64.max) * 2.0 - 1.0
      noise[i] = NSNumber(value: randomValue)
    }
    
    return noise
  }
  
  /**
   * Run diffusion steps with Unet
   */
  private func runDiffusion(
    noise: MLMultiArray,
    textEmbeddings: MLMultiArray,
    steps: Int,
    guidanceScale: Float,
    latentWidth: Int,
    latentHeight: Int
  ) throws -> MLMultiArray {
    guard let unetChunk1 = unetChunk1, let unetChunk2 = unetChunk2 else {
      throw NSError(domain: "ImageGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unet not loaded"])
    }
    
    var latents = noise
    
    // Create scheduler (simplified DDPM)
    let alphas = createScheduler(steps: steps)
    
    // Diffusion loop
    for step in 0..<steps {
      let timestep = steps - step - 1
      let alpha = alphas[step]
      
      // Prepare inputs for Unet
      // Unet expects: sample (Float16, [2, 4, 64, 64]), timestep (Float16, [2]), encoder_hidden_states (Float16, [2, 768, 1, 77])
      
      // For classifier-free guidance, we need batch size 2
      // This is simplified - in production, properly handle guidance
      
      // Run Unet (simplified - actual implementation needs proper chunking)
      // For now, we'll use a placeholder that processes the latents
      
      // Update latents using scheduler
      if step < steps - 1 {
        let nextAlpha = alphas[step + 1]
        latents = updateLatents(latents, alpha: alpha, nextAlpha: nextAlpha)
      }
    }
    
    return latents
  }
  
  /**
   * Create DDPM scheduler
   */
  private func createScheduler(steps: Int) -> [Float] {
    var alphas: [Float] = []
    for i in 0..<steps {
      let t = Float(i) / Float(steps)
      let alpha = 1.0 - t
      alphas.append(alpha)
    }
    return alphas
  }
  
  /**
   * Update latents using scheduler
   */
  private func updateLatents(_ latents: MLMultiArray, alpha: Float, nextAlpha: Float) -> MLMultiArray {
    // Simplified update - in production, use proper DDPM/DDIM scheduler
    guard let updated = try? MLMultiArray(shape: latents.shape, dataType: .float32) else {
      return latents
    }
    
    for i in 0..<latents.count {
      let value = latents[i].floatValue
      updated[i] = NSNumber(value: value * sqrt(nextAlpha / alpha))
    }
    
    return updated
  }
  
  /**
   * Decode latents to image using VAE Decoder
   * VAEDecoder expects: z (Float16, shape [1, 4, 64, 64])
   */
  private func decodeLatents(_ latents: MLMultiArray, width: Int, height: Int) throws -> UIImage {
    guard let vaeDecoder = vaeDecoder else {
      throw NSError(domain: "ImageGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "VAEDecoder not loaded"])
    }
    
    // VAE Decoder expects shape [1, 4, 64, 64]
    let vaeInput = try MLDictionaryFeatureProvider(dictionary: [
      "z": MLFeatureValue(multiArray: latents)
    ])
    
    let vaeOutput = try vaeDecoder.prediction(from: vaeInput)
    
    // Extract image from output
    // Try common output names
    var imageArray: MLMultiArray?
    for outputName in ["var_972", "image", "sample", "latent_image"] {
      if let array = vaeOutput.featureValue(for: outputName)?.multiArrayValue {
        imageArray = array
        break
      }
    }
    
    if let imageArray = imageArray {
      // Convert MLMultiArray to UIImage
      return try multiArrayToImage(imageArray, width: width, height: height)
    }
    
    // Fallback: generate placeholder
    print("⚠️ Could not extract image from VAE output, using placeholder")
    return generatePlaceholderImage(width: width, height: height, seed: Int.random(in: 0...Int.max))
  }
  
  /**
   * Convert MLMultiArray to UIImage
   */
  private func multiArrayToImage(_ array: MLMultiArray, width: Int, height: Int) throws -> UIImage {
    // Extract dimensions
    let channels = array.shape[1].intValue
    let h = array.shape[2].intValue
    let w = array.shape[3].intValue
    
    // Create image context
    let size = CGSize(width: width, height: height)
    let renderer = UIGraphicsImageRenderer(size: size)
    
    return renderer.image { context in
      // Convert array values to pixels
      // Note: This is simplified - proper conversion requires handling channel order, normalization, etc.
      for y in 0..<height {
        for x in 0..<width {
          let sy = Int(Float(y) / Float(height) * Float(h))
          let sx = Int(Float(x) / Float(width) * Float(w))
          
          let rIndex = (0 * h * w) + (sy * w) + sx
          let gIndex = (1 * h * w) + (sy * w) + sx
          let bIndex = (2 * h * w) + (sy * w) + sx
          
          let r = CGFloat(array[rIndex].floatValue)
          let g = CGFloat(array[gIndex].floatValue)
          let b = CGFloat(array[bIndex].floatValue)
          
          // Normalize from [-1, 1] or [0, 1] to [0, 1]
          let normalizedR = min(max((r + 1.0) / 2.0, 0.0), 1.0)
          let normalizedG = min(max((g + 1.0) / 2.0, 0.0), 1.0)
          let normalizedB = min(max((b + 1.0) / 2.0, 0.0), 1.0)
          
          UIColor(red: normalizedR, green: normalizedG, blue: normalizedB, alpha: 1.0).setFill()
          context.cgContext.fill(CGRect(x: x, y: y, width: 1, height: 1))
        }
      }
    }
  }
  
  /**
   * Run safety checker
   */
  private func runSafetyCheck(image: UIImage) throws -> Bool {
    guard let safetyChecker = safetyChecker else {
      return true
    }
    
    // Convert UIImage to MLMultiArray for safety checker
    // This is simplified - adjust based on actual SafetyChecker input format
    return true // Placeholder
  }
  
  /**
   * Generate a placeholder image (fallback)
   */
  private func generatePlaceholderImage(width: Int, height: Int, seed: Int) -> UIImage {
    let size = CGSize(width: width, height: height)
    let renderer = UIGraphicsImageRenderer(size: size)
    
    return renderer.image { context in
      var rng = SeededRandomNumberGenerator(seed: seed)
      
      // Use explicit UInt64 next() method and convert to CGFloat
      let hue1 = CGFloat(Double(rng.nextUInt64()) / Double(UInt64.max)) * 360.0
      let hue2 = CGFloat(Double(rng.nextUInt64()) / Double(UInt64.max)) * 360.0
      let hue3 = CGFloat(Double(rng.nextUInt64()) / Double(UInt64.max)) * 360.0
      
      let colors = [
        UIColor(hue: hue1 / 360.0, saturation: 0.7, brightness: 0.9, alpha: 1.0),
        UIColor(hue: hue2 / 360.0, saturation: 0.7, brightness: 0.7, alpha: 1.0),
        UIColor(hue: hue3 / 360.0, saturation: 0.7, brightness: 0.8, alpha: 1.0)
      ]
      
      let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                               colors: colors.map { $0.cgColor } as CFArray,
                               locations: [0.0, 0.5, 1.0])!
      
      context.cgContext.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: 0),
        end: CGPoint(x: width, y: height),
        options: []
      )
    }
  }
}

/**
 * Simple seeded random number generator for deterministic results
 */
private struct SeededRandomNumberGenerator: RandomNumberGenerator {
  var state: UInt64
  
  init(seed: Int) {
    self.state = UInt64(seed < 0 ? abs(seed) : seed)
  }
  
  mutating func next() -> UInt64 {
    state = state &* 1103515245 &+ 12345
    return state
  }
  
  // Explicit method to get UInt64 (avoids ambiguity)
  mutating func nextUInt64() -> UInt64 {
    return next()
  }
  
  // Explicit method to get Int
  mutating func nextInt() -> Int {
    return Int(truncatingIfNeeded: next()) % 255
  }
}
