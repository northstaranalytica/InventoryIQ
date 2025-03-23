//
//  AddGoodsVC.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/12.
//

import UIKit
import RxSwift
import PhotosUI
class AddInventoryVC: BaseViewController,UITableViewDelegate,UITableViewDataSource {
    var inventoryItem = InventoryItem(barcode: "", productName: "", productPrice: 0.0, imageData: nil, quantityInStock: 0, thumbImage: nil)
    var blockUpdate:((Int)->())?

    
    private lazy var choicePhotoTools: ChoicePhotoTools = {
        let object = ChoicePhotoTools()
        object.blockComplete = {[weak self] image in
            guard let `self` = self else { return }
            self.inventoryItem.thumbImage = image
            self.tableView.reloadData()
        }
        return object
    }()
    
    private lazy var buttomView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        let submitBtn = UIButton()
        submitBtn.backgroundColor = UIColor.cColor_light_blue
        submitBtn.layer.cornerRadius = 8
        submitBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        submitBtn.setTitle("保 存", for: UIControl.State())
        submitBtn.setTitleColor(UIColor.white, for: UIControl.State())
        submitBtn.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.center
        submitBtn.addTarget(self, action: #selector(addInventoryAction), for: .touchUpInside)

        view.addSubview(submitBtn)

        submitBtn.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(30)
            make.right.equalToSuperview().offset(-30)
            make.centerY.equalToSuperview().offset(-10)
            make.height.equalTo(40)
        }

        return view
    }()
    
    
    private lazy var tableView: UITableView = {
        let tabView = UITableView(frame: CGRectZero, style: .plain)
        tabView.delegate = self
        tabView.delegate = self
        tabView.dataSource = self
        tabView.estimatedRowHeight = 200
        tabView.separatorColor = UIColor.clear
        tabView.tableHeaderView = UIView(frame:  CGRect(x: 0, y: 0, width: kScreenWidth, height: 10))
        tabView.register(AddInventoryInfoTVCell.self, forCellReuseIdentifier:"AddInventoryInfoTVCell")
        tabView.register(AddInventoryImageTVCell.self, forCellReuseIdentifier:"AddInventoryImageTVCell")
        if #available(iOS 15.0, *) {
            tabView.sectionHeaderTopPadding = 0;
        }
        return tabView
    }()
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Add inventory Item"
        self.view.backgroundColor  = UIColor.white
        self.view.addSubview(self.buttomView)
        self.view.addSubview(self.tableView)

        
        self.buttomView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(90)
        }
        
        self.tableView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalTo(self.buttomView.snp.top)
            make.top.equalToSuperview()
        }
        // Do any additional setup after loading the view.
    }
    
    @objc func addInventoryAction(btn: UIButton) {

        if(inventoryItem.barcode.isEmpty){
            ProgressTools.showError("条形码不能为空!")
            return
        }
        if(inventoryItem.productName.isEmpty){
            ProgressTools.showError("产品名称不能为空！")
            return
        }
         if(inventoryItem.thumbImage == nil ){
            ProgressTools.showError("产品图片不能为空！")
            return
        }
        if(inventoryItem.recordID != nil){
            ProgressTools.showError("暂时不能更新！")
            return
        }
        ProgressTools.showLoading("正在新增产品...", self.view)
        CloudKitManager.shared.saveNote(note: inventoryItem,completion: {
            result in
               switch result {
               case .success(let record):
                   DispatchQueue.main.async {
                       ProgressTools.showSuccess("新增成功。。。")
                       if((self.blockUpdate) != nil){
                           self.blockUpdate!(1)
                       }
                       self.navigationController?.popViewController(animated: true)
                   }
                   _ = LocalInventory(record: record)
               case .failure(let error):
                   print("解析记录失败: \(error.localizedDescription)")
               }
        })
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if(indexPath.row < 4 ){
            let cell : AddInventoryInfoTVCell = tableView.dequeueReusableCell(withIdentifier: "AddInventoryInfoTVCell", for: indexPath) as! AddInventoryInfoTVCell
            cell.initTitleWithRow(row: indexPath.row,inventoryItem:self.inventoryItem)
            cell.blockTextFieldAction = {text in
                if(indexPath.row == 0 ){
                    self.inventoryItem.barcode = text
                }
                else if(indexPath.row == 1 ){
                    self.inventoryItem.productName = text
                }
                else if(indexPath.row == 2 ){
                    if Double(text) != nil {
                        self.inventoryItem.productPrice = Double(text) ?? 0.0
                    } else {
                        ProgressTools.showError("格式错误！")
                    }
                }
                else if(indexPath.row == 3 ){
                    if Int(text) != nil {
                        self.inventoryItem.quantityInStock = Int(text) ?? 0
                    } else {
                        ProgressTools.showError("格式错误！")
                    }
                }

            }
            return cell
        }
        else if(indexPath.row == 4)
        {
            let cell : AddInventoryImageTVCell = tableView.dequeueReusableCell(withIdentifier: "AddInventoryImageTVCell", for: indexPath) as! AddInventoryImageTVCell
            cell.initTitleWithRow(image:self.inventoryItem.thumbImage)
            cell.blockDidClickBtn = {
                [weak self] type in
                guard let `self` = self else { return }
                if(type == 1){
                    takePhoto()
                }else if(type == 2){
                    choicePhoto()
                }
            }
            return cell
        }
        let cell : UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        return cell
    }
    

    private func takePhoto(){
        self.choicePhotoTools.takePhoto(controller: self)
    }
    
    private func choicePhoto(){
        self.choicePhotoTools.choicePhoto(controller: self)
    }
    


}


