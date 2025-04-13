//
//  FileUploadManager.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/13.
//

import Foundation
import CloudKit

// File upload result structure
struct UploadResult {
    let inventoryItem: InventoryItem
    let isSuccess: Bool
    let error: Error?
}

// Callback type aliases
typealias SingleUploadCallback = ((Result<CKRecord, Error>)) -> Void
typealias AllCompleteCallback = ([(Result<CKRecord, Error>)]) -> Void

class FileUploadManager {
    // Serial queue to ensure thread safety
    private let queue = DispatchQueue(label: "com.upload.manager")
    private var currentTasks: [InventoryItem] = []
    private var results: [(Result<CKRecord, Error>)] = []
    
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
            
            let fileURL = self.currentTasks[index]
            
            // Simulate asynchronous upload operation (replace with real upload logic)
            self.mockUploadFile(fileURL) { result in
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
    
    // MARK: - Mock upload implementation (replace with real network request)
    private func mockUploadFile(_ inventoryItem: InventoryItem,
                               completion: @escaping (Result<CKRecord, Error>) -> Void) {
        
        CloudKitManager.shared.saveNote(note: inventoryItem,completion: {
            result in
            completion(result)
        })

    }
}

