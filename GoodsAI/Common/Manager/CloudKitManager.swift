//
//  CloudKitManager.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/13.
//

import Foundation
import CloudKit
import UIKit


class CloudKitManager {
    
    let container = CKContainer.default()
    private var publicDB: CKDatabase?
    @Published var products: [LocalInventory] = []
    var allInventory:[InventoryItem] = []

    
    
    // Static constant shared instance (thread-safe)
    static let shared = CloudKitManager()
    // Private initialization method to prevent external instance creation
    private init() {
        initCKContainer()
    }
    
    // Example method
    private func initCKContainer() {
        publicDB = container.publicCloudDatabase
        checkICloudStatus()
    }

    private func checkICloudStatus() {
        container.accountStatus { status, error in
            guard status == .available else {
                print("iCloud not logged in or unavailable")
                return
            }
        }
    }

    
    // MARK: - Save data method
    func saveNote(note: InventoryItem, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        // 1. Create CKRecord
        let record = CKRecord(recordType: "Note") // Must match Record Type name in Dashboard
        // 2. Set field values (types must match Dashboard definition)
        record["barcode"] = note.barcode as CKRecordValue
        record["productName"] = note.productName as CKRecordValue
        record["price"] = note.productPrice as CKRecordValue
        record["quantityInStock"] = note.quantityInStock as CKRecordValue
        record["timestamp"] = Date().timeIntervalSince1970 as CKRecordValue // Use timestamp instead of creationDate
       
        if((note.thumbImage) != nil){
            guard let imageAsset = createImageAsset(image: note.thumbImage!) else {
                // Image error
                ProgressTools.showError("Image error, please change the image!")
                return
            }
            record["thumbImage"] = imageAsset as CKRecordValue
        }
        
        
        // 4. Execute save operation
        publicDB?.save(record) { savedRecord, error in
            if let error = error {
                // Check if it's a recordName error - silence these specific errors
                if !error.localizedDescription.contains("recordName") {
                    print("Save failed: \(error.localizedDescription)")
                }
                completion(.failure(error))
                return
            }
            guard let savedRecord = savedRecord else {
                completion(.failure(CKError(.unknownItem)))
                return
            }
            // Don't need to log successful saves
            completion(.success(savedRecord))
        }
    }
    
    
    
    func deleteRecord(recordID: CKRecord.ID,completion: @escaping (Bool) -> Void) {
        let operation = CKModifyRecordsOperation(
            recordsToSave: nil,
            recordIDsToDelete: [recordID]
        )
        operation.configuration.qualityOfService = .userInitiated
        operation.modifyRecordsCompletionBlock = { (_, deletedIDs, error) in
            if let error = error {
                print("Delete failed: \(error.localizedDescription)")
                completion(false)
            } else if let ids = deletedIDs {
                print("Successfully deleted records: \(ids)")
                completion(true)
            }
        }
        
        // 4. Execute operation
        publicDB?.add(operation)
    }
    
    
    
    func fetchProducts(completion: @escaping ([LocalInventory]) -> Void) {
          let predicate = NSPredicate(value: true) // Query all records
          let query = CKQuery(recordType: "Note", predicate: predicate)
          
          // Use timestamp for sorting instead of creationDate
          query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
          
          let operation = CKQueryOperation(query: query)
          var loadedProducts: [LocalInventory] = []

        if #available(iOS 15.0, *) {
            operation.recordMatchedBlock = { recordID, result in
                switch result {
                case .success(let record):
                    let product = LocalInventory(record: record)
                    loadedProducts.append(product)
                case .failure(let error):
                    // Silently handle errors - don't log them to console
                    if !error.localizedDescription.contains("recordName") {
                        print("Parse record failed: \(error.localizedDescription)")
                    }
                }
            }
            
            operation.queryResultBlock = { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        self?.products = loadedProducts
                        completion(loadedProducts)
                    case .failure(let error):
                        if !error.localizedDescription.contains("recordName") {
                            print("Query failed: \(error.localizedDescription)")
                        }
                        // Still call completion with empty array on error
                        completion([])
                    }
                }
            }
        } else {
            // Fallback on earlier versions
            // For iOS 14 and below, use old API
            operation.recordFetchedBlock = { record in
                let product = LocalInventory(record: record)
                loadedProducts.append(product)
            }
            
            operation.queryCompletionBlock = { [weak self] cursor, error in
                DispatchQueue.main.async {
                    if let error = error {
                        if !error.localizedDescription.contains("recordName") {
                            print("Query failed: \(error.localizedDescription)")
                        }
                        // Call completion with empty array on error
                        completion([])
                    } else {
                        self?.products = loadedProducts
                        completion(loadedProducts)
                    }
                }
            }
        }

        publicDB?.add(operation)
      }
    
    
    
    
    func createImageAsset(image: UIImage) -> CKAsset? {
        // 1. Convert UIImage to Data (compression quality adjustable)
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            print("Image conversion failed")
            return nil
        }
        // 2. Create temporary file path (avoid filename conflicts)
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".jpg" // Unique filename
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        // 3. Write to temporary file
        do {
            try imageData.write(to: fileURL)
            return CKAsset(fileURL: fileURL)
        } catch {
            print("Temporary file write failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Update data method
    func updateNote(note: InventoryItem, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let recordID = note.recordID else {
            completion(.failure(NSError(domain: "CloudKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No record ID found"])))
            return
        }
        
        // Fetch the record first
        let operation = CKFetchRecordsOperation(recordIDs: [recordID])
        
        operation.fetchRecordsCompletionBlock = { [weak self] recordsDict, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let record = recordsDict?[recordID] else {
                completion(.failure(NSError(domain: "CloudKitManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Record not found"])))
                return
            }
            
            // Update record with new values
            record["productName"] = note.productName as CKRecordValue
            record["price"] = note.productPrice as CKRecordValue
            record["quantityInStock"] = note.quantityInStock as CKRecordValue
            record["timestamp"] = Date().timeIntervalSince1970 as CKRecordValue // Update timestamp
            
            // If thumbnail image has changed, update it
            if let thumbImage = note.thumbImage {
                if let imageAsset = self.createImageAsset(image: thumbImage) {
                    record["thumbImage"] = imageAsset as CKRecordValue
                }
            }
            
            // Save the updated record
            self.publicDB?.save(record) { _, error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
        
        publicDB?.add(operation)
    }
    
}
