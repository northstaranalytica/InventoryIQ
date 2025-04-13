//
//  DashboardVC.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/13.
//

import UIKit
import RxSwift
import MobileCoreServices

class DashboardVC: BaseViewController, UITableViewDelegate, UITableViewDataSource {

    private let disposeBag = DisposeBag()
    var allInventory: [InventoryItem] = []
    var filteredInventory: [InventoryItem] = []
    
    var searchText: String = ""
    var sortOption = SortOption.nameAsc
    
    private lazy var choicePhotoTools: ChoicePhotoTools = {
        let object = ChoicePhotoTools()
        object.blockComplete = { [weak self] image in
            guard let self = self else { return }
            
            // Create and present the add item form
            let addItemVC = UIAlertController(title: "Add New Item", message: "Enter item details", preferredStyle: .alert)
            
            addItemVC.addTextField { textField in
                textField.placeholder = "Product Name"
            }
            
            addItemVC.addTextField { textField in
                textField.placeholder = "Price"
                textField.keyboardType = .decimalPad
            }
            
            addItemVC.addTextField { textField in
                textField.placeholder = "Quantity"
                textField.keyboardType = .numberPad
            }
            
            let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
                guard let self = self,
                      let nameField = addItemVC.textFields?[0],
                      let priceField = addItemVC.textFields?[1],
                      let quantityField = addItemVC.textFields?[2],
                      let name = nameField.text, !name.isEmpty,
                      let priceText = priceField.text, !priceText.isEmpty,
                      let price = Double(priceText),
                      let quantityText = quantityField.text, !quantityText.isEmpty,
                      let quantity = Int(quantityText) else {
                    ProgressTools.showError("Please fill all fields with valid data")
                    return
                }
                
                // Create a new inventory item
                let newItem = InventoryItem(
                    barcode: UUID().uuidString, // Generate a unique barcode
                    productName: name,
                    productPrice: price,
                    imageData: image.jpegData(compressionQuality: 0.8),
                    quantityInStock: quantity,
                    thumbImage: image
                )
                
                // Save to CloudKit
                self.saveNewItem(newItem)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            addItemVC.addAction(addAction)
            addItemVC.addAction(cancelAction)
            
            self.present(addItemVC, animated: true)
        }
        return object
    }()
    
    // Background search view
    lazy var searchBgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 243/255.0, green: 243/255.0, blue: 243/255.0, alpha: 1.0)
        return view
    }()
    
    private lazy var searchTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Search inventory..."
        textField.textAlignment = .left
        textField.textColor = UIColor(red: 51/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1.0)
        textField.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        textField.borderStyle = .roundedRect
        textField.rx.text.orEmpty.changed.subscribe(onNext: { (text) in
            self.searchText = text
            self.updateFilteredInventory()
            self.tableView.reloadData()
        }).disposed(by: disposeBag)
        return textField
    }()
    
    private lazy var sortButton: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(systemName: "arrow.up.arrow.down"), for: .normal)
        btn.setTitleColor(.systemBlue, for: .normal)
        
        // Create menu actions
        let actions = [
            UIAction(title: "Name (A-Z)") { _ in
                self.sortOption = SortOption.nameAsc
                self.updateFilteredInventory()
                self.tableView.reloadData()
            },
            UIAction(title: "Name (Z-A)") { _ in
                self.sortOption = SortOption.nameDesc
                self.updateFilteredInventory()
                self.tableView.reloadData()
            },
            UIAction(title: "Price (Low-High)") { _ in
                self.sortOption = SortOption.priceAsc
                self.updateFilteredInventory()
                self.tableView.reloadData()
            },
            UIAction(title: "Price (High-Low)") { _ in
                self.sortOption = SortOption.priceDesc
                self.updateFilteredInventory()
                self.tableView.reloadData()
            }
        ]
        
        // Create and bind menu to button
        btn.menu = UIMenu(title: "Sort Options", children: actions)
        btn.showsMenuAsPrimaryAction = true
        return btn
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 200
        tableView.separatorColor = .clear
        tableView.register(GoodsItemTVCell.self, forCellReuseIdentifier: "GoodsItemTVCell")
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        return tableView
    }()
    
    private func setupNavigationItems() {
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addNewItem)
        )
        navigationItem.rightBarButtonItem = addButton
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Dashboard"
        setupNavigationItems()
        
        // Add subviews
        self.view.addSubview(self.searchBgView)
        self.searchBgView.addSubview(self.searchTextField)
        self.searchBgView.addSubview(self.sortButton)
        self.view.addSubview(self.tableView)
        
        // Layout constraints
        self.searchBgView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        self.sortButton.snp.makeConstraints { make in
            make.centerY.equalTo(self.searchTextField)
            make.right.equalToSuperview().offset(-20)
            make.width.equalTo(40)
            make.height.equalTo(40)
        }
        
        self.searchTextField.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(10)
            make.right.equalTo(self.sortButton.snp.left).offset(-20)
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
        if self.allInventory.isEmpty {
            updateInventory()
        }
    }
    
    func updateInventory() {
        ProgressTools.showLoading("Updating inventory...", self.view)
        CloudKitManager.shared.fetchProducts { [weak self] records in
            guard let self = self else {
                ProgressTools.hide(nil)
                return
            }
            
            if records.isEmpty {
                ProgressTools.hide(self.view)
                if self.allInventory.isEmpty {
                    self.allInventory = []
                    self.filteredInventory = []
                    self.tableView.reloadData()
                }
                return
            }
            
            let allData: [LocalInventory] = records
            var tempData: [InventoryItem] = []
            for good in allData {
                let imageData = good.thumbImage?.jpegData(compressionQuality: 0.8)
                let item = InventoryItem(
                    barcode: good.barCode,
                    productName: good.productName,
                    productPrice: good.price,
                    imageData: imageData,
                    recordID: good.id,
                    quantityInStock: good.quantityInStock,
                    thumbImage: good.thumbImage
                )
                tempData.append(item)
            }
            
            ProgressTools.hide(self.view)
            self.allInventory = tempData
            self.updateFilteredInventory()
            self.tableView.reloadData()
        }
    }
    
    func updateFilteredInventory() {
        // Apply search filter
        if searchText.isEmpty {
            filteredInventory = allInventory
        } else {
            filteredInventory = allInventory.filter { item in
                return item.productName.lowercased().contains(searchText.lowercased()) ||
                       item.barcode.lowercased().contains(searchText.lowercased())
            }
        }
        
        // Apply sorting
        switch sortOption {
        case .nameAsc:
            filteredInventory.sort { $0.productName < $1.productName }
        case .nameDesc:
            filteredInventory.sort { $0.productName > $1.productName }
        case .priceAsc:
            filteredInventory.sort { $0.productPrice < $1.productPrice }
        case .priceDesc:
            filteredInventory.sort { $0.productPrice > $1.productPrice }
        }
    }
    
    @objc func addNewItem() {
        // Show action sheet for taking photo or choosing from gallery
        let actionSheet = UIAlertController(title: "Add New Item", message: "Take a photo of the item", preferredStyle: .actionSheet)
        
        let takePhotoAction = UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
            self?.choicePhotoTools.takePhoto(controller: self!)
        }
        
        let choosePhotoAction = UIAlertAction(title: "Choose from Gallery", style: .default) { [weak self] _ in
            self?.choicePhotoTools.choicePhoto(controller: self!)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        actionSheet.addAction(takePhotoAction)
        actionSheet.addAction(choosePhotoAction)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true)
    }
    
    func saveNewItem(_ item: InventoryItem) {
        // First, add item to local collection right away for better UX
        let newItem = item
        self.allInventory.append(newItem)
        self.updateFilteredInventory()
        self.tableView.reloadData()
        
        // Then attempt to save to CloudKit
        ProgressTools.showLoading("Adding item...", self.view)
        
        CloudKitManager.shared.saveNote(note: item) { result in
            DispatchQueue.main.async {
                // Always hide loading first
                ProgressTools.hide(self.view)
                
                switch result {
                case .success(let record):
                    // Show success message
                    ProgressTools.showSuccess("Item added successfully")
                    print("Successfully added item with ID: \(record.recordID.recordName)")
                    
                case .failure(let error):
                    // Check for specific CloudKit errors
                    let errorMessage: String
                    
                    if error.localizedDescription.contains("recordName") {
                        errorMessage = "Item saved locally only (CloudKit schema issue)"
                        print("CloudKit schema error: \(error)")
                    } else if error.localizedDescription.contains("reserved key") {
                        errorMessage = "Item saved locally only (CloudKit reserved key issue)"
                        print("CloudKit reserved key error: \(error)")
                    } else {
                        errorMessage = "Item saved locally only"
                        print("CloudKit error: \(error)")
                    }
                    
                    ProgressTools.showError(errorMessage)
                }
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredInventory.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GoodsItemTVCell", for: indexPath) as? GoodsItemTVCell else {
            return UITableViewCell()
        }
        
        let item = filteredInventory[indexPath.row]
        cell.updateInfo(inventoryItem: item)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
} 