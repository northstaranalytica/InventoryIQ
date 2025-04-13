import UIKit
import Foundation
import Vision
import CoreML
import os.log

class DatabaseManager {
    static let shared = DatabaseManager()
    
    // Add a logger for debugging
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.findmystuff", category: "VectorDebug")
    
    private var inventoryItems: [String: InventoryItem] = [:] // Dictionary with barcode as key
    private var imageVectors: [String: [Float]] = [:] // Dictionary with barcode as key for vector storage
    
    // CLIP model properties
    private var imageEncoder: MLModel?
    private var textEncoder: MLModel?
    private let vectorDimension = 512 // Dimension for CLIP embeddings
    
    // Debug flag to control verbose logging
    var debugVectorization = true
    
    // Dictionary to store similarity scores for debugging
    private var debugSimilarityScores: [String: Float] = [:]
    
    // UserDefaults keys
    private let itemsStorageKey = "com.goodsai.inventoryItems"
    private let vectorsStorageKey = "com.goodsai.imageVectors"
    
    private init() {
        // Load CLIP models
        loadCLIPModels()
        
        // Load stored data
        loadStoredData()
    }
    
    // MARK: - Data Persistence
    
    private func loadStoredData() {
        if let itemsData = UserDefaults.standard.data(forKey: itemsStorageKey) {
            do {
                let decoder = JSONDecoder()
                // Using a dictionary [String: Data] to store serialized InventoryItems
                let serializedItems = try decoder.decode([String: Data].self, from: itemsData)
                
                // Deserialize each item
                for (barcode, itemData) in serializedItems {
                    do {
                        let item = try decoder.decode(InventoryItem.self, from: itemData)
                        self.inventoryItems[barcode] = item
                    } catch {
                        self.logger.error("Failed to decode item with barcode \(barcode): \(error.localizedDescription)")
                    }
                }
                
                self.logger.info("Loaded \(self.inventoryItems.count) items from local storage")
            } catch {
                self.logger.error("Failed to load items from UserDefaults: \(error.localizedDescription)")
            }
        }
        
        if let vectorsData = UserDefaults.standard.data(forKey: vectorsStorageKey) {
            do {
                let decoder = JSONDecoder()
                self.imageVectors = try decoder.decode([String: [Float]].self, from: vectorsData)
                self.logger.info("Loaded \(self.imageVectors.count) image vectors from local storage")
            } catch {
                self.logger.error("Failed to load vectors from UserDefaults: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveItemsToStorage() {
        do {
            let encoder = JSONEncoder()
            
            // Create a dictionary to store serialized items
            var serializedItems: [String: Data] = [:]
            
            // Serialize each item
            for (barcode, item) in self.inventoryItems {
                do {
                    let itemData = try encoder.encode(item)
                    serializedItems[barcode] = itemData
                } catch {
                    self.logger.error("Failed to encode item with barcode \(barcode): \(error.localizedDescription)")
                }
            }
            
            // Save serialized items dictionary
            let itemsData = try encoder.encode(serializedItems)
            UserDefaults.standard.set(itemsData, forKey: itemsStorageKey)
            
            // Save vectors dictionary
            let vectorsData = try encoder.encode(self.imageVectors)
            UserDefaults.standard.set(vectorsData, forKey: vectorsStorageKey)
            
            UserDefaults.standard.synchronize()
            self.logger.info("Saved \(self.inventoryItems.count) items and \(self.imageVectors.count) vectors to local storage")
        } catch {
            self.logger.error("Failed to save data to UserDefaults: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Item Management
    
    func saveItem(item: InventoryItem, completion: @escaping (Result<InventoryItem, Error>) -> Void) {
        var newItem = item
        
        // Generate embedding for the item's image if available
        if let imageData = item.imageData {
            if let embedding = generateCLIPEmbedding(for: imageData) {
                newItem.embedding = embedding
                self.imageVectors[item.barcode] = embedding
                self.logger.info("Generated embedding for item \(item.barcode)")
            } else {
                self.logger.error("Failed to generate embedding for item \(item.barcode)")
            }
        }
        
        // Save to local storage
        self.inventoryItems[newItem.barcode] = newItem
        
        // Persist changes
        saveItemsToStorage()
        
        // Return success with the new item
        completion(.success(newItem))
    }
    
    func updateItem(item: InventoryItem, completion: @escaping (Result<InventoryItem, Error>) -> Void) {
        var updatedItem = item
        
        // Generate new embedding if the image has changed
        if let imageData = item.imageData {
            if let embedding = generateCLIPEmbedding(for: imageData) {
                updatedItem.embedding = embedding
                self.imageVectors[item.barcode] = embedding
                self.logger.info("Updated embedding for item \(item.barcode)")
            }
        }
        
        // Update local storage
        self.inventoryItems[updatedItem.barcode] = updatedItem
        
        // Persist changes
        saveItemsToStorage()
        
        // Return success with the updated item
        completion(.success(updatedItem))
    }
    
    func deleteItem(barcode: String, completion: @escaping (Bool) -> Void) {
        // Remove from local storage
        self.inventoryItems.removeValue(forKey: barcode)
        self.imageVectors.removeValue(forKey: barcode)
        
        // Persist changes
        saveItemsToStorage()
        
        completion(true)
    }
    
    func getAllItems(completion: @escaping ([InventoryItem]) -> Void) {
        // Return all items sorted by name
        let items = Array(self.inventoryItems.values).sorted { $0.productName < $1.productName }
        completion(items)
    }
    
    // MARK: - CLIP Models Loading
    
    private func loadCLIPModels() {
        // Try to load the models from the app bundle
        if let imageEncoderURL = Bundle.main.url(forResource: "ImageEncoder_mobileCLIP_s2", withExtension: "mlmodelc"),
           let textEncoderURL = Bundle.main.url(forResource: "TextEncoder_mobileCLIP_s2", withExtension: "mlmodelc") {
            do {
                self.imageEncoder = try MLModel(contentsOf: imageEncoderURL)
                self.textEncoder = try MLModel(contentsOf: textEncoderURL)
                print("CLIP models loaded successfully from bundle")
                return
            } catch {
                print("Error loading CLIP models from bundle: \(error)")
            }
        } else {
            print("CLIP models not found in bundle, trying alternative paths")
        }
        
        // Try to load models from various paths
        let fileManager = FileManager.default
        
        // Define potential base directories to search
        var potentialBasePaths: [URL] = []
        
        // Add current directory
        potentialBasePaths.append(URL(fileURLWithPath: fileManager.currentDirectoryPath))
        
        // Add bundle resource URL
        if let bundleURL = Bundle.main.resourceURL {
            potentialBasePaths.append(bundleURL)
        }
        
        // Add document directory
        if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            potentialBasePaths.append(documentDirectory)
        }
        
        // Add application support directory
        if let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            potentialBasePaths.append(appSupportDirectory)
        }
        
        // Print all paths we're checking for debugging
        print("Searching for images directory in the following paths:")
        for path in potentialBasePaths {
            print("- \(path.path)")
        }
        
        // Search each potential parent directory
        for parentPath in potentialBasePaths.compactMap({ $0 }) {
            let imagesURL = parentPath.appendingPathComponent("images")
            if FileManager.default.fileExists(atPath: imagesURL.path) {
                print("Found images directory at: \(imagesURL.path)")
                return
            }
            
            // Also try searching one level up
            let parentDirURL = parentPath.deletingLastPathComponent()
            let imagesURLUp = parentDirURL.appendingPathComponent("images")
            if FileManager.default.fileExists(atPath: imagesURLUp.path) {
                print("Found images directory at: \(imagesURLUp.path)")
                return
            }
        }
        
        // If we're in a simulator, try to create the images directory in the documents folder
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let imagesDirectory = documentsDirectory.appendingPathComponent("images")
            
            // Check if directory exists, if not try to create it
            if !FileManager.default.fileExists(atPath: imagesDirectory.path) {
                print("Images directory not found. Attempting to create at: \(imagesDirectory.path)")
                do {
                    try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
                    print("Created images directory at: \(imagesDirectory.path)")
                    
                    // Generate sample images for the simulator
                    createSampleImagesInDirectory(imagesDirectory)
                    
                    return
                } catch {
                    print("Failed to create images directory: \(error)")
                }
            } else {
                // Check if the directory is empty and create sample images if needed
                do {
                    let contents = try FileManager.default.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: nil)
                    if contents.isEmpty {
                        print("Images directory is empty. Creating sample images.")
                        createSampleImagesInDirectory(imagesDirectory)
                    }
                } catch {
                    print("Error checking directory contents: \(error)")
                }
                
                return
            }
        }
        
        print("Could not find or create images directory")
    }
    
    // Helper function to create sample images in the simulator
    private func createSampleImagesInDirectory(_ directory: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Create a few sample colored images
            let colors: [(name: String, color: UIColor)] = [
                ("red", UIColor.red),
                ("green", UIColor.green),
                ("blue", UIColor.blue),
                ("yellow", UIColor.yellow),
                ("orange", UIColor.orange),
                ("purple", UIColor.purple),
                ("black", UIColor.black),
                ("white", UIColor.white)
            ]
            
            for (name, color) in colors {
                // Create a colored image
                let size = CGSize(width: 200, height: 200)
                UIGraphicsBeginImageContextWithOptions(size, false, 0)
                color.setFill()
                UIRectFill(CGRect(origin: .zero, size: size))
                
                // Add some text to the image
                let text = name.uppercased()
                let textAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 30),
                    .foregroundColor: color == UIColor.white || color == UIColor.yellow ? UIColor.black : UIColor.white
                ]
                
                let textSize = text.size(withAttributes: textAttributes)
                let textRect = CGRect(
                    x: (size.width - textSize.width) / 2,
                    y: (size.height - textSize.height) / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                
                text.draw(in: textRect, withAttributes: textAttributes)
                
                if let image = UIGraphicsGetImageFromCurrentImageContext(),
                   let imageData = image.jpegData(compressionQuality: 0.9) {
                    UIGraphicsEndImageContext()
                    
                    // Save the image to the directory
                    let imageURL = directory.appendingPathComponent("sample_\(name).jpg")
                    do {
                        try imageData.write(to: imageURL)
                        print("Created sample image: \(imageURL.lastPathComponent)")
                    } catch {
                        print("Error saving sample image \(name): \(error)")
                    }
                } else {
                    UIGraphicsEndImageContext()
                    print("Failed to create image data for \(name)")
                }
            }
            
            print("Finished creating sample images")
        }
    }
    
    // Add the findImagesDirectory function before the loadMockImagesFromDirectory method
    private func findImagesDirectory() -> URL? {
        let fileManager = FileManager.default
        
        // Define potential base directories to search
        var potentialBasePaths: [URL] = []
        
        // Add current directory
        potentialBasePaths.append(URL(fileURLWithPath: fileManager.currentDirectoryPath))
        
        // Add bundle resource URL
        if let bundleURL = Bundle.main.resourceURL {
            potentialBasePaths.append(bundleURL)
        }
        
        // Add document directory
        if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            potentialBasePaths.append(documentDirectory)
        }
        
        // Add application support directory
        if let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            potentialBasePaths.append(appSupportDirectory)
        }
        
        // Search each potential parent directory
        for parentPath in potentialBasePaths {
            let imagesURL = parentPath.appendingPathComponent("images")
            if FileManager.default.fileExists(atPath: imagesURL.path) {
                print("Found images directory at: \(imagesURL.path)")
                return imagesURL
            }
            
            // Also try searching one level up
            let parentDirURL = parentPath.deletingLastPathComponent()
            let imagesURLUp = parentDirURL.appendingPathComponent("images")
            if FileManager.default.fileExists(atPath: imagesURLUp.path) {
                print("Found images directory at: \(imagesURLUp.path)")
                return imagesURLUp
            }
        }
        
        // If not found, try to create in documents directory
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let imagesDirectory = documentsDirectory.appendingPathComponent("images")
            
            // Check if directory exists, if not try to create it
            if !FileManager.default.fileExists(atPath: imagesDirectory.path) {
                print("Images directory not found. Attempting to create at: \(imagesDirectory.path)")
                do {
                    try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
                    print("Created images directory at: \(imagesDirectory.path)")
                    return imagesDirectory
                } catch {
                    print("Failed to create images directory: \(error)")
                }
            } else {
                return imagesDirectory
            }
        }
        
        return nil
    }
    
    func loadMockImagesFromDirectory() {
        // Try to get the URL for the images directory from the bundle
        var imagesDirectoryURL: URL?
        
        // Print debug information about the current environment
        DispatchQueue.main.async {
            print("Current directory path: \(FileManager.default.currentDirectoryPath)")
            if let bundleURL = Bundle.main.resourceURL {
                print("Bundle resource URL: \(bundleURL)")
            }
            if let executableURL = Bundle.main.executableURL {
                print("Executable URL: \(executableURL)")
            }
        }
        
        // First try to find the images directory in the bundle
        if let bundleURL = Bundle.main.resourceURL?.appendingPathComponent("images") {
            if FileManager.default.fileExists(atPath: bundleURL.path) {
                imagesDirectoryURL = bundleURL
                DispatchQueue.main.async {
                    print("Found images directory in bundle")
                }
            }
        }
        
        // If not found in bundle, try to find it relative to the executable
        if imagesDirectoryURL == nil {
            if let executableURL = Bundle.main.executableURL {
                let potentialURL = executableURL.deletingLastPathComponent().appendingPathComponent("images")
                if FileManager.default.fileExists(atPath: potentialURL.path) {
                    imagesDirectoryURL = potentialURL
                    DispatchQueue.main.async {
                        print("Found images directory relative to executable")
                    }
                }
            }
        }
        
        // If still not found, try to find it in the current working directory
        if imagesDirectoryURL == nil {
            let currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            let potentialURL = currentDirectoryURL.appendingPathComponent("images")
            if FileManager.default.fileExists(atPath: potentialURL.path) {
                imagesDirectoryURL = potentialURL
                DispatchQueue.main.async {
                    print("Found images directory in current working directory")
                }
            }
        }
        
        // Try a direct path to the workspace (for development purposes)
        if imagesDirectoryURL == nil {
            // Use findImagesDirectory helper instead of hardcoded path
            imagesDirectoryURL = findImagesDirectory()
            if imagesDirectoryURL != nil {
                DispatchQueue.main.async {
                    print("Found images directory using findImagesDirectory helper")
                }
            }
        }
        
        // Try using the helper function to search for the images directory
        if imagesDirectoryURL == nil {
            imagesDirectoryURL = findImagesDirectory()
        }
        
        // Check if we found the directory
        guard let imagesDirectoryURL = imagesDirectoryURL else {
            DispatchQueue.main.async {
                print("Could not find images directory")
            }
            return
        }
        
        // Check if the directory is empty and wait a bit for sample images to be created
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: imagesDirectoryURL, includingPropertiesForKeys: nil)
            if contents.isEmpty {
                print("Images directory is empty. Waiting for sample images to be created...")
                // Create sample images
                createSampleImagesInDirectory(imagesDirectoryURL)
                // Wait a bit for the sample images to be created
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.loadImagesFromDirectory(imagesDirectoryURL)
                }
                return
            }
        } catch {
            print("Error checking directory contents: \(error)")
        }
        
        // If directory has contents, load images immediately
        loadImagesFromDirectory(imagesDirectoryURL)
    }
    
    // Load mock images directly from the workspace path
    func loadMockImagesFromWorkspace() {
        // Use findImagesDirectory helper instead of hardcoded path
        guard let imagesDirectoryURL = findImagesDirectory() else {
            DispatchQueue.main.async {
                print("Could not find images directory")
            }
            return
        }
        
        print("Attempting to load images from: \(imagesDirectoryURL.path)")
        
        if !FileManager.default.fileExists(atPath: imagesDirectoryURL.path) {
            DispatchQueue.main.async {
                print("Directory does not exist at: \(imagesDirectoryURL.path)")
            }
            return
        }
        
        // Check if the directory is empty and wait a bit for sample images to be created
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: imagesDirectoryURL, includingPropertiesForKeys: nil)
            if contents.isEmpty {
                print("Images directory is empty. Waiting for sample images to be created...")
                // Wait a bit for the sample images to be created
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.loadImagesFromDirectory(imagesDirectoryURL)
                }
                return
            }
        } catch {
            print("Error checking directory contents: \(error)")
        }
        
        // If directory has contents, load images immediately
        loadImagesFromDirectory(imagesDirectoryURL)
    }
    
    // Helper method to load images from a directory
    private func loadImagesFromDirectory(_ imagesDirectoryURL: URL) {
        // Create a secure bookmark for the directory
        _ = secureBookmarkForURL(imagesDirectoryURL)
        
        // Use a background queue for the file operations
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Get all files in the directory
                let fileURLs = try FileManager.default.contentsOfDirectory(at: imagesDirectoryURL, includingPropertiesForKeys: nil)
                
                // Filter for image files
                let imageURLs = fileURLs.filter { $0.pathExtension.lowercased() == "jpg" || $0.pathExtension.lowercased() == "jpeg" || $0.pathExtension.lowercased() == "png" }
                
                DispatchQueue.main.async {
                    print("Found \(imageURLs.count) images in the directory")
                }
                
                if imageURLs.isEmpty {
                    DispatchQueue.main.async {
                        print("No images found in directory. Trying to create sample images...")
                        self.createSampleImagesInDirectory(imagesDirectoryURL)
                        
                        // Try loading again after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.loadImagesFromDirectory(imagesDirectoryURL)
                        }
                    }
                    return
                }
                
                // Process each image
                for (index, imageURL) in imageURLs.enumerated() {
                    // Create a secure bookmark for each image file
                    _ = self.secureBookmarkForURL(imageURL)
                    
                    do {
                        // Load image data
                        let imageData = try Data(contentsOf: imageURL)
                        
                        // Generate a mock barcode based on the filename
                        let filename = imageURL.lastPathComponent
                        let barcode = "MOCK-\(filename)-\(index)"
                        
                        // Create inventory item with mock data
//                        let inventoryItem = InventoryItem(
//                            barcode: barcode,
//                            productName: "Mock Item \(filename)",
//                            productPrice: Double(arc4random_uniform(10000)) / 100.0, // Random price between $0 and $100
//                            imageData: imageData
//                        )
                        
                        // steve  update
                        let inventoryItem = InventoryItem(
                            barcode: barcode,
                            productName: "Mock Item \(filename)",
                            productPrice: Double(arc4random_uniform(10000)) / 100.0, // Random price between $0 and $100
                            imageData: imageData,
                            quantityInStock:10,
                            thumbImage: nil
                        )
                        // Store the item and update UI on the main thread
                        DispatchQueue.main.async {
                            // Store the item
                            self.inventoryItems[barcode] = inventoryItem
                            
                            // Generate and store embedding for the image
                            if let embedding = self.generateCLIPEmbedding(for: imageData) {
                                self.imageVectors[barcode] = embedding
                                print("Added mock item with barcode: \(barcode)")
                            } else {
                                print("Failed to generate embedding for: \(filename)")
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            print("Error loading image \(imageURL.lastPathComponent): \(error)")
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print("Error reading images directory: \(error)")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateCLIPEmbedding(for imageData: Data) -> [Float]? {
        if debugVectorization {
            self.logger.info("🖼️ Generating vector embedding for image")
        }
        
        guard let imageEncoder = self.imageEncoder,
              let image = UIImage(data: imageData),
              let resizedImage = resizeImage(image, targetSize: CGSize(width: 256, height: 256)),
              let pixelBuffer = pixelBuffer(from: resizedImage) else {
            self.logger.error("❌ Failed to prepare image for vectorization")
            return nil
        }
        
        if debugVectorization {
            self.logger.debug("Image prepared for vectorization: size \(resizedImage.size.width)x\(resizedImage.size.height)")
        }
        
        do {
            // Create input for the model
            let input = try MLDictionaryFeatureProvider(dictionary: ["colorImage": MLFeatureValue(pixelBuffer: pixelBuffer)])
            
            // Get prediction
            let startTime = CFAbsoluteTimeGetCurrent()
            let output = try imageEncoder.prediction(from: input)
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            
            if debugVectorization {
                self.logger.debug("Vectorization completed in \(timeElapsed) seconds")
            }
            
            // Extract embedding from output
            if let embOutput = output.featureValue(for: "embOutput")?.multiArrayValue {
                let count = embOutput.count
                var embedding = [Float](repeating: 0, count: count)
                
                // Check for NaN values while extracting
                var hasNaNValues = false
                for i in 0..<count {
                    let value = embOutput[i].floatValue
                    if value.isNaN {
                        hasNaNValues = true
                        embedding[i] = 0 // Replace NaN with 0
                    } else {
                        embedding[i] = value
                    }
                }
                
                if hasNaNValues && debugVectorization {
                    self.logger.warning("⚠️ NaN values detected in raw embedding and replaced with zeros")
                }
                
                // Normalize the embedding
                let normalizedEmbedding = normalizeVector(embedding)
                
                // Final check for NaN values
                let containsNaN = normalizedEmbedding.contains { $0.isNaN || !$0.isFinite }
                if containsNaN {
                    if debugVectorization {
                        self.logger.error("❌ Normalized embedding contains NaN or infinite values")
                    }
                    // Return a zero vector instead
                    return [Float](repeating: 0, count: count)
                }
                
                if debugVectorization {
                    self.logger.info("✅ Successfully generated image vector with dimension \(normalizedEmbedding.count)")
                }
                
                return normalizedEmbedding
            }
        } catch {
            self.logger.error("❌ Error generating CLIP embedding: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    private func generateTextEmbedding(for text: String) -> [Float]? {
        if debugVectorization {
            self.logger.info("📝 Generating vector embedding for text: \"\(text)\"")
        }
        
        guard let textEncoder = self.textEncoder else {
            self.logger.error("❌ Text encoder model not available")
            return nil
        }
        
        do {
            // Tokenize the text (simplified - in a real implementation, you'd use a proper tokenizer)
            let tokens = tokenizeText(text)
            
            if debugVectorization {
                self.logger.debug("Text tokenized with \(tokens.count) tokens")
            }
            
            // Create a multi-array for the tokens
            let tokenArray = try MLMultiArray(shape: [1, 77], dataType: .int32)
            
            // Fill the array with tokens
            for (i, token) in tokens.enumerated() {
                if i < 77 {
                    tokenArray[i] = NSNumber(value: token)
                }
            }
            
            // Create input for the model
            let input = try MLDictionaryFeatureProvider(dictionary: ["input_tokens": MLFeatureValue(multiArray: tokenArray)])
            
            // Get prediction
            let startTime = CFAbsoluteTimeGetCurrent()
            let output = try textEncoder.prediction(from: input)
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            
            if debugVectorization {
                self.logger.debug("Text vectorization completed in \(timeElapsed) seconds")
                
                // Log available output feature names for debugging
                let featureNames = output.featureNames
                if !featureNames.isEmpty {
                    self.logger.debug("Available output features: \(featureNames)")
                }
            }
            
            // Extract embedding from output
            if let embOutput = output.featureValue(for: "text_embeddings")?.multiArrayValue {
                let count = embOutput.count
                var embedding = [Float](repeating: 0, count: count)
                
                // Check for NaN values while extracting
                var hasNaNValues = false
                for i in 0..<count {
                    let value = embOutput[i].floatValue
                    if value.isNaN {
                        hasNaNValues = true
                        embedding[i] = 0 // Replace NaN with 0
                    } else {
                        embedding[i] = value
                    }
                }
                
                if hasNaNValues && debugVectorization {
                    self.logger.warning("⚠️ NaN values detected in raw text embedding and replaced with zeros")
                }
                
                // Normalize the embedding
                let normalizedEmbedding = normalizeVector(embedding)
                
                // Final check for NaN values
                let containsNaN = normalizedEmbedding.contains { $0.isNaN || !$0.isFinite }
                if containsNaN {
                    if debugVectorization {
                        self.logger.error("❌ Normalized text embedding contains NaN or infinite values")
                    }
                    // Return a zero vector instead
                    return [Float](repeating: 0, count: count)
                }
                
                if debugVectorization {
                    self.logger.info("✅ Successfully generated text vector with dimension \(normalizedEmbedding.count)")
                }
                
                return normalizedEmbedding
            }
        } catch {
            self.logger.error("❌ Error generating text embedding: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    // Simplified tokenization - in a real implementation, you'd use a proper tokenizer
    private func tokenizeText(_ text: String) -> [Int32] {
        // Try multiple approaches to load the vocabulary file
        var vocab: [String: Int]?
        
        // Approach 1: Try loading from bundle resources
        if let vocabURL = Bundle.main.url(forResource: "vocab", withExtension: "json", subdirectory: "CoreMLModels"),
           let vocabData = try? Data(contentsOf: vocabURL) {
            vocab = try? JSONSerialization.jsonObject(with: vocabData) as? [String: Int]
            if vocab != nil {
                self.logger.info("✅ Loaded vocabulary file from bundle resources")
            }
        }
        
        // Approach 2: Try loading from various potential locations
        if vocab == nil {
            let fileManager = FileManager.default
            
            // Define potential base directories to search
            var potentialBasePaths: [URL] = []
            
            // Add current directory
            potentialBasePaths.append(URL(fileURLWithPath: fileManager.currentDirectoryPath))
            
            // Add bundle resource URL
            if let bundleURL = Bundle.main.resourceURL {
                potentialBasePaths.append(bundleURL)
            }
            
            // Add document directory
            if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                potentialBasePaths.append(documentDirectory)
            }
            
            // Add application support directory
            if let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                potentialBasePaths.append(appSupportDirectory)
            }
            
            // Define relative paths to check in each base directory
            let relativeVocabPaths = [
                "CoreMLModels/vocab.json",
                "vocab.json",
                "../CoreMLModels/vocab.json"
            ]
            
            // Generate all potential paths for the vocabulary file
            var potentialVocabPaths: [URL] = []
            for basePath in potentialBasePaths {
                for relativePath in relativeVocabPaths {
                    potentialVocabPaths.append(basePath.appendingPathComponent(relativePath))
                }
            }
            
            print("Searching for vocabulary file in the following paths:")
            for vocabPath in potentialVocabPaths {
                print("- \(vocabPath.path)")
                if fileManager.fileExists(atPath: vocabPath.path) {
                    print("File exists at: \(vocabPath.path)")
                    do {
                        let vocabData = try Data(contentsOf: vocabPath)
                        print("Loaded \(vocabData.count) bytes of vocab data")
                        let loadedVocab = try JSONSerialization.jsonObject(with: vocabData) as? [String: Int]
                        if let loadedVocab = loadedVocab {
                            vocab = loadedVocab
                            print("Successfully parsed vocab with \(loadedVocab.count) entries")
                            self.logger.info("✅ Loaded vocabulary file from: \(vocabPath.path)")
                            break
                        } else {
                            print("Failed to parse vocab.json as [String: Int] dictionary")
                        }
                    } catch {
                        print("Error loading or parsing vocab.json: \(error)")
                    }
                }
            }
        }
        
        // If vocabulary still couldn't be loaded, use default tokens
        guard let vocab = vocab else {
            self.logger.error("❌ Failed to load vocabulary file from all attempted locations")
            return defaultTokens()
        }
        
        // Initialize tokens array with zeros
        var tokens = [Int32](repeating: 0, count: 77)
        
        // Add start token
        tokens[0] = 49406 // Start token for CLIP
        
        // Tokenize the text
        // Simple whitespace tokenization for demonstration
        let words = text.lowercased().split(separator: " ")
        var tokenIndex = 1 // Start after the start token
        
        for word in words {
            if tokenIndex >= 76 { break } // Leave room for end token
            
            // Try to find the word in vocabulary
            if let tokenId = vocab[String(word)] {
                tokens[tokenIndex] = Int32(tokenId)
                tokenIndex += 1
            } else {
                // If word not found, try character by character
                for char in word {
                    if tokenIndex >= 76 { break }
                    let charStr = String(char)
                    if let tokenId = vocab[charStr] {
                        tokens[tokenIndex] = Int32(tokenId)
                        tokenIndex += 1
                    }
                }
            }
        }
        
        // Add end token
        tokens[76] = 49407 // End token for CLIP
        
        if debugVectorization {
            self.logger.debug("Tokenized '\(text)' into \(tokenIndex) tokens")
        }
        
        return tokens
    }
    
    // Default tokens when vocabulary loading fails
    private func defaultTokens() -> [Int32] {
        var tokens = [Int32](repeating: 0, count: 77)
        tokens[0] = 49406 // Start token
        tokens[76] = 49407 // End token
        return tokens
    }
    
    // Utility function to resize an image
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        // First, resize the image to fill the target size while maintaining aspect ratio
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Use the larger ratio to ensure the image fills the target dimensions
        let scaleFactor = max(widthRatio, heightRatio)
        let scaledWidth = size.width * scaleFactor
        let scaledHeight = size.height * scaleFactor
        
        // Calculate positioning to center the image
        let x = (targetSize.width - scaledWidth) / 2.0
        let y = (targetSize.height - scaledHeight) / 2.0
        
        // Create a context with the target size
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0)
        
        // Draw the scaled image centered in the context
        image.draw(in: CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    // Convert UIImage to CVPixelBuffer
    private func pixelBuffer(from image: UIImage) -> CVPixelBuffer? {
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, nil, &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        let data = CVPixelBufferGetBaseAddress(buffer)
        
        let context = CGContext(
            data: data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        
        context?.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: width, height: height))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        
        return buffer
    }
    
    // Calculate cosine similarity between two vectors
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count && a.count > 0 else { 
            if debugVectorization {
                self.logger.error("❌ Vector dimension mismatch: \(a.count) vs \(b.count)")
            }
            return 0 
        }
        
        // Filter out NaN values by replacing them with zeros
        let validA = a.map { $0.isNaN || !$0.isFinite ? 0 : $0 }
        let validB = b.map { $0.isNaN || !$0.isFinite ? 0 : $0 }
        
        var dotProduct: Float = 0
        var magnitudeA: Float = 0
        var magnitudeB: Float = 0
        
        for i in 0..<validA.count {
            dotProduct += validA[i] * validB[i]
            magnitudeA += validA[i] * validA[i]
            magnitudeB += validB[i] * validB[i]
        }
        
        magnitudeA = sqrt(magnitudeA)
        magnitudeB = sqrt(magnitudeB)
        
        if magnitudeA == 0 || magnitudeB == 0 || !magnitudeA.isFinite || !magnitudeB.isFinite {
            if debugVectorization {
                self.logger.error("❌ Zero or invalid magnitude vector detected")
            }
            return 0
        }
        
        let similarity = dotProduct / (magnitudeA * magnitudeB)
        
        // Ensure the result is valid
        return similarity.isFinite ? similarity : 0
    }
    
    // Normalize a vector to unit length
    private func normalizeVector(_ vector: [Float]) -> [Float] {
        var magnitude: Float = 0
        
        // Check for NaN values in the input vector
        let validVector = vector.map { $0.isNaN ? 0 : $0 }
        
        for value in validVector {
            magnitude += value * value
        }
        
        magnitude = sqrt(magnitude)
        
        if magnitude == 0 || !magnitude.isFinite {
            if debugVectorization {
                self.logger.warning("⚠️ Attempted to normalize zero vector or encountered invalid magnitude")
            }
            // Return a zero vector of the same length instead of the original vector
            return [Float](repeating: 0, count: vector.count)
        }
        
        // Ensure no NaN or infinite values are returned
        return validVector.map { 
            let normalized = $0 / magnitude
            return normalized.isFinite ? normalized : 0
        }
    }
    
    // MARK: - Debug Helpers
    
    /// Logs a sample of vector values for debugging
    private func logVector(_ label: String, vector: [Float]) {
        guard debugVectorization else { return }
        
        // Calculate vector statistics
        let sum = vector.reduce(0, +)
        let mean = sum / Float(vector.count)
        let minValue = vector.min() ?? 0
        let maxValue = vector.max() ?? 0
        
        // Log vector statistics
        self.logger.info("📊 \(label) - Stats: count=\(vector.count), mean=\(mean), min=\(minValue), max=\(maxValue)")
        
        // Log a sample of the vector (first 5, middle 5, last 5)
        var sampleLog = "📊 \(label) - Sample values:\n"
        
        // First 5 values
        sampleLog += "  Start: "
        for i in 0..<min(5, vector.count) {
            sampleLog += String(format: "%.4f ", vector[i])
        }
        
        // Middle 5 values
        if vector.count > 10 {
            let midStart = max(5, (vector.count / 2) - 2)
            sampleLog += "\n  Middle: "
            for i in midStart..<min(midStart + 5, vector.count) {
                sampleLog += String(format: "%.4f ", vector[i])
            }
        }
        
        // Last 5 values
        if vector.count > 5 {
            sampleLog += "\n  End: "
            for i in max(0, vector.count - 5)..<vector.count {
                sampleLog += String(format: "%.4f ", vector[i])
            }
        }
        
        self.logger.debug("\(sampleLog)")
    }
    
    // MARK: - Debug Methods
    
    /// Generate image embedding for debugging purposes
    func generateCLIPEmbeddingForDebug(for imageData: Data) -> [Float]? {
        return generateCLIPEmbedding(for: imageData)
    }
    
    /// Generate text embedding for debugging purposes
    func generateTextEmbeddingForDebug(for text: String) -> [Float]? {
        return generateTextEmbedding(for: text)
    }
    
    /// Calculate cosine similarity for debugging purposes
    func calculateCosineSimilarityForDebug(_ a: [Float], _ b: [Float]) -> Float {
        return cosineSimilarity(a, b)
    }
    
    /// Get vector for a specific barcode (for debugging)
    func getVectorForBarcode(_ barcode: String) -> [Float]? {
        return self.imageVectors[barcode]
    }
    
    // Helper method to safely access file URLs
    private func secureBookmarkForURL(_ url: URL) -> Data? {
        do {
            let bookmarkData = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            return bookmarkData
        } catch {
            print("[ERROR] Could not create a bookmark: \(error)")
            return nil
        }
    }
    
    // MARK: - Inventory Management Methods
    
    /// Get all inventory items from the database
    func getAllInventoryItems() -> [InventoryItem] {
        // Return all inventory items as an array
        return Array(self.inventoryItems.values)
    }
    
    /// Add a new inventory item to the database
    func addInventoryItem(barcode: String, productName: String, productPrice: Double, imageData: Data?, quantityInStock: Int, thumbImage: UIImage?) -> InventoryItem {
        // Create a new inventory item
        let newItem = InventoryItem(
            barcode: barcode,
            productName: productName,
            productPrice: productPrice,
            imageData: imageData,
            recordID: nil,
            embedding: nil,
            quantityInStock: quantityInStock,
            thumbImage: thumbImage
        )
        
        // Save the item using our new method
        saveItem(item: newItem) { _ in }
        
        // Return the item for backward compatibility
        return newItem
    }
    
    /// Delete an inventory item from the database
    func deleteInventoryItem(barcode: String) -> Bool {
        // Check if the item exists
        guard self.inventoryItems[barcode] != nil else {
            print("Failed to delete item: Item with barcode \(barcode) not found")
            return false
        }
        
        // Remove the item from our dictionary
        self.inventoryItems.removeValue(forKey: barcode)
        
        // Remove the embedding if it exists
        self.imageVectors.removeValue(forKey: barcode)
        
        print("Deleted item with barcode: \(barcode)")
        return true
    }
    
    /// Update an existing inventory item in the database
    func updateInventoryItem(barcode: String, productName: String, productPrice: Double, imageData: Data?) -> InventoryItem? {
        // Check if the item exists
        guard self.inventoryItems[barcode] != nil else {
            print("Failed to update item: Item with barcode \(barcode) not found")
            return nil
        }
        
        // Generate embedding for the image if available
        var embedding: [Float]? = nil
        if let imageData = imageData {
            embedding = generateCLIPEmbedding(for: imageData)
        }
        
        // Create an updated inventory item
        let updatedItem = InventoryItem(
            barcode: barcode,
            productName: productName,
            productPrice: productPrice,
            imageData: imageData,
            embedding: embedding,
            quantityInStock:10,
            thumbImage: nil
        )
        
        // Store the updated item in our dictionary
        self.inventoryItems[barcode] = updatedItem
        
        // Store the embedding if available
        if let embedding = embedding {
            self.imageVectors[barcode] = embedding
        }
        
        print("Updated item: \(productName) with barcode: \(barcode)")
        return updatedItem
    }
    
    /// Find similar items to the given image data
    func findSimilarItems(to imageData: Data, limit: Int = 5) -> [InventoryItem] {
        // Generate embedding for the query image
        guard let queryEmbedding = generateCLIPEmbedding(for: imageData) else {
            print("Failed to generate embedding for query image, returning random items instead")
            return getRandomItems(limit: limit)
        }
        
        // If we have no vectors to compare against, return random items
        if self.imageVectors.isEmpty {
            print("No image vectors available, returning random items instead")
            return getRandomItems(limit: limit)
        }
        
        // Calculate similarity scores for all items
        var similarityScores: [(barcode: String, score: Float)] = []
        
        for (barcode, vector) in self.imageVectors {
            let similarity = cosineSimilarity(queryEmbedding, vector)
            similarityScores.append((barcode: barcode, score: similarity))
        }
        
        // Sort by similarity score (highest first)
        similarityScores.sort { $0.score > $1.score }
        
        // Take the top 'limit' results
        let topResults = similarityScores.prefix(limit)
        
        // Convert to inventory items
        var result: [InventoryItem] = []
        for (barcode, score) in topResults {
            if var item = self.inventoryItems[barcode] {
                item.score = Double(score)
                result.append(item)
                
                if debugVectorization {
                    print("Similar item: \(item.productName), score: \(score)")
                }
            }
        }
        
        // If we couldn't find any items, return random ones
        if result.isEmpty {
            print("No similar items found, returning random items instead")
            return getRandomItems(limit: limit)
        }
        
        return result
    }
    
    /// Find similar items using text query
    func findSimilarItemsByText(query: String, limit: Int = 5) -> [InventoryItem] {
        // Generate embedding for the text query
        guard let queryEmbedding = generateTextEmbedding(for: query) else {
            print("Failed to generate embedding for text query: \(query), returning random items instead")
            return getRandomItems(limit: limit)
        }
        
        // If we have no vectors to compare against, return random items
        if self.imageVectors.isEmpty {
            print("No image vectors available, returning random items instead")
            return getRandomItems(limit: limit)
        }
        
        // Calculate similarity scores for all items
        var similarityScores: [(barcode: String, score: Float)] = []
        
        print(self.imageVectors.count)
        for (barcode, vector) in self.imageVectors {
            let similarity = cosineSimilarity(queryEmbedding, vector)
            similarityScores.append((barcode: barcode, score: similarity))
        }
        
        // Sort by similarity score (highest first)
        similarityScores.sort { $0.score > $1.score }
        
        // Take the top 'limit' results
        let topResults = similarityScores.prefix(limit)
        
        // Convert to inventory items
        var result: [InventoryItem] = []
        for (barcode, score) in topResults {
            if var item = self.inventoryItems[barcode] {
                item.score = Double(score)
                result.append(item)
                
                if debugVectorization {
                    print("Text match: \(item.productName), score: \(score)")
                }
            }
        }
        
        // If we couldn't find any items, return random ones
        if result.isEmpty {
            print("No similar items found by text, returning random items instead")
            return getRandomItems(limit: limit)
        }
        
        return result
    }
    
    /// Helper method to get random items when vector search fails
    private func getRandomItems(limit: Int) -> [InventoryItem] {
        let allItems = Array(self.inventoryItems.values)
        
        // If we have no items at all, return an empty array
        if allItems.isEmpty {
            return []
        }
        
        // If we have fewer items than the limit, return all of them
        if allItems.count <= limit {
            return allItems
        }
        
        // Otherwise, return a random selection
        var randomItems: [InventoryItem] = []
        var availableIndices = Array(0..<allItems.count)
        
        for _ in 0..<limit {
            if availableIndices.isEmpty {
                break
            }
            
            let randomIndex = Int.random(in: 0..<availableIndices.count)
            let itemIndex = availableIndices.remove(at: randomIndex)
            randomItems.append(allItems[itemIndex])
        }
        
        return randomItems
    }
} 
