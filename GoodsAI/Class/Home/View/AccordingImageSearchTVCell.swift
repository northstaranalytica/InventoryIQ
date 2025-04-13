//
//  AccordingImageSearchTVCell.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/12.
//

import UIKit

class AccordingImageSearchTVCell: UITableViewCell {

    // 0 camera   1 gallery  2 search
    var blockAction:((Int)->())?

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
       
        self.contentView.addSubview(self.imageBgView)
        self.imageBgView.addSubview(self.cameraImageBtn)
        self.imageBgView.addSubview(self.photoImageBtn)

        self.imageBgView.addSubview(self.imageContentView)
        self.imageBgView.addSubview(self.imageSearchBtn)
        
        
        self.imageBgView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview()
        }
        
        
        self.cameraImageBtn.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.height.equalTo(80)
            make.width.equalTo(kScreenWidth/2-45)
        }
        
        self.photoImageBtn.snp.makeConstraints { make in
            make.centerY.equalTo(self.cameraImageBtn)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(80)
            make.width.equalTo(kScreenWidth/2-45)

        }
        
        
        self.imageContentView.snp.makeConstraints { make in
            make.top.equalTo(self.cameraImageBtn.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(20)
            make.height.equalTo(0)
            make.width.equalTo(kScreenWidth/2-45)
            make.bottom.equalToSuperview()
        }
        
        self.imageSearchBtn.snp.makeConstraints { make in
            make.centerY.equalTo(self.imageContentView)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(0)
            make.width.equalTo(kScreenWidth/2-45)
        }
        
    }

    
    func showImage(image:UIImage?){
        
        if(image != nil){
            self.imageSearchBtn.snp.updateConstraints { make in
                make.height.equalTo(80)
            }
            self.imageContentView.snp.updateConstraints { make in
                make.height.equalTo(80)
            }
        }
        
        self.imageContentView.image = image
        
    }
    
    
    @objc func clickSearchAction(btn: UIButton) {
        if((self.blockAction) != nil){
            self.blockAction!(btn.tag)
        }
    }
    
    lazy var imageBgView: UIView = {
        let view = UIView()
        view.backgroundColor = .cColor_F3F3F3
        return view
    }()
    

    private lazy var cameraImageBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("Camera", for: .normal)
        btn.setImage(UIImage(systemName: "camera"), for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        btn.backgroundColor = .kHexRGB(0x65C466)
        btn.layer.cornerRadius = 8
        btn.tintColor = .white
        btn.tag = 0
        btn.addTarget(self, action: #selector(clickSearchAction), for: .touchUpInside)
        return btn
    }()
    
    private lazy var photoImageBtn: UIButton = {
        let btn = UIButton()
        btn.setTitle("Gallery", for: .normal)
        btn.setImage(UIImage(systemName: "photo.on.rectangle"), for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        btn.backgroundColor = .kHexRGB(0xF19A37)
        btn.tintColor = .white
        btn.layer.cornerRadius = 8
        btn.tag = 1
        btn.addTarget(self, action: #selector(clickSearchAction), for: .touchUpInside)
        return btn
    }()
    
    
    lazy var imageContentView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .cColor_other_7C79F4
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var imageSearchBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle("Find Similar", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        btn.backgroundColor = .cColor_other_7C79F4
        btn.tintColor = .white
        btn.layer.cornerRadius = 8
        btn.tag = 2
        btn.addTarget(self, action: #selector(clickSearchAction), for: .touchUpInside)
        return btn
    }()
    

}
