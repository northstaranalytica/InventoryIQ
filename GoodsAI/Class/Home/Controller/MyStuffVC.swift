//
//  MyStuffVC.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/11.
//

import UIKit
import RxSwift
import RxCocoa
import AVFAudio
import Speech

class MyStuffVC: BaseViewController ,UITableViewDelegate,UITableViewDataSource {

//    private let databaseManager = DatabaseManager.shared
    var similarItems: [InventoryItem] = []
    var searchImage: UIImage?
    var searchText: String = ""
    
    // For technical diagnostics
    var lastQueryVector: [Float]?
    var lastQueryType: String = ""

    
    private lazy var tableView: UITableView = {
        let tabView = UITableView(frame: CGRectZero, style: .grouped)
        tabView.delegate = self
        tabView.dataSource = self
        tabView.estimatedRowHeight = 200
        tabView.separatorColor = .clear
        tabView.backgroundColor = .white
        tabView.register(GoodsItemTVCell.self, forCellReuseIdentifier:"GoodsItemTVCell")
        tabView.register(AccordingImageSearchTVCell.self, forCellReuseIdentifier:"AccordingImageSearchTVCell")
        tabView.register(AccordingTextSearchTVCell.self, forCellReuseIdentifier:"AccordingTextSearchTVCell")
        if #available(iOS 15.0, *) {
            tabView.sectionHeaderTopPadding = 0
        }
        return tabView
    }()
    
    
    private lazy var voiceToText: VoiceToTextTools = {
        let voiceToText = VoiceToTextTools()
        voiceToText.blockInputText = {[weak self] text in
            guard let `self` = self else { return }
            self.searchText = text
            
        }
     
        return voiceToText
    }()
    
    private lazy var choicePhotoTools: ChoicePhotoTools = {
        let object = ChoicePhotoTools()
        object.blockComplete = {[weak self] image in
            guard let `self` = self else { return }
            self.searchImage = image
            self.tableView.reloadData()
        }
        return object
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Home"
        self.view.addSubview(self.tableView)
        self.voiceToText.requestRecordPermission()

        self.tableView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Reset search results to ensure fresh data is used in searches
        self.similarItems.removeAll()
        self.tableView.reloadData()
    }
    
    
    // No longer needed as we're using local storage directly
    // func updateInventory() { ... }

    
    


    func findSimilarItemsByText(){
        
        let query = self.searchText
        if(self.searchText.isEmpty){
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
            let items = DatabaseManager.shared.findSimilarItemsByText(query: query, limit: 5)
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
    
    
    
    // Find similar items to the given image
    func findSimilarItems() {
        if(self.searchImage == nil){
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
            let items = DatabaseManager.shared.findSimilarItems(to: imageData, limit: 5)
            DispatchQueue.main.async {
                self.similarItems = items
                self.tableView.reloadData()
                ProgressTools.hide(self.view)
            }
        }
    }
    
    
    func acctodingToItemsTextSearch(type:Int){
        if(type == 0){
            self.findSimilarItemsByText()
        }
        else if( type == 1){
            self.voiceToText.startLiveTranscribe()
        }
        else if( type == 2){
            self.voiceToText.stopLiveTranscribe()
            self.tableView.reloadData()
            self.findSimilarItemsByText()
        }
    }
    
    
    func accordingToImageAction(type:Int){
        if(type == 0){
            self.choicePhotoTools.takePhoto(controller: self)
        }
       else if(type == 1){
           self.choicePhotoTools.choicePhoto(controller: self)
        }
        else if(type == 2){
            self.findSimilarItems()
        }
    }
    
  
  
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(section < 2){
            return 1
        }
        return self.similarItems.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: 58))
        view.backgroundColor = .white
        let centerVIew = UIView(frame: CGRect(x: 20, y: 14, width: kScreenWidth-40, height: 44))
        centerVIew.layer.cornerRadius = 8
        centerVIew.backgroundColor = .cColor_F3F3F3
        centerVIew.layer.maskedCorners = CACornerMask(rawValue: UIRectCorner.topLeft.rawValue | UIRectCorner.topRight.rawValue)
        
        let label = UILabel(frame: CGRect(x: 20, y: 14, width: kScreenWidth-80, height: 16))
        label.textColor = UIColor.cColor_text_333
        label.font = UIFont.systemFont(ofSize: 14,weight: UIFont.Weight.semibold)
        label.text = "Search Results"

        if(section == 0){
            label.text = "Search by Description"
        }
        else if( section == 1){
            label.text = "Find Similar Items"
        }

        view.addSubview(centerVIew)
        centerVIew.addSubview(label)

        return view
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 58
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: 20))
        view.backgroundColor = .white
        let centerVIew = UIView(frame: CGRect(x: 20, y: 0, width: kScreenWidth-40, height: 20))
        centerVIew.layer.cornerRadius = 8
        centerVIew.backgroundColor = .cColor_F3F3F3
        centerVIew.layer.maskedCorners = CACornerMask(rawValue: UIRectCorner.bottomLeft.rawValue | UIRectCorner.bottomRight.rawValue)
        view.addSubview(centerVIew)
        return view
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if(indexPath.section == 0){
            let cell : AccordingTextSearchTVCell = tableView.dequeueReusableCell(withIdentifier: "AccordingTextSearchTVCell", for: indexPath) as! AccordingTextSearchTVCell
            cell.blockInputText = {[weak self] text in
                guard let `self` = self else { return }
                self.searchText = text
            }
            cell.blockActiont = {[weak self] type in
                guard let `self` = self else { return }
                self.acctodingToItemsTextSearch(type: type)
            }
            cell.updateText(text: self.searchText)
            return cell
        }
        else if(indexPath.section == 1){
            
            let cell : AccordingImageSearchTVCell = tableView.dequeueReusableCell(withIdentifier: "AccordingImageSearchTVCell", for: indexPath) as! AccordingImageSearchTVCell
            cell.showImage(image: self.searchImage)
            cell.blockAction = {[weak self] type in
                guard let `self` = self else { return }
                self.accordingToImageAction(type: type)
            }
            return cell
        }
        
        let cell : GoodsItemTVCell = tableView.dequeueReusableCell(withIdentifier: "GoodsItemTVCell", for: indexPath) as! GoodsItemTVCell
        cell.updateInfo(inventoryItem: self.similarItems[indexPath.row])
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if(indexPath.section == 2){
            let vc = StuffDetailsVC()
            vc.inventoryItem = self.similarItems[indexPath.row]
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
    }


    

    
}
