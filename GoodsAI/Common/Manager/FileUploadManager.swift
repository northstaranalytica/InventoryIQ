//
//  FileUploadManager.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/13.
//

import Foundation
import CloudKit

// 文件上传结果结构体
struct UploadResult {
    let inventoryItem: InventoryItem
    let isSuccess: Bool
    let error: Error?
}

// 回调类型别名
typealias SingleUploadCallback = ((Result<CKRecord, Error>)) -> Void
typealias AllCompleteCallback = ([(Result<CKRecord, Error>)]) -> Void

class FileUploadManager {
    // 串行队列保证线程安全
    private let queue = DispatchQueue(label: "com.upload.manager")
    private var currentTasks: [InventoryItem] = []
    private var results: [(Result<CKRecord, Error>)] = []
    
    /// 批量上传入口方法
    func uploadFiles(_ items: [InventoryItem],
                     eachProgress: SingleUploadCallback?,
                     allComplete: @escaping AllCompleteCallback) {
        queue.async {
            // 重置状态
            self.currentTasks = items
            self.results.removeAll()
            
            // 开始循环上传
            self.processNextFile(index: 0,
                                 eachProgress: eachProgress,
                                 allComplete: allComplete)
        }
    }
    
    // MARK: - 私有方法
    private func processNextFile(index: Int,
                                 eachProgress: SingleUploadCallback?,
                                 allComplete: @escaping AllCompleteCallback) {
        queue.async {
            guard index < self.currentTasks.count else {
                // 所有任务完成时回调
                DispatchQueue.main.async { allComplete(self.results) }
                return
            }
            
            let fileURL = self.currentTasks[index]
            
            // 模拟异步上传操作（替换成真实上传逻辑）
            self.mockUploadFile(fileURL) { result in
                // 记录结果
                self.results.append(result)
                
                // 单个文件完成回调
                DispatchQueue.main.async { eachProgress?(result) }
                
                // 继续处理下一个文件
                self.processNextFile(index: index + 1,
                                    eachProgress: eachProgress,
                                    allComplete: allComplete)
            }
        }
    }
    
    // MARK: - 模拟上传实现（替换成真实网络请求）
    private func mockUploadFile(_ inventoryItem: InventoryItem,
                               completion: @escaping (Result<CKRecord, Error>) -> Void) {
        
        CloudKitManager.shared.saveNote(note: inventoryItem,completion: {
            result in
            completion(result)
        })

    }
}

