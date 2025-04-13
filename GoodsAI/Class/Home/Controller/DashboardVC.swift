//
//  DashboardVC.swift
//  GoodsAI
//
//  Created by Emily on 2025/3/13.
//

import UIKit
import RxSwift
import MobileCoreServices
import Speech

class DashboardVC: BaseViewController, UITableViewDelegate, UITableViewDataSource {

    private let disposeBag = DisposeBag()
    var allInventory: [InventoryItem] = []
    var filteredInventory: [InventoryItem] = []
    
    var sortOption = SortOption.nameAsc
    
    private lazy var voiceToTextTools: VoiceToTextTools = {
        let voiceToText = VoiceToTextTools()
        voiceToText.blockInputText = { [weak self] text in
            guard let self = self else { return }
            
            // Execute UI updates on the main thread
            DispatchQueue.main.async {
                print("=== DashboardVC: Received voice input: \"\(text)\" ===")
                
                // The current textfield being edited will be set when voice input starts
                if let activeTextField = self.activeTextField {
                    print("=== DashboardVC: Setting text on active text field: \(String(describing: activeTextField.placeholder)) ===")
                    
                    // Set the text directly and also trigger valueChanged notification
                    activeTextField.text = text
                    
                    // Notify that the text has changed - UIAlertController may not detect direct setting
                    NotificationCenter.default.post(name: UITextField.textDidChangeNotification, object: activeTextField)
                    
                    print("=== DashboardVC: Text set and notification posted ===")
                } else {
                    print("=== DashboardVC: No active text field found ===")
                }
            }
        }
        
        voiceToText.blockError = { errorMessage in
            DispatchQueue.main.async {
                print("=== DashboardVC: Voice error: \(errorMessage) ===")
                ProgressTools.showError(errorMessage)
            }
        }
        return voiceToText
    }()
    
    // Track which textfield is being edited with voice
    private var activeTextField: UITextField?
    
    private lazy var choicePhotoTools: ChoicePhotoTools = {
        let object = ChoicePhotoTools()
        object.blockComplete = { [weak self] image in
            guard let self = self else { return }
            
            // Create and present the add item form
            let addItemVC = UIAlertController(title: "Add New Item", message: "Enter item details", preferredStyle: .alert)
            
            // Product Name field with voice input
            addItemVC.addTextField { textField in
                textField.placeholder = "Product Name"
            }
            
            // Price field with voice input
            addItemVC.addTextField { textField in
                textField.placeholder = "Price"
                textField.keyboardType = .decimalPad
            }
            
            // Quantity field with voice input
            addItemVC.addTextField { textField in
                textField.placeholder = "Quantity"
                textField.keyboardType = .numberPad
            }
            
            // Add voice input buttons action
            let addVoiceButtons = { [weak self] (alertController: UIAlertController) in
                guard let self = self,
                      let nameField = alertController.textFields?[0],
                      let priceField = alertController.textFields?[1],
                      let quantityField = alertController.textFields?[2] else { return }
                
                // Create and add voice input buttons for each field
                let addVoiceButton = { (textField: UITextField, buttonTitle: String) in
                    let voiceButton = UIButton(type: .system)
                    voiceButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
                    voiceButton.tintColor = .systemBlue
                    voiceButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
                    voiceButton.tag = textField.hash
                    
                    // Add press-and-hold gesture instead of tap
                    voiceButton.addTarget(self, action: #selector(self.voiceButtonPressed(_:)), for: .touchDown)
                    voiceButton.addTarget(self, action: #selector(self.voiceButtonReleased(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
                    
                    textField.rightView = voiceButton
                    textField.rightViewMode = .always
                }
                
                addVoiceButton(nameField, "Name")
                addVoiceButton(priceField, "Price")
                addVoiceButton(quantityField, "Quantity")
            }
            
            // Add voice buttons after alert is presented (need to wait for text fields to be created)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                addVoiceButtons(addItemVC)
            }
            
            let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
                guard let self = self else { return }
                
                // Get text fields
                guard let nameField = addItemVC.textFields?[0],
                      let priceField = addItemVC.textFields?[1],
                      let quantityField = addItemVC.textFields?[2] else {
                    ProgressTools.showError("Could not access input fields")
                    return
                }
                
                // Get values with proper logging
                let name = nameField.text ?? ""
                let priceText = priceField.text ?? ""
                let quantityText = quantityField.text ?? ""
                
                print("Adding item - Name: '\(name)', Price: '\(priceText)', Quantity: '\(quantityText)'")
                
                // Validate input
                if name.isEmpty {
                    ProgressTools.showError("Product name cannot be empty")
                    return
                }
                
                guard let price = Double(priceText) else {
                    ProgressTools.showError("Invalid price format")
                    return
                }
                
                guard let quantity = Int(quantityText) else {
                    ProgressTools.showError("Invalid quantity format")
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
    
    // Background stats view
    lazy var statsBgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 243/255.0, green: 243/255.0, blue: 243/255.0, alpha: 1.0)
        return view
    }()
    
    // Stats views to replace search functionality
    private lazy var totalItemsLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = UIColor(red: 51/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.text = "Total Items: 0"
        return label
    }()
    
    private lazy var totalCountLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = UIColor(red: 51/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.text = "Total Count: 0"
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()
    
    private lazy var totalAmountLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = UIColor(red: 51/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.text = "Total Amount: $0.00"
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()
    
    private lazy var statsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [totalItemsLabel, totalCountLabel, totalAmountLabel])
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 2
        return stackView
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
        
        let infoButton = UIBarButtonItem(
            image: UIImage(systemName: "info.circle"),
            style: .plain,
            target: self,
            action: #selector(showInfoScreen)
        )
        
        navigationItem.rightBarButtonItems = [addButton, helpButton, infoButton]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Dashboard"
        setupNavigationItems()
        
        // Add subviews
        self.view.addSubview(self.statsBgView)
        self.statsBgView.addSubview(self.statsStackView)
        self.statsBgView.addSubview(self.sortButton)
        self.view.addSubview(self.tableView)
        
        // Layout constraints
        self.statsBgView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        self.sortButton.snp.makeConstraints { make in
            make.centerY.equalTo(self.statsStackView)
            make.right.equalToSuperview().offset(-20)
            make.width.equalTo(40)
            make.height.equalTo(40)
        }
        
        self.statsStackView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(8)
            make.right.equalTo(self.sortButton.snp.left).offset(-20)
            make.bottom.equalToSuperview().offset(-8)
        }
        
        self.tableView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(self.statsBgView.snp.bottom).offset(10)
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
    
    func updateFilteredInventory() {
        // Since we're not using search anymore, just use all inventory items
        self.filteredInventory = allInventory
        
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
        
        // Update stats
        updateStats()
        
        // Show empty state if needed
        if self.filteredInventory.isEmpty {
            self.tableView.setViewState(state: .CT_empty, title: "No inventory items found")
        } else {
            self.tableView.setViewState(state: .CT_normal)
        }
        
        self.tableView.reloadData()
    }
    
    // New function to update statistics
    private func updateStats() {
        let totalItems = allInventory.count
        let totalCount = allInventory.reduce(0) { $0 + $1.quantityInStock }
        let totalAmount = allInventory.reduce(0.0) { $0 + ($1.productPrice * Double($1.quantityInStock)) }
        
        totalItemsLabel.text = "Total Items: \(totalItems)"
        totalCountLabel.text = "Total Count: \(totalCount)"
        totalAmountLabel.text = "Total Amount: $\(String(format: "%.2f", totalAmount))"
    }
    
    @objc func addNewItem() {
        // Request voice permission when user tries to add a new item
        voiceToTextTools.requestRecordPermission()
        
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
    
    @objc func showInfoScreen() {
        // Create alert controller with information
        let alert = UIAlertController(
            title: "Information",
            message: nil,
            preferredStyle: .alert
        )
        
        // Add legal liability disclaimer
        let disclaimerAction = UIAlertAction(title: "Legal Disclaimer", style: .default) { _ in
            let disclaimerAlert = UIAlertController(
                title: "Legal Disclaimer",
                message: "This application is provided as-is without any warranties. The developers are not liable for any damages or losses resulting from the use of this app. Information provided is for general purposes only and should not be considered professional advice.",
                preferredStyle: .alert
            )
            disclaimerAlert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(disclaimerAlert, animated: true)
        }
        
        // Add credits
        let creditsAction = UIAlertAction(title: "Credits", style: .default) { _ in
            let creditsAlert = UIAlertController(
                title: "Credits",
                message: "This app uses the following technologies and resources:\n\n• UIKit for interface design\n• CoreML for machine learning capabilities\n• Vision framework for image processing\n• SnapKit for auto layout\n• Alamofire for networking\n• SDWebImage for image loading\n\nDesign elements and icons by Apple SF Symbols.",
                preferredStyle: .alert
            )
            creditsAlert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(creditsAlert, animated: true)
        }
        
        // Add contact info
        let contactAction = UIAlertAction(title: "Contact Us", style: .default) { _ in
            let contactAlert = UIAlertController(
                title: "Contact Information",
                message: "For support or inquiries:\nEmail: support@goodsai.com\nWebsite: www.goodsai.com",
                preferredStyle: .alert
            )
            contactAlert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(contactAlert, animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(disclaimerAction)
        alert.addAction(creditsAction)
        alert.addAction(contactAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func saveNewItem(_ item: InventoryItem) {
        // First, add item to local collection right away for better UX
        let newItem = item
        self.allInventory.append(newItem)
        self.updateFilteredInventory()
        self.tableView.reloadData()
        // Stats are already updated in updateFilteredInventory
        
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
        
        // Add voice input buttons to edit fields
        let addVoiceButtons = { [weak self] (alertController: UIAlertController) in
            guard let self = self,
                  let nameField = alertController.textFields?[0],
                  let priceField = alertController.textFields?[1],
                  let quantityField = alertController.textFields?[2] else { return }
            
            // Create and add voice input buttons for each field
            let addVoiceButton = { (textField: UITextField, buttonTitle: String) in
                let voiceButton = UIButton(type: .system)
                voiceButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
                voiceButton.tintColor = .systemBlue
                voiceButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
                voiceButton.tag = textField.hash
                
                // Add press-and-hold gesture instead of tap
                voiceButton.addTarget(self, action: #selector(self.voiceButtonPressed(_:)), for: .touchDown)
                voiceButton.addTarget(self, action: #selector(self.voiceButtonReleased(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
                
                textField.rightView = voiceButton
                textField.rightViewMode = .always
            }
            
            addVoiceButton(nameField, "Name")
            addVoiceButton(priceField, "Price")
            addVoiceButton(quantityField, "Quantity")
        }
        
        // Add voice buttons after alert is presented
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            addVoiceButtons(editItemVC)
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [self] _ in
            // Get text fields
            guard let nameField = editItemVC.textFields?[0],
                  let priceField = editItemVC.textFields?[1],
                  let quantityField = editItemVC.textFields?[2] else {
                ProgressTools.showError("Could not access input fields")
                return
            }
            
            // Get values with proper logging
            let name = nameField.text ?? ""
            let priceText = priceField.text ?? ""
            let quantityText = quantityField.text ?? ""
            
            print("Updating item - Name: '\(name)', Price: '\(priceText)', Quantity: '\(quantityText)'")
            
            // Validate input
            if name.isEmpty {
                ProgressTools.showError("Product name cannot be empty")
                return
            }
            
            guard let price = Double(priceText) else {
                ProgressTools.showError("Invalid price format")
                return
            }
            
            guard let quantity = Int(quantityText) else {
                ProgressTools.showError("Invalid quantity format")
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
                    self.updateStats()
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
            // Stats are already updated in updateFilteredInventory
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
    
    // Voice button press-and-hold implementation
    @objc func voiceButtonPressed(_ sender: UIButton) {
        print("=== Voice Button Pressed ===")
        
        // Provide haptic feedback
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
        
        // Determine which text field to update based on the button's tag
        if let alertController = self.presentedViewController as? UIAlertController,
           let textFields = alertController.textFields {
            for textField in textFields {
                if textField.hash == sender.tag {
                    self.activeTextField = textField
                    print("=== Active TextField Set: \(String(describing: textField.placeholder)) ===")
                    
                    // Change button appearance to indicate recording
                    UIView.animate(withDuration: 0.2) {
                        sender.tintColor = .systemRed
                        sender.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                    }
                    
                    // Start voice recognition immediately
                    print("=== Starting Voice Recognition ===")
                    self.voiceToTextTools.startLiveTranscribe()
                    
                    // Show recording indicator
                    ProgressTools.showLoading("Listening... (Release when done)", self.view)
                    break
                }
            }
        } else {
            print("=== Alert controller or text fields not found ===")
        }
    }
    
    @objc func voiceButtonReleased(_ sender: UIButton) {
        print("=== Voice Button Released ===")
        
        // Provide haptic feedback
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        // Stop voice recognition
        print("=== Stopping Voice Recognition ===")
        self.voiceToTextTools.stopLiveTranscribe()
        ProgressTools.hide(self.view)
        
        // Extra validation - make sure text is properly set
        if let text = self.activeTextField?.text, !text.isEmpty {
            print("=== Voice input captured: \(text) ===")
            
            // Provide success feedback if text was captured
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
        } else {
            print("=== Voice input NOT captured - text field is empty ===")
            
            // Provide error feedback if no text was captured
            let errorFeedback = UINotificationFeedbackGenerator()
            errorFeedback.notificationOccurred(.error)
        }
        
        // Reset button appearance
        UIView.animate(withDuration: 0.2) {
            sender.tintColor = .systemBlue
            sender.transform = .identity
        }
        
        // Ensure the text field updates are processed
        if let activeField = self.activeTextField {
            NotificationCenter.default.post(name: UITextField.textDidChangeNotification, object: activeField)
            print("=== Posted text change notification ===")
            
            // Add a repeat notification after a small delay to ensure UIAlertController refreshes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("=== Posting follow-up text change notification ===")
                NotificationCenter.default.post(name: UITextField.textDidChangeNotification, object: activeField)
            }
        }
    }
} 