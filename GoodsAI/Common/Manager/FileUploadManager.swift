//
//  FileUploadManager.swift
//  GoodsAI
//
//  Created by Emily on 2025/3/13.
//

import Foundation

// File upload result structure
struct UploadResult {
    let inventoryItem: InventoryItem
    let isSuccess: Bool
    let error: Error?
}

// Callback type aliases
typealias SingleUploadCallback = ((Result<InventoryItem, Error>)) -> Void
typealias AllCompleteCallback = ([(Result<InventoryItem, Error>)]) -> Void

class FileUploadManager {
    // Serial queue to ensure thread safety
    private let queue = DispatchQueue(label: "com.upload.manager")
    private var currentTasks: [InventoryItem] = []
    private var results: [(Result<InventoryItem, Error>)] = []
    
    /// Batch upload entry method
    func uploadFiles(_ items: [InventoryItem],
                     eachProgress: SingleUploadCallback?,
                     allComplete: @escaping AllCompleteCallback) {
        queue.async {
            // Reset state
            self.currentTasks = items
            self.results.removeAll()
            
            // Start loop upload
            self.processNextFile(index: 0,
                                 eachProgress: eachProgress,
                                 allComplete: allComplete)
        }
    }
    
    // MARK: - Private methods
    private func processNextFile(index: Int,
                                 eachProgress: SingleUploadCallback?,
                                 allComplete: @escaping AllCompleteCallback) {
        queue.async {
            guard index < self.currentTasks.count else {
                // Callback when all tasks are completed
                DispatchQueue.main.async { allComplete(self.results) }
                return
            }
            
            let item = self.currentTasks[index]
            
            // Use DatabaseManager to save the item
            self.saveToLocalStorage(item) { result in
                // Record results
                self.results.append(result)
                
                // Single file completion callback
                DispatchQueue.main.async { eachProgress?(result) }
                
                // Continue processing the next file
                self.processNextFile(index: index + 1,
                                    eachProgress: eachProgress,
                                    allComplete: allComplete)
            }
        }
    }
    
    private func saveToLocalStorage(_ inventoryItem: InventoryItem,
                               completion: @escaping (Result<InventoryItem, Error>) -> Void) {
        
        DatabaseManager.shared.saveItem(item: inventoryItem) { result in
            completion(result)
        }
    }
}

