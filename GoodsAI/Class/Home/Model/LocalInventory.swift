//
//  InventoryItem.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/12.
//

import Foundation
import CloudKit
import UIKit

struct LocalInventory: Identifiable {
    let id: CKRecord.ID
    let barCode: String
    let productName: String
    let price: Double
    let quantityInStock: Int
    let thumbImage: UIImage?

       init(record: CKRecord) {
           self.id = record.recordID
           self.barCode = record["barcode"] as? String ?? ""
           self.productName = record["productName"] as? String ?? ""
           self.price = record["price"] as? Double ?? 0.0
           self.quantityInStock = record["quantityInStock"] as? Int ?? 0
           // 解析 CKAsset 为 UIImage
           if let asset = record["thumbImage"] as? CKAsset,
              let data = try? Data(contentsOf: asset.fileURL!) {
               self.thumbImage = UIImage(data: data)
           } else {
               self.thumbImage = nil
           }
       }
}
