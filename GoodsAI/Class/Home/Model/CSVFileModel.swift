//
//  CSVFileModel.swift
//  GoodsAI
//
//  Created by Emily on 2025/3/12.
//

import Foundation

import SwiftCSV
import UIKit

struct DataModel {
    var id = UUID()
    let barCode: String
//    let productName: String
//    let price: String
//    let inventory: String
    var thumbImage: UIImage?  
}

// Extension to create a namespace for app-wide functions
// This allows calling parseCSV as InventoryIQ.parseCSV()
enum InventoryIQ {
    // Parse CSV and process image columns
    static func parseCSV(filePath: URL, completion: @escaping ([InventoryItem]) -> Void) {
        // Delegate to the free function implementation
        parseCSV(filePath: filePath, completion: completion)
    }
}

// Parse CSV and process image columns
func parseCSV(filePath: URL,completion: @escaping ([InventoryItem]) -> Void) {
    
    var allInventory:[InventoryItem] = []

    do {
        let csv = try CSV<Named>(url: filePath)
        try csv.enumerateAsDict { rowDict in
            guard let imageField = rowDict["thumbImage"] else { return }
            
            // Choose processing method based on storage type
            let image: UIImage?
            if imageField.hasPrefix("http") {
                image = loadImageFromURL(urlString: imageField)  // Network image loading ‌:ml-citation{ref="4" data="citationList"}
            } else if let data = Data(base64Encoded: imageField) {
                image = UIImage(data: data)  // Base64 decoding ‌:ml-citation{ref="7" data="citationList"}
            } else {
                image = UIImage(named: imageField)  // Local path loading ‌:ml-citation{ref="4" data="citationList"}
            }
            
            let barcode = rowDict["barcode"] ?? ""
            
            let productName = rowDict["productName"] ?? ""
            let productPrice = Double(rowDict["productPrice"] ?? "0.0")
            let quantityInStock = Int(rowDict["quantityInStock"] ?? "0")
            let thumbImage = image

            let model = InventoryItem(barcode:barcode, productName: productName, productPrice: productPrice ?? 0.0, imageData: nil, quantityInStock: quantityInStock ?? 0, thumbImage: thumbImage)
            allInventory.append(model)
            // Store or display model
        }
        completion(allInventory)
        
    } catch {
        print("CSV parsing failed: \(error)")
    }
}



func parseCSVFile(filePath: String) -> [[String: String]] {
    var records: [[String: String]] = []
    do {
        let csvData = try String(contentsOfFile: filePath)
        let csv = try CSV<Named>(string: csvData)
        
        
        try csv.enumerateAsDict { rowDict in
            var record = [String: String]()
            for (index, element) in rowDict.enumerated() {
//                if let header = csv.header[index] {
////                    record[header] = element
//                } else {
//                    // Handle cases without header information, such as extra row information, etc.
//                }
            }
            records.append(record)
        }
        
 
    } catch {
        print("Error parsing CSV file: \(error)")
    }
    return records
}














/// Extract ID from DISPIMG string
func extractImageID(from dispimgString: String) -> String? {
    let pattern = #"DISPIMG$\"(.+?)\",\s*\d+$"#  // Regular expression pattern
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    
    let matches = regex.matches(in: dispimgString, range: NSRange(dispimgString.startIndex..., in: dispimgString))
    guard let match = matches.first, match.numberOfRanges > 1 else { return nil }
    
    let idRange = Range(match.range(at: 1), in: dispimgString)!
    return String(dispimgString[idRange])
}

// Load image from URL
private func loadImageFromURL(urlString: String) -> UIImage? {
    guard let url = URL(string: urlString),
          let data = try? Data(contentsOf: url) else { return nil }
    return UIImage(data: data)
}
