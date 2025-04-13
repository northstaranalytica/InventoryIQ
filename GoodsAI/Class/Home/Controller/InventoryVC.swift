//
//  InventoryVC.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/11.
//

import UIKit
import RxSwift
import MobileCoreServices
import SwiftCSV
class InventoryVC: BaseViewController ,UITableViewDelegate,UITableViewDataSource,UIDocumentPickerDelegate {

    private let disposeBag = DisposeBag()
    var allInventory:[InventoryItem] = []
    var tempInventory:[InventoryItem] = []

    var searchText:String = ""
    var sortOption = SortOption.nameAsc

    // Background
    lazy var searchBgView: UIView = {
        let view = UIView()
        view.backgroundColor = .cColor_F3F3F3
        return view
    }()
    
    private lazy var contentTextFiled: UITextField = {
        let textFiled = UITextField()
        textFiled.placeholder = "Search inventory..."
        textFiled.textAlignment = NSTextAlignment.left
        textFiled.textColor = UIColor.cColor_text_333
        textFiled.font = UIFont.systemFont(ofSize: 14,weight: UIFont.Weight.regular)
        textFiled.borderStyle = .roundedRect
        textFiled.rx.text.orEmpty.changed.subscribe(onNext: { (text) in
            self.searchText = text
            self.tempInventory = self.filteredItems
            self.tableView.reloadData()
           }).disposed(by: disposeBag)
        return textFiled
    }()
    
    private lazy var searchBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(systemName: "arrow.up.arrow.down"), for: .normal)
        btn.setTitleColor(.cColor_Main, for: .normal)
        btn.tag = 1
        btn.addTarget(self, action: #selector(clickSearchAction), for: .touchUpInside)
        // 创建菜单动作
        let actions = [
            UIAction(title: "Name (A-Z)") { _ in
                self.sortOption = SortOption.nameAsc
                self.tempInventory = self.filteredItems
                self.tableView.reloadData()
            },
            UIAction(title: "Name (Z-A)") { _ in
                self.sortOption = SortOption.nameDesc
                self.tempInventory = self.filteredItems
                self.tableView.reloadData()
            },
            UIAction(title: "Price (Low-High)") { _ in
                self.sortOption = SortOption.priceAsc
                self.tempInventory = self.filteredItems
                self.tableView.reloadData()
            },
            UIAction(title: "Price (High-Low)") { _ in
                self.sortOption = SortOption.priceDesc
                self.tempInventory = self.filteredItems
                self.tableView.reloadData()
            }
        ]
        
        // 创建菜单并绑定到按钮
        btn.menu = UIMenu(title: "Sort Menu", children: actions)
        // 设置点击立即显示菜单（默认需要长按）
        btn.showsMenuAsPrimaryAction = true
        return btn
    }()
    
    
    private lazy var tableView: UITableView = {
        let tabView = UITableView(frame: CGRectZero, style: .plain)
        tabView.delegate = self
        tabView.dataSource = self
        tabView.estimatedRowHeight = 200
        tabView.separatorColor = .clear
        tabView.register(GoodsItemTVCell.self, forCellReuseIdentifier:"GoodsItemTVCell")
        if #available(iOS 15.0, *) {
            tabView.sectionHeaderTopPadding = 0
        } else {
            // Fallback on earlier versions
        };
        return tabView
    }()
    
    private func setupNavigationItems() {
        let button1 = UIBarButtonItem(
            image: UIImage(systemName: "folder.badge.plus"),
            primaryAction: UIAction { _ in
                self.importFile()
            }
        )
        let button2 = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            primaryAction: UIAction { _ in
                self.addGoodsToInventory()
            }
        )
        navigationItem.rightBarButtonItems = [button1, button2]
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Inventory"
        self.setupNavigationItems()
        self.view.addSubview(self.searchBgView)
        self.searchBgView.addSubview(self.tableView)
        self.searchBgView.addSubview(self.contentTextFiled)
        self.searchBgView.addSubview(self.searchBtn)
        self.view.addSubview(self.tableView)
        
        self.searchBgView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.right.equalToSuperview()

        }
        
        self.searchBtn.snp.makeConstraints { make in
            make.centerY.equalTo(self.contentTextFiled)
            make.right.equalToSuperview().offset(-20)
            make.width.equalTo(40)
            make.height.equalTo(40)
        }
        
        self.contentTextFiled.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(10)
            make.right.equalTo(self.searchBtn.snp.left).offset(-20)
            make.height.equalTo(36)
            make.bottom.equalToSuperview().offset(-10)
        }


        self.tableView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(self.searchBgView.snp.bottom).offset(10)
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (self.allInventory.isEmpty){
            updateInventory(isUpdateDatabase: false)
        }
    }
    
    
    func updateInventory( isUpdateDatabase:Bool){
        ProgressTools.showLoading("Updating inventory...", self.view)
        CloudKitManager.shared.fetchProducts { [weak self] records in
            guard let self = self else {
                ProgressTools.hide(nil)
                return
            }
            
            // Add a check for empty records
            if records.isEmpty {
                // If no records, just hide the spinner and keep the current items
                ProgressTools.hide(self.view)
                // If we had no items before, we should at least initialize an empty array
                if self.allInventory.isEmpty {
                    self.allInventory = []
                    self.tempInventory = []
                    self.tableView.reloadData()
                }
                return
            }
            
            let allData:[LocalInventory] = records
            var tempData:[InventoryItem] = []
            for good in allData{
                let imageData = good.thumbImage?.jpegData(compressionQuality: 0.8)
                let item = InventoryItem(barcode: good.barCode, productName: good.productName, productPrice: good.price, imageData: imageData,recordID: good.id, quantityInStock: good.quantityInStock, thumbImage: good.thumbImage)
                tempData.append(item)
                if(isUpdateDatabase){
                    DatabaseManager.shared.addInventoryItem(barcode: good.barCode, productName: good.productName, productPrice: good.price, imageData: imageData,quantityInStock: good.quantityInStock, thumbImage: good.thumbImage)
                }
            }
            ProgressTools.hide(self.view)
            self.allInventory = tempData
            self.tempInventory = tempData
            self.tableView.reloadData()
        }
    }

    
    @objc func clickSearchAction(btn: UIButton) {


    }

    private func importFile() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeCommaSeparatedText)], in: .import)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }
    
    
    private func addGoodsToInventory() {
        let secondVC = AddInventoryVC()
        secondVC.blockUpdate = {[weak self] type in
            guard let `self` = self else { return }
            updateInventory(isUpdateDatabase: true)
        }
        self.navigationController?.pushViewController(secondVC, animated: true)
        
    }
    
    
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let filePathURL = urls.first else { return }
        // Process the selected file, e.g. get file content or display images
        print("Selected file URL: \(filePathURL)")
        GoodsAI.parseCSV(filePath: filePathURL) { items in
            self.uploadInventory(note: items)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled")
    }
        
    func uploadInventory(note:[InventoryItem]){
        ProgressTools.showLoading("Importing...",nil)
        let manager = FileUploadManager()
        manager.uploadFiles(
            note,
            eachProgress: { result in
            },
            allComplete: { results in
                DispatchQueue.main.async {
                    ProgressTools.showSuccess(String(results.count)+" items imported successfully")
                    self.updateInventory(isUpdateDatabase: true)
                }
            }
        )
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tempInventory.count
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: 40))
        view.backgroundColor = .cColor_F3F3F3
        let label = UILabel(frame: CGRect(x: 20, y: 12, width: kScreenWidth-80, height: 16))
        label.textColor = UIColor.cColor_text_333
        label.font = UIFont.systemFont(ofSize: 14,weight: UIFont.Weight.semibold)
        label.text = String(self.tempInventory.count)+" items"
        view.addSubview(label)
        return view
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : GoodsItemTVCell = tableView.dequeueReusableCell(withIdentifier: "GoodsItemTVCell", for: indexPath) as! GoodsItemTVCell
        cell.updateInfo(inventoryItem: self.tempInventory[indexPath.row])
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let secondVC = AddInventoryVC()
        secondVC.inventoryItem = self.tempInventory[indexPath.row]
        secondVC.blockUpdate = {[weak self] type in
            guard let `self` = self else { return }
            updateInventory(isUpdateDatabase: true)
        }
        self.navigationController?.pushViewController(secondVC, animated: true)

    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            if(self.allInventory[indexPath.row].recordID != nil){
                ProgressTools.showLoading("Deleting...",nil)
                CloudKitManager.shared.deleteRecord(recordID: self.tempInventory[indexPath.row].recordID!) { result in
                    DispatchQueue.main.async {
                        ProgressTools.showSuccess("Successfully deleted")
                        self.updateInventory(isUpdateDatabase: true)
                    }
                }
            }
        }
    }

    
    
    
    var filteredItems: [InventoryItem] {
        let filtered = searchText.isEmpty ? allInventory : allInventory.filter {
            $0.productName.lowercased().contains(searchText.lowercased()) ||
            $0.barcode.contains(searchText)
        }
        
        switch sortOption {
        case .nameAsc:
            return filtered.sorted { $0.productName < $1.productName }
        case .nameDesc:
            return filtered.sorted { $0.productName > $1.productName }
        case .priceAsc:
            return filtered.sorted { $0.productPrice < $1.productPrice }
        case .priceDesc:
            return filtered.sorted { $0.productPrice > $1.productPrice }
        }
    }
    
    
    

        
        

}

enum SortOption: String, CaseIterable, Identifiable {
    case nameAsc = "Name (A-Z)"
    case nameDesc = "Name (Z-A)"
    case priceAsc = "Price (Low-High)"
    case priceDesc = "Price (High-Low)"
    
    var id: String { self.rawValue }
}
