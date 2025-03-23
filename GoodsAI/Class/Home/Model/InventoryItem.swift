//
//  InventoryItem.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/12.
//

import Foundation
import CloudKit
import UIKit

struct InventoryItem: Identifiable {
    let id: String // Using barcode as the unique identifier
    var barcode: String
    var productName: String
    var productPrice: Double
    var imageData: Data?
    var embedding: [Float]? // Vector embedding for the image
    var recordID: CKRecord.ID? // Vector embedding for the image
  
    var quantityInStock: Int //quantity in stock
    var thumbImage: UIImage?  //thumbImage
    var score: Double?    // 附加字段

    
    
    
    init(barcode: String, productName: String, productPrice: Double, imageData: Data?, recordID: CKRecord.ID? = nil,embedding: [Float]? = nil,quantityInStock:Int,thumbImage:UIImage? ) {
        self.id = barcode
        self.barcode = barcode
        self.productName = productName
        self.productPrice = productPrice
        self.imageData = imageData
        self.embedding = embedding
        
        self.recordID = recordID
        self.quantityInStock = quantityInStock
        self.thumbImage = thumbImage


    }
    
    var image: UIImage? {
        if let imageData = imageData {
            return UIImage(data: imageData)
        }
        return nil
    }
}
