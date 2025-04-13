//
//  SearchVC.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/13.
//

import UIKit
import RxSwift
import AVFAudio
import Speech
import CloudKit

class SearchVC: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let disposeBag = DisposeBag()
    
    @Published var lastQueryVector: [Float]?
    @Published var lastQueryType: String = ""
    @Published var similarItems: [InventoryItem] = []
    var searchImage: UIImage?
    var searchText: String = ""
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorColor = .clear
        tableView.backgroundColor = .white
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        tableView.register(GoodsItemTVCell.self, forCellReuseIdentifier: "GoodsItemTVCell")
        tableView.register(SearchOptionCell.self, forCellReuseIdentifier: "SearchOptionCell")
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        return tableView
    }()
    
    private lazy var voiceToText: VoiceToTextTools = {
        let voiceToText = VoiceToTextTools()
        voiceToText.blockInputText = { [weak self] text in
            guard let self = self else { return }
            self.searchText = text
        }
        return voiceToText
    }()
    
    private lazy var choicePhotoTools: ChoicePhotoTools = {
        let object = ChoicePhotoTools()
        object.blockComplete = { [weak self] image in
            guard let self = self else { return }
            self.searchImage = image
            self.tableView.reloadData()
        }
        return object
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Search"
        
        view.addSubview(tableView)
        voiceToText.requestRecordPermission()
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - Search Functions
    
    func findSimilarItemsByText() {
        let query = self.searchText
        if query.isEmpty {
            ProgressTools.showError("Search content cannot be empty!")
            return
        }
        
        ProgressTools.showLoading("Searching...", self.view)
        self.similarItems.removeAll()
        self.tableView.reloadData()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Store the query vector for debugging
            if let queryEmbedding = DatabaseManager.shared.generateTextEmbeddingForDebug(for: query) {
                DispatchQueue.main.async {
                    self.lastQueryVector = queryEmbedding
                    self.lastQueryType = "Text Query: \"\(query)\""
                }
            }
            
            // Find similar items using text query
            let items = DatabaseManager.shared.findSimilarItemsByText(query: query, limit: 10)
            
            DispatchQueue.main.async {
                self.similarItems = items
                self.tableView.reloadData()
                ProgressTools.hide(self.view)
                
                if items.isEmpty {
                    ProgressTools.showError("No items found matching '\(query)'")
                }
            }
        }
    }
    
    func findSimilarItemsByImage() {
        if self.searchImage == nil {
            ProgressTools.showError("Search image cannot be empty!")
            return
        }
        
        guard let imageData = self.searchImage!.jpegData(compressionQuality: 0.8) else {
            ProgressTools.showError("Image error!")
            return
        }
        
        ProgressTools.showLoading("Searching...", self.view)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Store the query vector for debugging
            if let queryEmbedding = DatabaseManager.shared.generateCLIPEmbeddingForDebug(for: imageData) {
                DispatchQueue.main.async {
                    self.lastQueryVector = queryEmbedding
                    self.lastQueryType = "Image Query"
                }
            }
            
            let items = DatabaseManager.shared.findSimilarItems(to: imageData, limit: 10)
            
            DispatchQueue.main.async {
                self.similarItems = items
                self.tableView.reloadData()
                ProgressTools.hide(self.view)
                
                if items.isEmpty {
                    ProgressTools.showError("No similar items found")
                }
            }
        }
    }
    
    // MARK: - Action Handlers
    
    func handleTextSearchAction(type: Int) {
        switch type {
        case 0: // Text search
            let alert = UIAlertController(title: "Search", message: "Enter search keywords", preferredStyle: .alert)
            
            alert.addTextField { textField in
                textField.placeholder = "Enter keywords"
                textField.text = self.searchText
            }
            
            let searchAction = UIAlertAction(title: "Search", style: .default) { [weak self] _ in
                guard let self = self,
                      let textField = alert.textFields?.first,
                      let searchText = textField.text, !searchText.isEmpty else {
                    ProgressTools.showError("Search text cannot be empty")
                    return
                }
                
                self.searchText = searchText
                self.findSimilarItemsByText()
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            alert.addAction(searchAction)
            alert.addAction(cancelAction)
            
            present(alert, animated: true)
            
        case 1: // Voice search
            self.voiceToText.startLiveTranscribe()
            
        case 2: // Stop voice search and perform search
            self.voiceToText.stopLiveTranscribe()
            self.tableView.reloadData()
            self.findSimilarItemsByText()
            
        default:
            break
        }
    }
    
    func handleImageSearchAction(type: Int) {
        switch type {
        case 0: // Take photo
            self.choicePhotoTools.takePhoto(controller: self)
            
        case 1: // Choose from gallery
            self.choicePhotoTools.choicePhoto(controller: self)
            
        case 2: // Search with selected image
            self.findSimilarItemsByImage()
            
        default:
            break
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0, 1: // Search options sections
            return 1
        case 2: // Results section
            return similarItems.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: // Text search
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SearchOptionCell", for: indexPath) as? SearchOptionCell else {
                return UITableViewCell()
            }
            
            cell.configure(title: "Search by Keywords", 
                          description: "Find items using text search",
                          image: UIImage(systemName: "doc.text.magnifyingglass"),
                          buttonTitle: "Search")
            
            cell.actionHandler = { [weak self] in
                self?.handleTextSearchAction(type: 0)
            }
            
            return cell
            
        case 1: // Image search
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SearchOptionCell", for: indexPath) as? SearchOptionCell else {
                return UITableViewCell()
            }
            
            // If there's a search image, show different UI
            if let searchImage = self.searchImage {
                cell.configure(title: "Image Search",
                              description: "Find similar items to this image",
                              image: searchImage,
                              buttonTitle: "Search")
                
                cell.actionHandler = { [weak self] in
                    self?.handleImageSearchAction(type: 2)
                }
                
                // Add a "New Search" button to allow taking another photo
                cell.addSecondaryButton(title: "New Search") { [weak self] in
                    self?.searchImage = nil
                    self?.tableView.reloadData()
                }
            } else {
                cell.configure(title: "Search by Image",
                              description: "Take a photo or select from gallery",
                              image: UIImage(systemName: "camera"),
                              buttonTitle: "Take Photo")
                
                cell.actionHandler = { [weak self] in
                    self?.handleImageSearchAction(type: 0)
                }
                
                cell.addSecondaryButton(title: "Gallery") { [weak self] in
                    self?.handleImageSearchAction(type: 1)
                }
            }
            
            return cell
            
        case 2: // Results
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "GoodsItemTVCell", for: indexPath) as? GoodsItemTVCell else {
                return UITableViewCell()
            }
            
            let item = similarItems[indexPath.row]
            cell.updateInfo(inventoryItem: item)
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .white
        
        let containerView = UIView()
        containerView.backgroundColor = UIColor(red: 243/255.0, green: 243/255.0, blue: 243/255.0, alpha: 1.0)
        containerView.layer.cornerRadius = 8
        
        if section < 2 || !similarItems.isEmpty {
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else {
            return nil
        }
        
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = UIColor(red: 51/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1.0)
        
        switch section {
        case 0:
            titleLabel.text = "Text Search"
        case 1:
            titleLabel.text = "Image Search"
        case 2:
            if !similarItems.isEmpty {
                titleLabel.text = "Search Results"
            } else {
                return nil
            }
        default:
            return nil
        }
        
        headerView.addSubview(containerView)
        containerView.addSubview(titleLabel)
        
        containerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 2 && similarItems.isEmpty {
            return 0
        }
        return 50
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 2 && similarItems.isEmpty {
            return nil
        }
        
        let footerView = UIView()
        footerView.backgroundColor = .white
        
        let containerView = UIView()
        containerView.backgroundColor = UIColor(red: 243/255.0, green: 243/255.0, blue: 243/255.0, alpha: 1.0)
        containerView.layer.cornerRadius = 8
        containerView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        footerView.addSubview(containerView)
        
        containerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-10)
        }
        
        return footerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 2 && similarItems.isEmpty {
            return 0
        }
        return 20
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 2 {
            return 120 // Fixed height for results cells
        }
        return UITableView.automaticDimension
    }
}

// MARK: - SearchOptionCell

class SearchOptionCell: UITableViewCell {
    
    var actionHandler: (() -> Void)?
    var secondaryActionHandler: (() -> Void)?
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(red: 51/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()
    
    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 0/255.0, green: 122/255.0, blue: 255/255.0, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var secondaryButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 243/255.0, green: 243/255.0, blue: 243/255.0, alpha: 1.0)
        button.setTitleColor(UIColor(red: 51/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1.0), for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(secondaryButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        contentView.addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(actionButton)
        containerView.addSubview(secondaryButton)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 5, left: 20, bottom: 5, right: 20))
        }
        
        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(15)
            make.left.equalToSuperview().offset(15)
            make.width.height.equalTo(60)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.top)
            make.left.equalTo(iconImageView.snp.right).offset(15)
            make.right.equalToSuperview().offset(-15)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.equalTo(iconImageView.snp.right).offset(15)
            make.right.equalToSuperview().offset(-15)
        }
        
        actionButton.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(15)
            make.left.equalTo(iconImageView.snp.right).offset(15)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-15)
        }
        
        secondaryButton.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(15)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-15)
        }
        
        // Set default single-button configuration
        configureForSingleButton()
    }
    
    private func configureForSingleButton() {
        secondaryButton.isHidden = true
        
        actionButton.snp.remakeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(15)
            make.left.equalTo(iconImageView.snp.right).offset(15)
            make.right.equalToSuperview().offset(-15)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-15)
        }
    }
    
    private func configureForDualButtons() {
        secondaryButton.isHidden = false
        
        actionButton.snp.remakeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(15)
            make.left.equalTo(iconImageView.snp.right).offset(15)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-15)
            // Calculate width dynamically based on available space
            // Remove the hard-coded width that's causing conflicts
            make.right.equalTo(secondaryButton.snp.left).offset(-10) // Ensure spacing to secondaryButton
        }
        
        secondaryButton.snp.remakeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(15)
            make.right.equalToSuperview().offset(-15)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-15)
            make.width.equalTo(actionButton.snp.width) // Equal width to actionButton
        }
    }
    
    func configure(title: String, description: String, image: UIImage?, buttonTitle: String) {
        titleLabel.text = title
        descriptionLabel.text = description
        iconImageView.image = image
        actionButton.setTitle(buttonTitle, for: .normal)
        
        // Reset to single button layout
        configureForSingleButton()
    }
    
    func addSecondaryButton(title: String, action: @escaping () -> Void) {
        secondaryButton.setTitle(title, for: .normal)
        secondaryActionHandler = action
        
        // Update to dual button layout
        configureForDualButtons()
    }
    
    @objc private func actionButtonTapped() {
        actionHandler?()
    }
    
    @objc private func secondaryButtonTapped() {
        secondaryActionHandler?()
    }
} 