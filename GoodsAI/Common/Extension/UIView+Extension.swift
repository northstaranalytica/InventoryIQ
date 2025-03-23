//
//  UIView+Extension.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/11.
//

import UIKit
let CTEmptyViewTag: Int = 100121200
let CTNetErrorViewTag: Int = 100121201

enum CTViewState {
    /// 移除页面loading、无数据视图、网络异常视图
    case CT_normal
    /// 设置页面loading状态
    case CT_loading
    /// 设置页面无数据，无背景色
    case CT_empty
    /// 设置页面网络异常
    case CT_netError
}

extension UIView {
    /*
    private static var errorViewKey = true
    var errorView : CTNetErrorView?{
        get {
            return objc_getAssociatedObject(self , &Self.errorViewKey) as? CTNetErrorView
        }
        set {
            objc_setAssociatedObject(self, &Self.errorViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    */
    
    func setViewState(state: CTViewState,
                      title: String? = nil,
                      imageName: String? = nil,
                      reloadAction: (()->())? = nil){
        
        self.setViewNormal()
        
        switch(state){
        case .CT_loading:
//            CTToast.showNetLoadingAtCenter(onView: self)
            break
        case .CT_normal:
            
            break;
        case .CT_empty:
            self.addEmptyView(emptyTitle: title, emptyImageName: imageName)
            break
        case .CT_netError:
//            self.addNetErrorView(reloadAction: reloadAction)
            break;
        }
    }
    
    private func setViewNormal() {
        if let empty = self.viewWithTag(CTEmptyViewTag) {
            empty.removeFromSuperview()
        }
        if let netErrorVIew = self.viewWithTag(CTNetErrorViewTag) {
            netErrorVIew.removeFromSuperview()
        }
//        CTToast.hideNetLoadingAtCenter(onView: self)
    }
    
    private func addEmptyView(emptyTitle: String? = nil, emptyImageName: String? = nil) {
//        let empty = CTEmptyView()
//        empty.createSubviews(title: emptyTitle, imageName: emptyImageName)
//        empty.tag = CTEmptyViewTag
//        if(emptyTitle != nil){
//            empty.titleLabel.text = emptyTitle;
//        }
//        if(emptyImageName != nil){
//            empty.imageView.image = UIImage(named: emptyImageName!)
//        }
//        self.addSubview(empty)
//        empty.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//            make.size.equalTo(self)
//        }
    }
    
//    private func addNetErrorView(reloadAction: (()->())? = nil) {
//        let netError = CTNetErrorView()
//        netError.backgroundColor = .CTLightGray_F9F9F9
//        netError.createSubviews(title: nil, imageName: nil){
//            //网络异常时、点击重新加载操作
//            reloadAction?()
//        }
//        netError.tag = CTNetErrorViewTag
//
//        self.addSubview(netError)
//        netError.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//            make.size.equalTo(self)
//        }
//    }
    
}


//MARK: - 获取当前视图控制器
extension UIView {
    
    
    func CT_findController() -> UIViewController? {
        return self.CT_findControllerWithClass(UIViewController.self)
    }
    
    func CT_findNavigation() -> UINavigationController? {
        return self.CT_findControllerWithClass(UINavigationController.self)
    }
    
    func CT_findControllerWithClass<T>(_ clzz: AnyClass) -> T? {
        var responder = self.next
        while(responder != nil) {
            if (responder!.isKind(of: clzz)) {
                return responder as? T
            }
            responder = responder?.next
        }
        return nil
    }
    
    /// 部分圆角
    func CTCorner(byRoundingCorners corners: UIRectCorner, radii: CGFloat, size: CGSize) {
        let maskPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size.width, height: size.height), byRoundingCorners: corners, cornerRadii: CGSize(width: radii, height: radii))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = maskPath.cgPath
        self.layer.mask = maskLayer
        self.layer.masksToBounds = true
    }
}

