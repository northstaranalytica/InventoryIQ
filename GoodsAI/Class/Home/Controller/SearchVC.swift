//
//  SearchVC.swift
//  GoodsAI
//
//  Created by Emily on 2025/3/13.
//

import UIKit
import RxSwift
import AVFAudio
import Speech

class SearchVC: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let disposeBag = DisposeBag()
    
    @Published var lastQueryVector: [Float]?
    @Published var lastQueryType: String = ""
    @Published var similarItems: [InventoryItem] = []
    var searchImage: UIImage?
    var searchText: String = ""
    var isVoiceSearchActive: Bool = false // Track if voice search is active
    
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
            // Only reload the text search cell to prevent affecting image search
            if let indexPath = IndexPath(row: 0, section: 0) as? IndexPath {
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
        voiceToText.blockError = { [weak self] errorMessage in
            guard let self = self else { return }
            ProgressTools.showError(errorMessage)
            // Only reload the text search cell
            if let indexPath = IndexPath(row: 0, section: 0) as? IndexPath {
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }
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
        
        // Explicitly request permissions first with feedback
        voiceToText.requestRecordPermission { granted in
            if !granted {
                print("Speech recognition permission denied")
            }
        }
        
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
            // Check if we're currently recording - if so, stop
            if self.voiceToText.audioEngine.isRunning {
                handleTextSearchAction(type: 2)
                return
            }
            
            ProgressTools.showLoading("Listening...", self.view)
            
            // Start fresh recording session
            self.searchText = ""
            self.isVoiceSearchActive = true
            self.voiceToText.startLiveTranscribe()
            
            // Only reload the text search cell
            if let indexPath = IndexPath(row: 0, section: 0) as? IndexPath {
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }
            
            // Dismiss progress after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                ProgressTools.hide(self.view)
            }
            
        case 2: // Stop voice search and perform search
            self.voiceToText.stopLiveTranscribe()
            self.isVoiceSearchActive = false
            
            if !self.searchText.isEmpty {
                // Only reload the text search cell
                if let indexPath = IndexPath(row: 0, section: 0) as? IndexPath {
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
                self.findSimilarItemsByText()
            } else {
                ProgressTools.showError("No speech detected, please try again")
            }
            
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
                          buttonTitle: "")
            
            // Use icon instead of text for primary button
            cell.actionButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
            cell.actionButton.tintColor = .white
            
            cell.actionHandler = { [weak self] in
                self?.handleTextSearchAction(type: 0)
            }
            
            // Add a voice search button with appropriate state
            if self.voiceToText.audioEngine.isRunning {
                // Recording is active - show stop button with red background and current text
                cell.addSecondaryButton(title: "") { [weak self] in
                    self?.handleTextSearchAction(type: 2)
                }
                
                // Set button appearance for recording state
                cell.secondaryButton.backgroundColor = UIColor(red: 255/255.0, green: 59/255.0, blue: 48/255.0, alpha: 1.0)
                cell.secondaryButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
                cell.secondaryButton.tintColor = .white
                
                // Show the current transcription
                if !searchText.isEmpty {
                    cell.updateDescription("Voice input: \"\(searchText)\"")
                } else {
                    cell.updateDescription("Listening... (speak now)")
                }
            } else {
                // Not recording - show normal voice search button
                cell.addSecondaryButton(title: "") { [weak self] in
                    self?.handleTextSearchAction(type: 1)
                }
                
                // Set button appearance for inactive state
                cell.secondaryButton.backgroundColor = UIColor(red: 90/255.0, green: 200/255.0, blue: 250/255.0, alpha: 1.0)
                cell.secondaryButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
                cell.secondaryButton.tintColor = .white
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
                              buttonTitle: "")
                
                // Use icon instead of text for search button
                cell.actionButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
                cell.actionButton.tintColor = .white
                
                cell.actionHandler = { [weak self] in
                    self?.handleImageSearchAction(type: 2)
                }
                
                // Add a "New Search" button to allow taking another photo
                cell.addSecondaryButton(title: "") { [weak self] in
                    self?.searchImage = nil
                    self?.tableView.reloadData()
                }
                
                // Set button appearance for new search
                cell.secondaryButton.setImage(UIImage(systemName: "arrow.counterclockwise"), for: .normal)
                cell.secondaryButton.tintColor = UIColor(red: 51/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1.0)
            } else {
                cell.configure(title: "Search by Image",
                              description: "Take a photo or select from gallery",
                              image: UIImage(systemName: "camera"),
                              buttonTitle: "")
                
                // Use icon instead of text for camera button
                cell.actionButton.setImage(UIImage(systemName: "camera.fill"), for: .normal)
                cell.actionButton.tintColor = .white
                
                cell.actionHandler = { [weak self] in
                    self?.handleImageSearchAction(type: 0)
                }
                
                cell.addSecondaryButton(title: "") { [weak self] in
                    self?.handleImageSearchAction(type: 1)
                }
                
                // Set button appearance for gallery
                cell.secondaryButton.setImage(UIImage(systemName: "photo.on.rectangle"), for: .normal)
                cell.secondaryButton.tintColor = UIColor(red: 51/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1.0)
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
    var tertiaryActionHandler: (() -> Void)?
    
    // Make buttons accessible
    var secondaryButton: UIButton {
        return _secondaryButton
    }
    
    // Make action button accessible as well
    var actionButton: UIButton {
        return _actionButton
    }
    
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
    
    private lazy var _actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 0/255.0, green: 122/255.0, blue: 255/255.0, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var _secondaryButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 243/255.0, green: 243/255.0, blue: 243/255.0, alpha: 1.0)
        button.setTitleColor(UIColor(red: 51/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1.0), for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(secondaryButtonTapped), for: .touchUpInside)
        button.isHidden = true
        button.tag = 102
        return button
    }()
    
    private lazy var tertiaryButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 243/255.0, green: 243/255.0, blue: 243/255.0, alpha: 1.0)
        button.setTitleColor(UIColor(red: 51/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1.0), for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(tertiaryButtonTapped), for: .touchUpInside)
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
        containerView.addSubview(_actionButton)
        containerView.addSubview(_secondaryButton)
        containerView.addSubview(tertiaryButton)
        
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
        
        _actionButton.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(15)
            make.left.equalTo(iconImageView.snp.right).offset(15)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-15)
        }
        
        _secondaryButton.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(15)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-15)
        }
        
        tertiaryButton.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(15)
            make.right.equalToSuperview().offset(-15)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-15)
        }
        
        // Set default single-button configuration
        configureForSingleButton()
    }
    
    private func configureForSingleButton() {
        _secondaryButton.isHidden = true
        tertiaryButton.isHidden = true
        
        _actionButton.snp.remakeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(15)
            make.left.equalTo(iconImageView.snp.right).offset(15)
            make.right.equalToSuperview().offset(-15)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-15)
        }
    }
    
    private func configureForDualButtons() {
        _secondaryButton.isHidden = false
        tertiaryButton.isHidden = true
        
        _actionButton.snp.remakeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(15)
            make.left.equalTo(iconImageView.snp.right).offset(15)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-15)
            // Calculate width dynamically based on available space
            make.right.equalTo(_secondaryButton.snp.left).offset(-10) // Ensure spacing to secondaryButton
        }
        
        _secondaryButton.snp.remakeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(15)
            make.right.equalToSuperview().offset(-15)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-15)
            make.width.equalTo(_actionButton.snp.width) // Equal width to actionButton
        }
    }
    
    private func configureForTripleButtons() {
        _secondaryButton.isHidden = false
        tertiaryButton.isHidden = false
        
        // Using flex layout for buttons to ensure they fit
        let buttonSpacing: CGFloat = 8
        
        _actionButton.snp.remakeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(15)
            make.left.equalTo(iconImageView.snp.right).offset(15)
            make.height.equalTo(40)
            make.width.equalTo((containerView.frame.width - 30 - 2 * buttonSpacing) / 3) // Divide available width
        }
        
        _secondaryButton.snp.remakeConstraints { make in
            make.top.equalTo(_actionButton)
            make.left.equalTo(_actionButton.snp.right).offset(buttonSpacing)
            make.height.equalTo(40)
            make.width.equalTo(_actionButton.snp.width)
        }
        
        tertiaryButton.snp.remakeConstraints { make in
            make.top.equalTo(_actionButton)
            make.left.equalTo(_secondaryButton.snp.right).offset(buttonSpacing)
            make.right.equalToSuperview().offset(-15)
            make.height.equalTo(40)
            make.width.equalTo(_actionButton.snp.width)
            make.bottom.equalToSuperview().offset(-15)
        }
    }
    
    func configure(title: String, description: String, image: UIImage?, buttonTitle: String) {
        titleLabel.text = title
        descriptionLabel.text = description
        iconImageView.image = image
        _actionButton.setTitle(buttonTitle, for: .normal)
        
        // Set default layout
        configureForSingleButton()
    }
    
    func updateDescription(_ text: String) {
        descriptionLabel.text = text
    }
    
    func addSecondaryButton(title: String, action: @escaping () -> Void) {
        _secondaryButton.setTitle(title, for: .normal)
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
    
    @objc private func tertiaryButtonTapped() {
        tertiaryActionHandler?()
    }
} 