//
//  AccordingTextSearchTVCell.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/12.
//

import UIKit
import RxSwift

class AccordingTextSearchTVCell: UITableViewCell {
    private let disposeBag = DisposeBag()
    var blockInputText:((String)->())?
    // 0 search click   1 recording  2 voice end
    var blockActiont:((Int)->())?

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
       
        self.contentView.addSubview(self.textBgView)
        self.textBgView.addSubview(self.audioBtn)
        self.textBgView.addSubview(self.contentTextFiled)
        self.textBgView.addSubview(self.searchBtn)
        
        self.textBgView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview()
        }
        
        
        self.audioBtn.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
            make.left.equalToSuperview().offset(20)
            make.height.equalTo(40)
        }
        
        self.searchBtn.snp.makeConstraints { make in
            make.centerY.equalTo(self.contentTextFiled)
            make.right.equalToSuperview().offset(-20)
            make.width.equalTo(40)
            make.height.equalTo(40)
        }
        
        self.contentTextFiled.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(self.audioBtn.snp.bottom).offset(20)
            make.right.equalTo(self.searchBtn.snp.left).offset(-20)
            make.height.equalTo(40)
            make.bottom.equalToSuperview()
        }

    }

    
    // MARK: - Event Handling

    func updateText(text:String){
        self.contentTextFiled.text = text;
    }
    
    @objc func clickSearchAction(btn: UIButton) {
        
        if((self.blockActiont) != nil){
            self.blockActiont!(0)
        }
    }
    
    @objc private func handleTouchDown(btn: UIButton) {
        btn.backgroundColor = .systemRed
        // Vibration feedback (iOS 10+)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if((self.blockActiont) != nil){
            self.blockActiont!(1)
        }
    }
    
    @objc private func handleTouchUp(btn: UIButton) {
        btn.backgroundColor = .cColor_other_7C79F4
        if((self.blockActiont) != nil){
            self.blockActiont!(2)
        }

    }

    
    
    
    // Background
    lazy var textBgView: UIView = {
        let view = UIView()
        view.backgroundColor = .cColor_F3F3F3
        return view
    }()
    
    private lazy var contentTextFiled: UITextField = {
        let textFiled = UITextField()
        textFiled.placeholder = "Describe what you're looking for..."
        textFiled.textAlignment = NSTextAlignment.left
        textFiled.textColor = UIColor.cColor_text_333
        textFiled.font = UIFont.systemFont(ofSize: 14,weight: UIFont.Weight.regular)
        textFiled.borderStyle = .roundedRect
        textFiled.rx.text.orEmpty.changed.subscribe(onNext: { (text) in
            if((self.blockInputText) != nil){
                self.blockInputText!(text)
            }
           }).disposed(by: disposeBag)
        return textFiled
    }()
    
    private lazy var searchBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        btn.setTitleColor(.cColor_Main, for: .normal)
        btn.tag = 1
        btn.addTarget(self, action: #selector(clickSearchAction), for: .touchUpInside)
        return btn
    }()
    
    
    private lazy var audioBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(systemName: "microphone"), for: .normal)
        btn.setImage(UIImage(systemName: "microphone.fill"), for: .highlighted)

        
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle("Press and hold to search by voice", for: .normal)
        btn.setTitle("Recording...", for: .highlighted)

        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14,weight: UIFont.Weight.regular)
        btn.tintColor = .white
        btn.backgroundColor = .cColor_other_7C79F4
        btn.tag = 1
        btn.layer.cornerRadius = 8
        btn.addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragEnter])
        btn.addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchUpOutside, .touchDragExit, .touchCancel])

        return btn
    }()
    
}
