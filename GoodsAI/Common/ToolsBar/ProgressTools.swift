//
//  ToolsBar.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/13.
//

import Foundation
import MBProgressHUD


class ProgressTools {


    /// 通用样式配置
        private static func setupCommonStyle(hud: MBProgressHUD) {
            hud.contentColor = .white
            hud.bezelView.color = UIColor.black.withAlphaComponent(0.7)
            hud.bezelView.style = .solidColor
            hud.minSize = CGSize(width: 120, height: 110)
            hud.margin = 16
            hud.bezelView.layer.cornerRadius = 12
            hud.removeFromSuperViewOnHide = true
            
        }
        
        // MARK: - 获取安全视图
        private static func getSafeView() -> UIView? {
            guard let window = UIApplication.currentKeyWindow else {
                print("未找到有效窗口")
                return nil
            }
            return window
        }
        
        // MARK: - 显示加载提示
    
    static func showLoading(_ text: String? = nil,_ view:UIView?) {
      
        guard var window = getSafeView() else { return }
        if(view != nil){
            window = view!
        }
        let hud = MBProgressHUD.showAdded(to: window, animated: true)
        setupCommonStyle(hud: hud)
        
        hud.mode = .indeterminate
        hud.label.text = text ?? "加载中..."
        hud.label.font = UIFont.systemFont(ofSize: 14, weight: .medium)



        }
        

    // MARK: - 显示成功提示
    static func showSuccess(_ text: String, delay: TimeInterval = 1.5) {
        hide(nil)
        guard let window = getSafeView() else { return }
        let hud = MBProgressHUD.showAdded(to: window, animated: true)
        setupCommonStyle(hud: hud)
        
        hud.mode = .customView
        hud.customView = UIImageView(image: UIImage(named: "progress_success"))
        hud.label.text = text
        hud.hide(animated: true, afterDelay: delay)
    }
    
    // MARK: - 显示错误提示
    static func showError(_ text: String, delay: TimeInterval = 1.5) {
        hide(nil)
        guard let window = getSafeView() else { return }
        let hud = MBProgressHUD.showAdded(to: window, animated: true)
        setupCommonStyle(hud: hud)
        
        hud.mode = .customView
        hud.customView = UIImageView(image: UIImage(named: "progress_error"))
        hud.label.text = text
        hud.hide(animated: true, afterDelay: delay)
    }
    
    // MARK: - 隐藏所有HUD
    static func hide(_ view:UIView?) {
        guard var window = getSafeView() else { return }
        if(view != nil){
            window = view!
        }
        MBProgressHUD.hide(for: window, animated: true)
    }


}


extension UIApplication {
    static var currentKeyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            return shared.keyWindow
        }
    }
}
