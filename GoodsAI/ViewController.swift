//
//  ViewController.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/10.
//

import UIKit
import MobileCoreServices
import SwiftCSV

// 自定义数据结构
struct CSVRow: Identifiable {
    var id = UUID()
    let barCode: String
    let productName: String
    let price: String
    let inventory: String

}

class ViewController: UIViewController ,UIDocumentPickerDelegate{

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let myButton = UIButton()
        myButton.frame = CGRect(x: 50, y: 100, width: 200, height: 50) // x, y, width, height
        myButton.setTitle("点击我", for: .normal)
        myButton.setTitleColor(.blue, for: .normal)
        myButton.backgroundColor = .lightGray
        myButton.layer.cornerRadius = 10  // 圆角半径，使按钮更圆润
        myButton.clipsToBounds = true     // 确保圆角效果正确显示
        myButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        self.view.addSubview(myButton)

    }
    
    

    @objc func buttonTapped() {
        print("按钮被点击了！")
        let documentPicker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeCommaSeparatedText)], in: .import)
                documentPicker.delegate = self
                documentPicker.allowsMultipleSelection = false
                present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let filePathURL = urls.first else { return }
            // 处理选中的文件，例如获取文件内容或显示图片等
            print("Selected file URL: \(filePathURL)")
        self.parseCSV(url: filePathURL)
        
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("Document picker was cancelled")
        }

    private func parseCSV(url: URL) {
        
        do {
            let csv = try CSV<Named>(url: url, delimiter: ",", encoding: .utf8)
            //            let csv = try CSV<Named>(url: url)
            // 映射为自定义数据结构
            let rows = csv.rows.compactMap { row -> CSVRow? in
                guard let barCode = row["barCode"],
                      let productName = row["productName"],
                      let price = row["price"],
                      let inventory = row["inventory"],
                      let inventory1 = Int(inventory) else { return nil }
                return CSVRow(barCode: barCode, productName: productName, price: price,inventory: inventory)
            }
            
            DispatchQueue.main.async {
                //                self.cs = rows
            }
            
            //            let csv: CSV = try CSV<Named>(string: "barCode,productName,price,inventory")
            
            //            let rows = csv.rows.compactMap { row -> CSVRow? in
            //                guard let name = row["Name"], let value = row["Value"] else { return nil }
            //                return CSVRow(name: name, value: value)
            //            }
            
            
            
        } catch { /* 错误处理 */
            DispatchQueue.main.async {
                print("解析失败: \(error.localizedDescription)")
            }
        }}

}

