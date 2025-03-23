//
//  CSVFileModel.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/12.
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

// 解析 CSV 并处理图像列
func parseCSV(filePath: URL,completion: @escaping ([InventoryItem]) -> Void) {
    
    var allInventory:[InventoryItem] = []

    do {
        let csv = try CSV<Named>(url: filePath)
        try csv.enumerateAsDict { rowDict in
            guard let imageField = rowDict["thumbImage"] else { return }
            
            // 根据存储类型选择处理方式
            let image: UIImage?
            if imageField.hasPrefix("http") {
                image = loadImageFromURL(urlString: imageField)  // 网络图片加载 ‌:ml-citation{ref="4" data="citationList"}
            } else if let data = Data(base64Encoded: imageField) {
                image = UIImage(data: data)  // Base64 解码 ‌:ml-citation{ref="7" data="citationList"}
            } else {
                image = UIImage(named: imageField)  // 本地路径加载 ‌:ml-citation{ref="4" data="citationList"}
            }
            
            let barcode = rowDict["barcode"] ?? ""
            
            let productName = rowDict["productName"] ?? ""
            let productPrice = Double(rowDict["productPrice"] ?? "0.0")
            let quantityInStock = Int(rowDict["quantityInStock"] ?? "0")
            let thumbImage = image

            let model = InventoryItem(barcode:barcode, productName: productName, productPrice: productPrice ?? 0.0, imageData: nil, quantityInStock: quantityInStock ?? 0, thumbImage: thumbImage)
            allInventory.append(model)
            // 存储或展示 model
        }
        completion(allInventory)
        
    } catch {
        print("CSV 解析失败: \(error)")
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
//                    // 处理无头信息的情况，例如额外的行信息等。
//                }
            }
            records.append(record)
        }
        
 
    } catch {
        print("Error parsing CSV file: \(error)")
    }
    return records
}














/// 从 DISPIMG 字符串中提取 ID
func extractImageID(from dispimgString: String) -> String? {
    let pattern = #"DISPIMG$\"(.+?)\",\s*\d+$"#  // 正则匹配模式
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    
    let matches = regex.matches(in: dispimgString, range: NSRange(dispimgString.startIndex..., in: dispimgString))
    guard let match = matches.first, match.numberOfRanges > 1 else { return nil }
    
    let idRange = Range(match.range(at: 1), in: dispimgString)!
    return String(dispimgString[idRange])
}

// 从 URL 加载图像
private func loadImageFromURL(urlString: String) -> UIImage? {
    guard let url = URL(string: urlString),
          let data = try? Data(contentsOf: url) else { return nil }
    return UIImage(data: data)
}
