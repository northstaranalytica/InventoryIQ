//
//  InventoryItem.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/12.
//

import Foundation
import UIKit

struct InventoryItem: Identifiable, Codable {
    let id: String // Using barcode as the unique identifier
    var barcode: String
    var productName: String
    var productPrice: Double
    var imageData: Data?
    var embedding: [Float]? // Vector embedding for the image
    var quantityInStock: Int // quantity in stock
    
    // Properties not stored directly
    var thumbImage: UIImage? // thumbImage
    var score: Double? // Similarity score for search results
    
    // CodingKeys to exclude non-Codable properties
    enum CodingKeys: String, CodingKey {
        case id, barcode, productName, productPrice, imageData, embedding, quantityInStock
    }
    
    init(barcode: String, productName: String, productPrice: Double, imageData: Data?, embedding: [Float]? = nil, quantityInStock: Int, thumbImage: UIImage?) {
        self.id = barcode
        self.barcode = barcode
        self.productName = productName
        self.productPrice = productPrice
        self.imageData = imageData
        self.embedding = embedding
        self.quantityInStock = quantityInStock
        self.thumbImage = thumbImage
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(barcode, forKey: .barcode)
        try container.encode(productName, forKey: .productName)
        try container.encode(productPrice, forKey: .productPrice)
        try container.encode(imageData, forKey: .imageData)
        try container.encode(embedding, forKey: .embedding)
        try container.encode(quantityInStock, forKey: .quantityInStock)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        barcode = try container.decode(String.self, forKey: .barcode)
        productName = try container.decode(String.self, forKey: .productName)
        productPrice = try container.decode(Double.self, forKey: .productPrice)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        embedding = try container.decodeIfPresent([Float].self, forKey: .embedding)
        quantityInStock = try container.decode(Int.self, forKey: .quantityInStock)
        
        // Set thumbImage from imageData if available
        if let imageData = imageData {
            thumbImage = UIImage(data: imageData)
        } else {
            thumbImage = nil
        }
    }
    
    var image: UIImage? {
        if let imageData = imageData {
            return UIImage(data: imageData)
        }
        return nil
    }
}
