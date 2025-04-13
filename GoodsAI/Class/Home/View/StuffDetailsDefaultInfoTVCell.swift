//
//  AccordingTextSearchTVCell.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/12.
//

import UIKit
import RxSwift


class StuffDetailsDefaultInfoTVCell: UITableViewCell {

    
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
    
    
    // Background
    lazy var whiteBgView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    
    private lazy var titleLable: UILabel = {
        let label = UILabel()
        label.text = "Work Order Type"
        label.textAlignment = NSTextAlignment.left
        label.textColor = UIColor.cColor_text_333
        label.font = UIFont.systemFont(ofSize: 14,weight: UIFont.Weight.regular)

        return label
    }()
    
    
    
    
    private lazy var contentLable: UILabel = {
        let label = UILabel()
        label.text = "Content"
        label.textAlignment = NSTextAlignment.left
        label.textColor = UIColor.cColor_text_333
        label.font = UIFont.systemFont(ofSize: 14,weight: UIFont.Weight.regular)

        return label
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
        self.whiteBgView.addSubview(contentLable)
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
        
        contentLable.snp.makeConstraints { make in
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
    
    

    
    func initTitleWithRow(par:NSDictionary){

        self.titleLable.text = par["title"] as? String
        self.contentLable.text = par["content"] as? String
    }
    
    
 
    

}
