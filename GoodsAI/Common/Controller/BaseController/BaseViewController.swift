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
        // When there is a navigation bar, set whether to pass through the navigation bar, default is not to pass through, need to set .top in your page to pass through
        self.edgesForExtendedLayout = UIRectEdge.init()
        
        showLeftBackButton()
    }
    
    // Show back button
    public func showLeftBackButton() {
        if self.navigationController?.viewControllers.count ?? 0 > 1 {
            let backItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(navigationBack))
            //backItem.imageInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)
            self.navigationItem.leftBarButtonItem = backItem
        }
    }
    
    // Back
    @objc func navigationBack() {
        self.navigationController?.popViewController(animated: true)
    }

    // Find the specified VC in navigation
    public func getNavigationChildrenController(type: UIViewController.Type) -> UIViewController? {
        guard let childrenVC = navigationController?.children else {
            return nil
        }
        return childrenVC.first(where: { $0.isMember(of: type) })
    }
}
