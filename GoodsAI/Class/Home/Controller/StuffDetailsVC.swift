//
//  AddGoodsVC.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/12.
//

import UIKit
import RxSwift
import PhotosUI
import ZLPhotoBrowser
class StuffDetailsVC: BaseViewController,UITableViewDelegate,UITableViewDataSource {
    var inventoryItem = InventoryItem(barcode: "", productName: "", productPrice: 0.0, imageData: nil, quantityInStock: 0, thumbImage: nil)
    var blockUpdate:((Int)->())?
    
    var dataArray = [[String: Any]]()


    
    private lazy var tableView: UITableView = {
        let tabView = UITableView(frame: CGRectZero, style: .plain)
        tabView.delegate = self
        tabView.delegate = self
        tabView.dataSource = self
        tabView.estimatedRowHeight = 200
        tabView.separatorColor = UIColor.clear
        tabView.tableHeaderView = self.contentImageView
        tabView.register(StuffDetailsDefaultInfoTVCell.self, forCellReuseIdentifier:"StuffDetailsDefaultInfoTVCell")
        if #available(iOS 15.0, *) {
            tabView.sectionHeaderTopPadding = 0;
        }
        return tabView
    }()
    
    
    private lazy var contentImageView: UIImageView = {
        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: kScreenWidth))
//        view.layer.cornerRadius = 6
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.backgroundColor = .cColor_other_ECEBFF
        view.isUserInteractionEnabled = true
        view.tintColor = .white
        view.image = UIImage(systemName: "photo.artframe.circle.fill")
        let tap = UITapGestureRecognizer(target: self, action: #selector(openPhotoBrowser))
        view.addGestureRecognizer(tap)
        return view
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Product Details"
        self.view.backgroundColor  = UIColor.white
        self.view.addSubview(self.tableView)

        
        self.tableView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalToSuperview()
        }
        self.makeStuddInfo()
        self.contentImageView.image = self.inventoryItem.thumbImage

        // Do any additional setup after loading the view.
    }
    
    func makeStuddInfo(){
        self.dataArray.append(["title":"Barcode","content":self.inventoryItem.barcode])
        self.dataArray.append(["title":"Product Name","content":self.inventoryItem.productName])
        self.dataArray.append(["title":"Price","content":String(inventoryItem.productPrice)])
        self.dataArray.append(["title":"Quantity in Stock","content":String(inventoryItem.quantityInStock)])
        self.dataArray.append(["title":"Score","content":String(inventoryItem.score ?? 0)])
        self.tableView.reloadData()

    }

    
    @objc func openPhotoBrowser() {
        
        if(self.inventoryItem.thumbImage != nil){
            let previewVC = ZLImagePreviewController(datas: [self.inventoryItem.thumbImage!],showSelectBtn: false,showBottomView: false)
               present(previewVC, animated: true)
        }
    }
 
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell : StuffDetailsDefaultInfoTVCell = tableView.dequeueReusableCell(withIdentifier: "StuffDetailsDefaultInfoTVCell", for: indexPath) as! StuffDetailsDefaultInfoTVCell
        cell.initTitleWithRow(par: self.dataArray[indexPath.row] as NSDictionary)
        return cell
    }
    




}


