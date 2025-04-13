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
    /// Remove page loading, empty data view, network error view
    case CT_normal
    /// Set page loading state
    case CT_loading
    /// Set page empty data, no background color
    case CT_empty
    /// Set page network error
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
//            //Network error, click to reload operation
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


//MARK: - Get current view controller
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
    
    /// Partial corner radius
    func CTCorner(byRoundingCorners corners: UIRectCorner, radii: CGFloat, size: CGSize) {
        let maskPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size.width, height: size.height), byRoundingCorners: corners, cornerRadii: CGSize(width: radii, height: radii))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = maskPath.cgPath
        self.layer.mask = maskLayer
        self.layer.masksToBounds = true
    }
}

