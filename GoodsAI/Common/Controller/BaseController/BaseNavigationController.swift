//
//  BaseNavigationController.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/11.
//

import UIKit

class BaseNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
        navigationBar.tintColor = .systemBlue
    }
    
    // 拦截 push 操作，自动隐藏底部 TabBar
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if viewControllers.count > 0 {
            viewController.hidesBottomBarWhenPushed = true
        }
        super.pushViewController(viewController, animated: animated)
    }
}

extension BaseNavigationController: UIGestureRecognizerDelegate {
    // 允许侧滑返回
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
