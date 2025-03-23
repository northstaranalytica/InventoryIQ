//
//  AddGoodsTVCell.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/12.
//

import UIKit
import RxSwift

class AddInventoryInfoTVCell: UITableViewCell {

    
    var blockTextFieldAction:((String)->())?
    private let disposeBag = DisposeBag()
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    // 背景
    lazy var whiteBgView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    
    private lazy var titleLable: UILabel = {
        let label = UILabel()
        label.text = "工单类型"
        label.textAlignment = NSTextAlignment.left
        label.textColor = UIColor.cColor_text_333
        label.font = UIFont.systemFont(ofSize: 14,weight: UIFont.Weight.regular)

        return label
    }()
    
    
    private lazy var contentTextFiled: UITextField = {
        let textFiled = UITextField()
        textFiled.placeholder = ""
        textFiled.textAlignment = NSTextAlignment.left
        textFiled.textColor = UIColor.cColor_text_333
        textFiled.font = UIFont.systemFont(ofSize: 14,weight: UIFont.Weight.regular)
        textFiled.textAlignment = .left
        textFiled.rx.text.orEmpty.changed.subscribe(onNext: { (text) in
            if(self.blockTextFieldAction != nil){
                self.blockTextFieldAction!(text)
            }
           }).disposed(by: disposeBag)
        return textFiled
    }()
    
    
    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.cColor_Line
        return view
    }()
    
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = UIColor.white
       
        self.contentView.addSubview(whiteBgView)
        self.whiteBgView.addSubview(titleLable)
        self.whiteBgView.addSubview(contentTextFiled)
        self.whiteBgView.addSubview(lineView)

        whiteBgView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(30)
            make.top.equalToSuperview()
            make.right.equalToSuperview().offset(-30)
            make.height.equalTo(44)
        }
        

        titleLable.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(78)
        }
        
        contentTextFiled.snp.makeConstraints { make in
            make.left.equalTo(titleLable.snp.right).offset(6)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
        }
        

        lineView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        
    }
    
    

    
    func initTitleWithRow(row:Int,inventoryItem: InventoryItem){
        

        if(row == 0 ){
            self.titleLable.text = "条形码"
            self.contentTextFiled.placeholder = "Barcode"
            self.contentTextFiled.keyboardType = .asciiCapable
            self.contentTextFiled.text = inventoryItem.barcode

        }
        else if(row == 1){
            self.titleLable.text = "产品名称"
            self.contentTextFiled.placeholder = "Product Name"
            self.contentTextFiled.text = inventoryItem.productName
            self.contentTextFiled.keyboardType = .default
        }
        else if(row == 2){
            self.titleLable.text = "价格"
            self.contentTextFiled.placeholder = "Price"
            self.contentTextFiled.text = String(inventoryItem.productPrice)
            self.contentTextFiled.keyboardType = .decimalPad

        }
        else if(row == 3){
            self.titleLable.text = "库存数量"
            self.contentTextFiled.placeholder = "Quantity In Stock"
            self.contentTextFiled.text = String(inventoryItem.quantityInStock ?? 0)
            self.contentTextFiled.keyboardType = .asciiCapableNumberPad
        }


        
    }
    
    
 
    

}
