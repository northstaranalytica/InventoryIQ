//
//  UIDevice+Centran.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/11.
//

import UIKit
extension UIDevice {

    
    /// Top safe area height
    static func vg_safeDistanceTop() -> CGFloat {
        let scene = UIApplication.shared.connectedScenes.first
        guard let windowScene = scene as? UIWindowScene else { return 0 }
        guard let window = windowScene.windows.first else { return 0 }
        return window.safeAreaInsets.top
    }
    
    /// Bottom safe area height
    static func vg_safeDistanceBottom() -> CGFloat {
        let scene = UIApplication.shared.connectedScenes.first
        guard let windowScene = scene as? UIWindowScene else { return 0 }
        guard let window = windowScene.windows.first else { return 0 }
        return window.safeAreaInsets.bottom
    }
    
    /// Top status bar height (including safe area)
    static func vg_statusBarHeight() -> CGFloat {
        var statusBarHeight: CGFloat = 0
        let scene = UIApplication.shared.connectedScenes.first
        guard let windowScene = scene as? UIWindowScene else { return 0 }
        guard let statusBarManager = windowScene.statusBarManager else { return 0 }
        statusBarHeight = statusBarManager.statusBarFrame.height
        return statusBarHeight
    }
    
    /// Navigation bar height
    static func vg_navigationBarHeight() -> CGFloat {
        return 44.0
    }
    
    /// Status bar + navigation bar height
    static func vg_navigationFullHeight() -> CGFloat {
        return UIDevice.vg_statusBarHeight() + UIDevice.vg_navigationBarHeight()
    }
    
    /// Bottom tab bar height
    static func vg_tabBarHeight() -> CGFloat {
        return 49.0
    }
    
    /// Bottom tab bar height (including safe area)
    static func vg_tabBarFullHeight() -> CGFloat {
        return UIDevice.vg_tabBarHeight() + UIDevice.vg_safeDistanceBottom()
    }
    
    
    /// Is iPhone X series
    static func isIPhoneX() -> Bool {
        if(UIDevice.vg_safeDistanceBottom() == 0 ){
            return false
        }
        return true
    }
}

