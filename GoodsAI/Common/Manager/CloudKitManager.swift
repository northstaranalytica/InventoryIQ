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

    
    
    // 静态常量共享实例（线程安全）
       static let shared = CloudKitManager()
       // 私有化初始化方法，防止外部创建实例
       private init() {
           initCKContainer()
       }
    
    // 示例方法
    private func initCKContainer() {
        publicDB = container.publicCloudDatabase
        checkICloudStatus()
    }

    private func checkICloudStatus() {
        container.accountStatus { status, error in
            guard status == .available else {
                print("iCloud未登录或不可用")
                return
            }
        }
    }

    
    // MARK: - 保存数据方法
    func saveNote(note: InventoryItem, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        // 1. 创建 CKRecord
        let record = CKRecord(recordType: "Note") // 必须与 Dashboard 中的 Record Type 名称一致
        // 2. 设置字段值（类型需与 Dashboard 定义匹配）
        record["barcode"] = note.barcode as CKRecordValue
        record["productName"] = note.productName as CKRecordValue
        record["price"] = note.productPrice as CKRecordValue
        record["quantityInStock"] = note.quantityInStock as CKRecordValue
       
        if((note.thumbImage) != nil){
            guard let imageAsset = createImageAsset(image: note.thumbImage!) else {
                //  图片错误
                ProgressTools.showError("图片错误，请更换图片！")
                return
            }
            record["thumbImage"] = imageAsset as CKRecordValue
        }
        
        
        // 4. 执行保存操作
        publicDB?.save(record) { savedRecord, error in
            if let error = error {
                print("保存失败: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            guard let savedRecord = savedRecord else {
                completion(.failure(CKError(.unknownItem)))
                return
            }
            print("保存成功，Record ID: \(savedRecord.recordID.recordName)")
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
                print("删除失败: \(error.localizedDescription)")
                completion(false)
            } else if let ids = deletedIDs {
                print("成功删除记录: \(ids)")
                completion(true)
            }
        }
        
        // 4. 执行操作
        publicDB?.add(operation)
    }
    
    
    
    func fetchProducts(completion: @escaping ([LocalInventory]) -> Void) {
          let predicate = NSPredicate(value: true) // 查询所有记录
          let query = CKQuery(recordType: "Note", predicate: predicate)
          let operation = CKQueryOperation(query: query)
//          operation.resultsLimit = 20 // 限制返回数量
          var loadedProducts: [LocalInventory] = []

        if #available(iOS 15.0, *) {
            operation.recordMatchedBlock = { recordID, result in
                switch result {
                case .success(let record):
                    let product = LocalInventory(record: record)
                    loadedProducts.append(product)
                case .failure(let error):
                    print("解析记录失败: \(error.localizedDescription)")
                }
            }
            
            operation.queryResultBlock = { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        self?.products = loadedProducts
                        completion(loadedProducts)
                    case .failure(let error):
                        print("查询失败: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            // Fallback on earlier versions
            // iOS 14 及以下使用旧 API
                    operation.recordFetchedBlock = { record in
                        // 处理获取记录
                    }
                    operation.queryCompletionBlock = { cursor, error in
                        // 处理完成回调
                    }
        }

        publicDB?.add(operation)
      }
    
    
    
    
    func createImageAsset(image: UIImage) -> CKAsset? {
        // 1. 将 UIImage 转为 Data（压缩质量可调整）
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            print("图片转换失败")
            return nil
        }
        // 2. 创建临时文件路径（避免文件名冲突）
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".jpg" // 唯一文件名
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        // 3. 写入临时文件
        do {
            try imageData.write(to: fileURL)
            return CKAsset(fileURL: fileURL)
        } catch {
            print("临时文件写入失败: \(error)")
            return nil
        }
    }
    
    
    
}
