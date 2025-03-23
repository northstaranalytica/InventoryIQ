//
//  BaseViewController.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/11.
//

import UIKit
import SnapKit


class BaseViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        // 有导航栏时设置是否穿过导航栏，默认不穿过，需要穿过自己页面设置 .top
        self.edgesForExtendedLayout = UIRectEdge.init()
        
        showLeftBackButton()
    }
    
    // 显示返回按钮
    public func showLeftBackButton() {
        if self.navigationController?.viewControllers.count ?? 0 > 1 {
            let backItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(navigationBack))
            //backItem.imageInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)
            self.navigationItem.leftBarButtonItem = backItem
        }
    }
    
    // 返回
    @objc func navigationBack() {
        self.navigationController?.popViewController(animated: true)
    }

    // 找到navigation中指定的VC
    public func getNavigationChildrenController(type: UIViewController.Type) -> UIViewController? {
        guard let childrenVC = navigationController?.children else {
            return nil
        }
        return childrenVC.first(where: { $0.isMember(of: type) })
    }
}
