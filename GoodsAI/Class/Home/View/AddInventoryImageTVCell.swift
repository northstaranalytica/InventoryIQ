//
//  AddGoodsTVCell.swift
//  GoodsAI
//
//  Created by Emily on 2025/3/12.
//

import UIKit
import RxSwift

class AddInventoryImageTVCell: UITableViewCell {

    var blockDidClickBtn:((Int)->())?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    

    
    private lazy var titleLable: UILabel = {
        let label = UILabel()
        label.text = "Product Image"
        label.textAlignment = NSTextAlignment.left
        label.textColor = UIColor.cColor_text_333
        label.font = UIFont.systemFont(ofSize: 14,weight: UIFont.Weight.regular)

        return label
    }()
    
    
    private lazy var contentImageView: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 6
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.backgroundColor = .cColor_other_ECEBFF
        view.tintColor = .white
        view.image = UIImage(systemName: "photo.artframe.circle.fill")

        return view
    }()
    
    private lazy var cameraImageBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(systemName: "camera"), for: .normal)
        btn.backgroundColor = .kHexRGB(0x65C466)
        btn.layer.cornerRadius = 8
        btn.tintColor = .white
        btn.tag = 1
        btn.addTarget(self, action: #selector(clickAddImage), for: .touchUpInside)
        return btn
    }()
    
    private lazy var photoImageBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(systemName: "photo.on.rectangle"), for: .normal)
        btn.backgroundColor = .kHexRGB(0xF19A37)
        btn.tintColor = .white
        btn.layer.cornerRadius = 8
        btn.tag = 2
        btn.addTarget(self, action: #selector(clickAddImage), for: .touchUpInside)
        return btn
    }()
    


    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = UIColor.white
       
        self.contentView.addSubview(titleLable)
        self.contentView.addSubview(contentImageView)
        self.contentView.addSubview(cameraImageBtn)
        self.contentView.addSubview(photoImageBtn)

        
        

        self.titleLable.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(30)
            make.top.equalToSuperview().offset(12)
            make.width.equalTo(78)
        }
        
        self.contentImageView.snp.makeConstraints { make in
            make.top.equalTo(self.titleLable.snp.top).offset(2)
            make.left.equalTo(titleLable.snp.right).offset(6)
            make.width.equalTo(150)
            make.height.equalTo(100)
            make.bottom.equalToSuperview()

        }
        
        self.cameraImageBtn.snp.makeConstraints { make in
            make.top.equalTo(self.contentImageView.snp.top)
            make.left.equalTo(contentImageView.snp.right).offset(6)
            make.right.equalToSuperview().offset(-30)
            make.height.equalTo(45)
        }
        
        self.photoImageBtn.snp.makeConstraints { make in
            make.top.equalTo(self.cameraImageBtn.snp.bottom).offset(5)
            make.left.equalTo(contentImageView.snp.right).offset(6)
            make.right.equalToSuperview().offset(-30)
            make.height.equalTo(45)
        }
        
        
  
    }
    
    
    @objc func clickAddImage(btn: UIButton) {
        
        if (self.blockDidClickBtn != nil ){
            self.blockDidClickBtn?(btn.tag)
        }
    }
    
    func initTitleWithRow(image: UIImage?){
        if(image != nil){
            self.contentImageView.image = image
        }
        
    }
    
//    @objc func tapImageView() {
//        if (self.blockDidClickBtn != nil ){
//            self.blockDidClickBtn?(0)
//        }
//    }
//    
    
//    func initTitleWithRow(row:Int,model: LockDetailsResponseData?){
//        
//        self.contentImageView.isHidden = true
//        self.addconImageView.isHidden = false
//        self.updateBtn.isHidden = true
//        self.imageBgTitleView.isHidden = false
//
//        
//        if( model != nil && model?.livePictures != nil  && model?.livePictures?.count ?? 0>0){
//        
//            self.contentImageView.sd_setImage(with:NSURL(string:PhotosManagerClass.getNetworkImageBaseUrl()+(model!.livePictures ?? "")) as URL?)
//            self.contentImageView.isHidden = false
//            self.addconImageView.isHidden = true
//            self.updateBtn.isHidden = false
//            self.imageBgTitleView.isHidden = true
//
//            self.lineView.snp.updateConstraints { make in
//                make.top.equalTo(self.updateBtn.snp.bottom).offset(2)
//            }
//
//        }else{
//            
//            self.lineView.snp.updateConstraints { make in
//                make.top.equalTo(self.updateBtn.snp.bottom).offset(10)
//            }
//        }
//    }
}
