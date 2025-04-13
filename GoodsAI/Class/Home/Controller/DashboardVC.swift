//
//  DashboardVC.swift
//  GoodsAI
//
//  Created by Emily on 2025/3/13.
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
                
                // Save to local storage
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
        
        let helpButton = UIBarButtonItem(
            image: UIImage(systemName: "questionmark.circle"),
            style: .plain,
            target: self,
            action: #selector(showOnboardingTutorial)
        )
        
        navigationItem.rightBarButtonItems = [addButton, helpButton]
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
        fetchItems()  // Always refresh inventory data when view appears
    }
    
    func fetchItems() {
        ProgressTools.showLoading("Loading items...", self.view)
        
        // Load items from local storage
        DatabaseManager.shared.getAllItems { items in
            DispatchQueue.main.async {
                self.allInventory = items
                self.updateFilteredInventory()
                self.tableView.reloadData()
                ProgressTools.hide(self.view)
                
                if items.isEmpty {
                    // Show an add items prompt if there are no items
                    self.showEmptyStatePrompt()
                }
            }
        }
    }
    
    func showEmptyStatePrompt() {
        // Create and show an alert to guide the user on adding items
        let alert = UIAlertController(
            title: "No Items Found",
            message: "Your inventory is empty. Add your first item by tapping the + button.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        self.present(alert, animated: true)
    }
    
    private func updateFilteredInventory() {
        self.filteredInventory = allInventory.filter { item in
            if searchText.isEmpty {
                return true
            }
            return item.productName.lowercased().contains(searchText.lowercased()) || item.barcode.lowercased().contains(searchText.lowercased())
        }
        
        switch sortOption {
        case .nameAsc:
            self.filteredInventory.sort { $0.productName < $1.productName }
        case .nameDesc:
            self.filteredInventory.sort { $0.productName > $1.productName }
        case .priceAsc:
            self.filteredInventory.sort { $0.productPrice < $1.productPrice }
        case .priceDesc:
            self.filteredInventory.sort { $0.productPrice > $1.productPrice }
        }
        
        // Show empty state if needed
        if self.filteredInventory.isEmpty {
            self.tableView.setViewState(state: .CT_empty, title: "No inventory items found")
        } else {
            self.tableView.setViewState(state: .CT_normal)
        }
        
        self.tableView.reloadData()
    }
    
    @objc func addNewItem() {
        // Show action sheet for taking photo or choosing from gallery
        let actionSheet = UIAlertController(title: "Add New Item", message: "Take a photo of the item", preferredStyle: .actionSheet)
        
        let takePhotoAction = UIAlertAction(title: "Take Photo", style: .default) { [self] _ in
            self.choicePhotoTools.takePhoto(controller: self)
        }
        
        let choosePhotoAction = UIAlertAction(title: "Choose from Gallery", style: .default) { [self] _ in
            self.choicePhotoTools.choicePhoto(controller: self)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        actionSheet.addAction(takePhotoAction)
        actionSheet.addAction(choosePhotoAction)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true)
    }
    
    @objc func showOnboardingTutorial() {
        // Present the onboarding tutorial
        let onboardingVC = OnboardingViewController()
        onboardingVC.modalPresentationStyle = .fullScreen
        present(onboardingVC, animated: true)
    }
    
    func saveNewItem(_ item: InventoryItem) {
        // First, add item to local collection right away for better UX
        let newItem = item
        self.allInventory.append(newItem)
        self.updateFilteredInventory()
        self.tableView.reloadData()
        
        // Save to local storage
        ProgressTools.showLoading("Adding item...", self.view)
        
        DatabaseManager.shared.saveItem(item: item) { result in
            DispatchQueue.main.async {
                // Always hide loading first
                ProgressTools.hide(self.view)
                
                switch result {
                case .success(_):
                    // Show success message
                    ProgressTools.showSuccess("Item added successfully")
                    
                case .failure(let error):
                    ProgressTools.showError("Failed to save item: \(error.localizedDescription)")
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
        
        // Get the selected item
        let item = filteredInventory[indexPath.row]
        
        // Create edit form
        let editItemVC = UIAlertController(title: "Edit Item", message: "Update item details", preferredStyle: .alert)
        
        editItemVC.addTextField { textField in
            textField.placeholder = "Product Name"
            textField.text = item.productName
        }
        
        editItemVC.addTextField { textField in
            textField.placeholder = "Price"
            textField.keyboardType = .decimalPad
            textField.text = String(item.productPrice)
        }
        
        editItemVC.addTextField { textField in
            textField.placeholder = "Quantity"
            textField.keyboardType = .numberPad
            textField.text = String(item.quantityInStock)
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [self] _ in
            guard let nameField = editItemVC.textFields?[0],
                  let priceField = editItemVC.textFields?[1],
                  let quantityField = editItemVC.textFields?[2],
                  let name = nameField.text, !name.isEmpty,
                  let priceText = priceField.text, !priceText.isEmpty,
                  let price = Double(priceText),
                  let quantityText = quantityField.text, !quantityText.isEmpty,
                  let quantity = Int(quantityText) else {
                ProgressTools.showError("Please fill all fields with valid data")
                return
            }
            
            // Create updated item
            let updatedItem = InventoryItem(
                barcode: item.barcode,
                productName: name,
                productPrice: price,
                imageData: item.imageData,
                quantityInStock: quantity,
                thumbImage: item.thumbImage
            )
            
            // Update in local array first
            if let index = self.allInventory.firstIndex(where: { $0.barcode == item.barcode }) {
                self.allInventory[index] = updatedItem
                self.updateFilteredInventory()
                self.tableView.reloadData()
            }
            
            // Update in database
            self.updateItemLocally(updatedItem)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        editItemVC.addAction(saveAction)
        editItemVC.addAction(cancelAction)
        
        present(editItemVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 84 // Based on cell layout constraints (60px image height + 12px top padding + 12px bottom padding)
    }
    
    // MARK: - Swipe to Delete
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Only allow actions for inventory items
        guard tableView == self.tableView && indexPath.row < filteredInventory.count else {
            return nil
        }
        
        let item = filteredInventory[indexPath.row]
        
        // Create delete action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [self] (_, _, completionHandler) in
            // Show confirmation alert
            let alert = UIAlertController(title: "Delete Item", message: "Are you sure you want to delete this item?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completionHandler(false)
            })
            
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [self] _ in
                // Remove item from UI immediately
                self.filteredInventory.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                
                // Then delete from storage using barcode
                self.deleteItem(barcode: item.barcode)
                
                completionHandler(true)
            })
            
            self.present(alert, animated: true)
        }
        
        // Create edit action
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [self] (_, _, completionHandler) in
            // Simulate a tap on the row to bring up the edit form
            self.tableView(tableView, didSelectRowAt: indexPath)
            
            completionHandler(true)
        }
        
        // Add image to actions (SF Symbols)
        deleteAction.image = UIImage(systemName: "trash")
        editAction.image = UIImage(systemName: "pencil")
        editAction.backgroundColor = .systemBlue
        
        // Create and return configuration
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        return configuration
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Only allow actions for inventory items
        guard tableView == self.tableView && indexPath.row < filteredInventory.count else {
            return nil
        }
        
        let item = filteredInventory[indexPath.row]
        
        // Create quick edit action for incrementing quantity
        let incrementAction = UIContextualAction(style: .normal, title: "+1") { [self] (_, _, completionHandler) in
            // Increment the quantity by 1
            let updatedQuantity = item.quantityInStock + 1
            
            // Create updated item
            let updatedItem = InventoryItem(
                barcode: item.barcode,
                productName: item.productName,
                productPrice: item.productPrice,
                imageData: item.imageData,
                quantityInStock: updatedQuantity,
                thumbImage: item.thumbImage
            )
            
            // Update in local array first
            if let index = self.allInventory.firstIndex(where: { $0.barcode == item.barcode }) {
                self.allInventory[index] = updatedItem
                self.updateFilteredInventory()
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            
            // Update in database
            self.updateItemLocally(updatedItem)
            
            completionHandler(true)
        }
        
        // Create quick edit action for decrementing quantity
        let decrementAction = UIContextualAction(style: .normal, title: "-1") { [self] (_, _, completionHandler) in
            // Prevent negative quantities
            let updatedQuantity = max(0, item.quantityInStock - 1)
            
            // Create updated item
            let updatedItem = InventoryItem(
                barcode: item.barcode,
                productName: item.productName,
                productPrice: item.productPrice,
                imageData: item.imageData,
                quantityInStock: updatedQuantity,
                thumbImage: item.thumbImage
            )
            
            // Update in local array first
            if let index = self.allInventory.firstIndex(where: { $0.barcode == item.barcode }) {
                self.allInventory[index] = updatedItem
                self.updateFilteredInventory()
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            
            // Update in database
            self.updateItemLocally(updatedItem)
            
            completionHandler(true)
        }
        
        // Add images to actions (SF Symbols)
        incrementAction.image = UIImage(systemName: "plus.circle")
        incrementAction.backgroundColor = .systemGreen
        
        decrementAction.image = UIImage(systemName: "minus.circle")
        decrementAction.backgroundColor = .systemOrange
        
        // Create and return configuration
        let configuration = UISwipeActionsConfiguration(actions: [incrementAction, decrementAction])
        return configuration
    }
    
    // MARK: - Local Database Operations
    
    func updateItemLocally(_ item: InventoryItem) {
        ProgressTools.showLoading("Updating item...", self.view)
        
        DatabaseManager.shared.updateItem(item: item) { result in
            DispatchQueue.main.async {
                ProgressTools.hide(self.view)
                
                switch result {
                case .success(_):
                    ProgressTools.showSuccess("Item updated successfully")
                case .failure(let error):
                    ProgressTools.showError("Failed to update item: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Additional method to delete item by barcode
    func deleteItem(barcode: String) {
        // First remove from local array for immediate UI update
        if let index = allInventory.firstIndex(where: { $0.barcode == barcode }) {
            allInventory.remove(at: index)
            updateFilteredInventory()
            tableView.reloadData()
        }
        
        // Then delete from storage
        DatabaseManager.shared.deleteItem(barcode: barcode) { success in
            DispatchQueue.main.async {
                if success {
                    ProgressTools.showSuccess("Item deleted successfully")
                } else {
                    ProgressTools.showError("Failed to delete item")
                }
            }
        }
    }
} 