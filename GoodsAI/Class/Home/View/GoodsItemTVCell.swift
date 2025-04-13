//
//  GoodsItemTVCell.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/11.
//

import UIKit

class GoodsItemTVCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = UIColor.white
       
        self.contentView.addSubview(self.whiteBgView)
        self.whiteBgView.addSubview(self.imageContentView)
        self.whiteBgView.addSubview(self.productNameLable)
        self.whiteBgView.addSubview(self.productPriceLable)
        self.whiteBgView.addSubview(self.inventoryLable)
        self.whiteBgView.addSubview(self.scoreLable)
        self.whiteBgView.addSubview(self.bottomLineView)

        self.whiteBgView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(5)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-5)
        }
        
        self.imageContentView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.top.equalToSuperview().offset(12)
            make.width.height.equalTo(80)
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
   
        self.productNameLable.snp.makeConstraints { make in
            make.left.equalTo(self.imageContentView.snp.right).offset(12)
            make.top.equalTo(self.imageContentView.snp.top).offset(2)
            make.right.equalToSuperview().offset(-10)
        }
        
        self.scoreLable.snp.makeConstraints { make in
            make.left.equalTo(self.productNameLable.snp.left)
            make.top.equalTo(self.productNameLable.snp.bottom).offset(5)
            make.right.equalToSuperview().offset(-10)
        }
        
        self.productPriceLable.snp.makeConstraints { make in
            make.left.equalTo(self.productNameLable.snp.left)
            make.top.equalTo(self.scoreLable.snp.bottom).offset(5)
            make.bottom.lessThanOrEqualTo(self.imageContentView.snp.bottom)
        }
        
        self.inventoryLable.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalTo(self.productPriceLable.snp.centerY)
        }
        
        self.bottomLineView.snp.makeConstraints { make in
            make.left.equalTo(self.productNameLable.snp.left)
            make.right.equalToSuperview().offset(-10)
            make.height.equalTo(0.6)
            make.bottom.equalToSuperview().offset(-5)
            make.top.equalTo(self.imageContentView.snp.bottom).offset(8)
        }
    }

    func updateInfo(inventoryItem:InventoryItem){
        
        self.productNameLable.text = inventoryItem.productName
        self.productPriceLable.text = "$"+String(format: "%.2f", inventoryItem.productPrice)
        self.inventoryLable.text = "库存 " + String(inventoryItem.quantityInStock)
        self.imageContentView.image = inventoryItem.thumbImage
        
        if(inventoryItem.score != nil) {
            self.scoreLable.text = "Score: " + String(format: "%.2f", inventoryItem.score ?? 0.0)
        } else {
            self.scoreLable.text = ""
        }
    }
    
    
    // 背景
    lazy var whiteBgView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.isUserInteractionEnabled = true
        view.layer.cornerRadius = 8
        view.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowOpacity = 0.5
        view.layer.shadowRadius = 4
        return view
    }()
    

    lazy var imageContentView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = UIColor.systemGray5
        view.contentMode = .scaleAspectFit
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var productNameLable: UILabel = {
        let label = UILabel()
        label.text = "商品名称"
        label.textAlignment = NSTextAlignment.left
        label.textColor = UIColor.darkText
        label.font = UIFont.systemFont(ofSize: 14,weight: UIFont.Weight.semibold)
        return label
    }()
    
    private lazy var productPriceLable: UILabel = {
        let label = UILabel()
        label.text = "$200"
        label.textAlignment = NSTextAlignment.left
        label.textColor = UIColor.darkText
        label.font = UIFont.systemFont(ofSize: 14,weight: UIFont.Weight.semibold)
        return label
    }()

    private lazy var inventoryLable: UILabel = {
        let label = UILabel()
        label.text = "库存：200"
        label.textAlignment = NSTextAlignment.left
        label.textColor = UIColor.lightGray
        label.font = UIFont.systemFont(ofSize: 12,weight: UIFont.Weight.regular)
        return label
    }()
    
    private lazy var scoreLable: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textAlignment = NSTextAlignment.left
        label.textColor = UIColor.darkText
        label.font = UIFont.systemFont(ofSize: 12,weight: UIFont.Weight.regular)
        return label
    }()
    
    lazy var bottomLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        return view
    }()


}
