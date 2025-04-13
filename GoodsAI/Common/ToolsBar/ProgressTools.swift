//
//  ToolsBar.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/13.
//

import Foundation
import MBProgressHUD


class ProgressTools {


    /// Common style configuration
        private static func setupCommonStyle(hud: MBProgressHUD) {
            hud.contentColor = .white
            hud.bezelView.color = UIColor.black.withAlphaComponent(0.7)
            hud.bezelView.style = .solidColor
            hud.minSize = CGSize(width: 120, height: 110)
            hud.margin = 16
            hud.bezelView.layer.cornerRadius = 12
            hud.removeFromSuperViewOnHide = true
            
        }
        
        // MARK: - Get Safe View
        private static func getSafeView() -> UIView? {
            guard let window = UIApplication.currentKeyWindow else {
                print("No valid window found")
                return nil
            }
            return window
        }
        
        // MARK: - Show Loading Tip
    
    static func showLoading(_ text: String? = nil,_ view:UIView?) {
      
        guard var window = getSafeView() else { return }
        if(view != nil){
            window = view!
        }
        let hud = MBProgressHUD.showAdded(to: window, animated: true)
        setupCommonStyle(hud: hud)
        
        hud.mode = .indeterminate
        hud.label.text = text ?? "Loading..."
        hud.label.font = UIFont.systemFont(ofSize: 14, weight: .medium)



        }
        

    // MARK: - Show Success Tip
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
    
    // MARK: - Show Error Tip
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
    
    // MARK: - Hide All HUDs
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
