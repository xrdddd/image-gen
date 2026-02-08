//
// ImageGenerationModule.swift
// Native iOS module using Apple's Stable Diffusion Swift package
// This replaces the manual implementation with Apple's official framework
//

import Foundation
import CoreML
import UIKit
import StableDiffusion
import Compression

@objc(ImageGenerationModule)
class ImageGenerationModule: RCTEventEmitter {
  
  private var pipeline: StableDiffusionPipeline?
  private var isModelReady = false
  private var modelsBasePath: String?
  private var progressTimer: Timer?
  
  // Required for RCTEventEmitter
  override static func requiresMainQueueSetup() -> Bool {
    return false
  }
  
  // Define events that can be sent to JavaScript
  override func supportedEvents() -> [String]! {
    return ["onGenerationProgress"]
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
        
        // Consolidate models before loading (copy missing models from bundle to Documents)
        let consolidatedPath = try self.consolidateModels(targetPath: cleanPath)
        let baseURL = URL(fileURLWithPath: consolidatedPath)
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
        
        let totalSteps = steps.intValue
        let startTime = Date()
        var isGenerating = true
        
        // Start progress reporting - estimate based on elapsed time
        // Since Apple's framework doesn't expose step-by-step progress,
        // we estimate based on typical generation time (roughly 1-2 seconds per step)
        // Run timer on main thread to ensure events are sent properly
        DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }
          
          self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] timer in
            guard let self = self, isGenerating else {
              timer.invalidate()
              return
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            // Estimate: each step takes roughly 1-2 seconds depending on device
            // Use a conservative estimate of 1.5 seconds per step
            let estimatedTimePerStep = 1.5
            let estimatedProgress = min(95, Int((elapsed / (Double(totalSteps) * estimatedTimePerStep)) * 100))
            let estimatedStep = min(totalSteps, Int((elapsed / estimatedTimePerStep)))
            
            print("📊 Sending progress: step \(estimatedStep)/\(totalSteps), progress: \(estimatedProgress)%, elapsed: \(Int(elapsed))s")
            
            // Send progress event to JavaScript
            self.sendEvent(withName: "onGenerationProgress", body: [
              "step": estimatedStep,
              "totalSteps": totalSteps,
              "progress": estimatedProgress,
              "elapsed": Int(elapsed)
            ])
          }
          
          // Add timer to run loop
          if let timer = self.progressTimer {
            RunLoop.current.add(timer, forMode: .common)
          }
        }
        
        // Generate image using Apple's framework
        let images = try pipeline.generateImages(configuration: generationConfig)
        
        // Stop progress timer
        isGenerating = false
        DispatchQueue.main.async { [weak self] in
          self?.progressTimer?.invalidate()
        }
        
        // Send final progress (100%)
        let totalElapsed = Int(Date().timeIntervalSince(startTime))
        print("📊 Sending final progress: 100%")
        DispatchQueue.main.async { [weak self] in
          self?.sendEvent(withName: "onGenerationProgress", body: [
            "step": totalSteps,
            "totalSteps": totalSteps,
            "progress": 100,
            "elapsed": totalElapsed
          ])
        }
        
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
  
  /**
   * Extract tar.gz archive to a directory
   * Returns the path to the extracted directory
   */
  @objc
  func extractTarGz(_ tarGzPath: String, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
    let workItem = DispatchWorkItem {
      do {
        // Remove file:// prefix if present, as URL(fileURLWithPath:) expects a file path, not a URL string
        var cleanPath = tarGzPath
        if cleanPath.hasPrefix("file://") {
          cleanPath = String(cleanPath.dropFirst(7))  // Remove "file://" prefix
        }
        
        let tarGzURL = URL(fileURLWithPath: cleanPath)
        
        // Verify file exists
        guard FileManager.default.fileExists(atPath: cleanPath) else {
          rejecter("FILE_NOT_FOUND", "tar.gz file not found at: \(cleanPath)", nil)
          return
        }
        
        print("📦 Extracting tar.gz: \(tarGzPath)")
        
        // Determine output directory (same directory as tar.gz, without .tar.gz extension)
        let outputDir = tarGzURL.deletingPathExtension().deletingPathExtension() // Remove .tar.gz
        let outputPath = outputDir.path
        
        // Create a temporary directory for extraction first
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
        
        // Read tar.gz file
        let tarGzData = try Data(contentsOf: tarGzURL)
        print("   File size: \(tarGzData.count) bytes")
        
        // Decompress gzip using Compression framework
        let decompressedData = try self.decompressGzip(data: tarGzData)
        print("   Decompressed size: \(decompressedData.count) bytes")
        
        // Extract tar archive to temp directory first
        try self.extractTar(data: decompressedData, to: tempDir)
        
        // Check if tar contains a single top-level directory with the same name as output
        let tempContents = try FileManager.default.contentsOfDirectory(atPath: tempDir.path)
        
        if tempContents.count == 1 {
          let topLevelItem = tempDir.appendingPathComponent(tempContents[0])
          var isDirectory: ObjCBool = false
          if FileManager.default.fileExists(atPath: topLevelItem.path, isDirectory: &isDirectory),
             isDirectory.boolValue {
            // Check if the directory name matches the expected output name
            let expectedName = outputDir.lastPathComponent
            if topLevelItem.lastPathComponent == expectedName {
              // Tar contains a directory with the same name - extract its contents directly
              print("   📁 Tar contains directory '\(expectedName)', extracting contents directly")
              try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true, attributes: nil)
              
              let innerContents = try FileManager.default.contentsOfDirectory(atPath: topLevelItem.path)
              for item in innerContents {
                let sourceItem = topLevelItem.appendingPathComponent(item)
                let destItem = outputDir.appendingPathComponent(item)
                try FileManager.default.moveItem(at: sourceItem, to: destItem)
              }
              
              // Clean up temp directory
              try? FileManager.default.removeItem(at: tempDir)
              
              print("✅ Extracted to: \(outputPath)")
              resolver(outputPath)
              return
            }
          }
        }
        
        // Otherwise, move everything from temp to output
        // Create output directory
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true, attributes: nil)
        
        for item in tempContents {
          let sourceItem = tempDir.appendingPathComponent(item)
          let destItem = outputDir.appendingPathComponent(item)
          try FileManager.default.moveItem(at: sourceItem, to: destItem)
        }
        
        // Clean up temp directory
        try? FileManager.default.removeItem(at: tempDir)
        
        print("✅ Extracted to: \(outputPath)")
        resolver(outputPath)
      } catch {
        print("❌ Extraction error: \(error.localizedDescription)")
        rejecter("EXTRACTION_ERROR", error.localizedDescription, error)
      }
    }
    DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
  }
  
  /**
   * Decompress gzip data using Compression framework
   * Note: Gzip uses deflate compression (similar to zlib) but with additional headers
   */
  private func decompressGzip(data: Data) throws -> Data {
    // Check for gzip magic number (1f 8b)
    if data.count < 2 {
      throw NSError(domain: "Compression", code: -1, userInfo: [NSLocalizedDescriptionKey: "Data too short for gzip"])
    }
    
    let magicBytes = data.prefix(2)
    let isGzip = magicBytes[0] == 0x1f && magicBytes[1] == 0x8b
    
    if !isGzip {
      print("   ⚠️ Warning: File doesn't appear to be gzip format (magic: \(String(format: "%02x %02x", magicBytes[0], magicBytes[1])))")
    }
    
    // For gzip, we need to skip the header (10 bytes minimum) and process the deflate stream
    // Gzip header is: magic (2) + method (1) + flags (1) + mtime (4) + xfl (1) + os (1) = 10 bytes minimum
    // Then optional extra fields, filename, comment, etc.
    // Then the deflate stream starts
    
    var headerOffset = 10 // Minimum header size
    
    // Skip optional fields if present
    if data.count > 3 {
      let flags = data[3]
      if (flags & 0x04) != 0 { // FEXTRA
        if data.count > headerOffset + 2 {
          let xlen = UInt16(data[headerOffset]) | (UInt16(data[headerOffset + 1]) << 8)
          headerOffset += Int(xlen) + 2
        }
      }
      if (flags & 0x08) != 0 { // FNAME
        while headerOffset < data.count && data[headerOffset] != 0 {
          headerOffset += 1
        }
        headerOffset += 1 // Skip null terminator
      }
      if (flags & 0x10) != 0 { // FCOMMENT
        while headerOffset < data.count && data[headerOffset] != 0 {
          headerOffset += 1
        }
        headerOffset += 1 // Skip null terminator
      }
      if (flags & 0x02) != 0 { // FHCRC
        headerOffset += 2 // Skip CRC16
      }
    }
    
    // Extract the deflate stream (skip header and footer)
    // Footer is last 8 bytes: CRC32 (4) + ISIZE (4)
    let footerSize = 8
    let deflateData = data.subdata(in: headerOffset..<(data.count - footerSize))
    
    print("   📊 Gzip header size: \(headerOffset) bytes, deflate data: \(deflateData.count) bytes")
    
    // Now decompress the deflate stream using zlib
    let bufferSize = 1024 * 1024 // 1 MB buffer
    let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    defer { destinationBuffer.deallocate() }
    
    let stream = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
    defer { stream.deallocate() }
    
    var status = compression_stream_init(stream, COMPRESSION_STREAM_DECODE, COMPRESSION_ZLIB)
    guard status == COMPRESSION_STATUS_OK else {
      throw NSError(domain: "Compression", code: Int(status.rawValue), userInfo: [NSLocalizedDescriptionKey: "Failed to initialize compression stream: \(status.rawValue)"])
    }
    defer { compression_stream_destroy(stream) }
    
    var result = Data()
    
    // Process the deflate stream
    deflateData.withUnsafeBytes { sourceBytes in
      stream.pointee.src_ptr = sourceBytes.bindMemory(to: UInt8.self).baseAddress!
      stream.pointee.src_size = deflateData.count
      
      var hasMoreData = true
      while hasMoreData {
        stream.pointee.dst_ptr = destinationBuffer
        stream.pointee.dst_size = bufferSize
        
        // Finalize when all source data is consumed
        let isLastChunk = stream.pointee.src_size == 0
        let flags: Int32 = isLastChunk ? Int32(COMPRESSION_STREAM_FINALIZE.rawValue) : 0
        
        status = compression_stream_process(stream, flags)
        
        let bytesWritten = bufferSize - stream.pointee.dst_size
        if bytesWritten > 0 {
          result.append(destinationBuffer, count: bytesWritten)
        }
        
        if status == COMPRESSION_STATUS_END {
          print("   ✅ Successfully decompressed gzip data: \(result.count) bytes")
          hasMoreData = false
        } else if status != COMPRESSION_STATUS_OK {
          print("   ⚠️ Decompression error, status: \(status.rawValue)")
          hasMoreData = false
        } else if stream.pointee.src_size == 0 {
          // All input consumed, try finalizing
          if !isLastChunk {
            continue // Process again with finalize flag
          }
          hasMoreData = false
        }
      }
    }
    
    if result.count > 0 {
      if status == COMPRESSION_STATUS_END {
        return result
      } else {
        print("   ⚠️ Warning: Decompression completed with status \(status.rawValue), but got \(result.count) bytes")
        return result
      }
    }
    
    throw NSError(domain: "Compression", code: Int(status.rawValue), userInfo: [NSLocalizedDescriptionKey: "Failed to decompress gzip data. Status: \(status.rawValue), Output size: \(result.count)"])
  }
  
  /**
   * Consolidate models: copy missing models from bundle to Documents directory
   * This ensures all models are in one location for Apple's framework
   * Returns the consolidated path (always Documents/models/)
   */
  private func consolidateModels(targetPath: String) throws -> String {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let consolidatedPath = documentsPath.appendingPathComponent("models")
    
    // Create consolidated directory if it doesn't exist
    try FileManager.default.createDirectory(at: consolidatedPath, withIntermediateDirectories: true, attributes: nil)
    
    // Required model components
    let requiredModels = ["TextEncoder.mlmodelc", "UnetChunk1.mlmodelc", "UnetChunk2.mlmodelc", "VAEDecoder.mlmodelc"]
    let requiredFiles = ["vocab.json", "merges.txt"]
    
    // Check bundle path
    var bundleModelPath: String? = nil
    if let resourcePath = Bundle.main.resourcePath {
      // Try ImageGenerate/model/ first
      let path1 = (resourcePath as NSString).appendingPathComponent("ImageGenerate/model")
      if FileManager.default.fileExists(atPath: path1) {
        bundleModelPath = path1
      } else {
        // Try model/ directly
        let path2 = (resourcePath as NSString).appendingPathComponent("model")
        if FileManager.default.fileExists(atPath: path2) {
          bundleModelPath = path2
        }
      }
    }
    
    // Copy missing models from bundle to Documents
    if let bundlePath = bundleModelPath {
      for modelName in requiredModels {
        let consolidatedModelPath = consolidatedPath.appendingPathComponent(modelName)
        
        // Skip if already exists in consolidated location
        if FileManager.default.fileExists(atPath: consolidatedModelPath.path) {
          print("✅ \(modelName) already in Documents")
          continue
        }
        
        // Check if exists in bundle
        let bundleModelPath = (bundlePath as NSString).appendingPathComponent(modelName)
        if FileManager.default.fileExists(atPath: bundleModelPath) {
          // Copy from bundle to Documents
          do {
            try FileManager.default.copyItem(at: URL(fileURLWithPath: bundleModelPath), to: consolidatedModelPath)
            print("📋 Copied \(modelName) from bundle to Documents")
          } catch {
            print("⚠️ Failed to copy \(modelName) from bundle: \(error.localizedDescription)")
            // Continue - maybe it's in Documents already or will be downloaded
          }
        }
      }
      
      // Copy missing files (vocab.json, merges.txt)
      for fileName in requiredFiles {
        let consolidatedFilePath = consolidatedPath.appendingPathComponent(fileName)
        
        // Skip if already exists
        if FileManager.default.fileExists(atPath: consolidatedFilePath.path) {
          continue
        }
        
        // Check if exists in bundle
        let bundleFilePath = (bundlePath as NSString).appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: bundleFilePath) {
          do {
            try FileManager.default.copyItem(at: URL(fileURLWithPath: bundleFilePath), to: consolidatedFilePath)
            print("📋 Copied \(fileName) from bundle to Documents")
          } catch {
            print("⚠️ Failed to copy \(fileName) from bundle: \(error.localizedDescription)")
          }
        }
      }
    }
    
    // Verify all required models are present
    var missingModels: [String] = []
    for modelName in requiredModels {
      let modelPath = consolidatedPath.appendingPathComponent(modelName)
      if !FileManager.default.fileExists(atPath: modelPath.path) {
        missingModels.append(modelName)
      }
    }
    
    if !missingModels.isEmpty {
      throw NSError(domain: "ModelConsolidation", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing required models: \(missingModels.joined(separator: ", "))"])
    }
    
    print("✅ Models consolidated to: \(consolidatedPath.path)")
    return consolidatedPath.path
  }
  
  /**
   * Extract tar archive (UStar format)
   */
  private func extractTar(data: Data, to outputDir: URL) throws {
    var position = 0
    
    while position + 512 <= data.count {
      // Read 512-byte block (tar header)
      let headerData = data.subdata(in: position..<position + 512)
      position += 512
      
      // Check if block is all zeros (end of archive)
      if headerData.allSatisfy({ $0 == 0 }) {
        break
      }
      
      // Parse header
      let header = try parseTarHeader(headerData)
      
      guard !header.name.isEmpty else {
        continue
      }
      
      // Calculate file size
      let fileSize = header.size
      let blocks = (fileSize + 511) / 512 // Round up to 512-byte blocks
      
      // Create file path
      let fileURL = outputDir.appendingPathComponent(header.name)
      
      // Create parent directories
      try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
      
      if header.type == "0" || header.type == "\0" {
        // Regular file
        let fileData = data.subdata(in: position..<position + Int(fileSize))
        try fileData.write(to: fileURL)
        print("   Extracted file: \(header.name) (\(fileSize) bytes)")
      } else if header.type == "5" {
        // Directory
        try FileManager.default.createDirectory(at: fileURL, withIntermediateDirectories: true, attributes: nil)
        print("   Extracted directory: \(header.name)")
      }
      // Skip other types (symlinks, etc.)
      
      position += Int(blocks) * 512
    }
  }
  
  /**
   * Parse tar header (UStar format)
   */
  private func parseTarHeader(_ data: Data) throws -> (name: String, size: UInt64, type: String) {
    // Name (100 bytes)
    let nameData = data.subdata(in: 0..<100)
    let name = String(data: nameData, encoding: .utf8)?.trimmingCharacters(in: CharacterSet(charactersIn: "\0")) ?? ""
    
    // File size (12 bytes, octal)
    let sizeData = data.subdata(in: 124..<136)
    let sizeString = String(data: sizeData, encoding: .utf8)?.trimmingCharacters(in: CharacterSet(charactersIn: "\0 ")) ?? "0"
    let size = UInt64(sizeString, radix: 8) ?? 0
    
    // Type flag (1 byte)
    let typeData = data.subdata(in: 156..<157)
    let type = String(data: typeData, encoding: .utf8) ?? "0"
    
    return (name: name, size: size, type: type)
  }
}
