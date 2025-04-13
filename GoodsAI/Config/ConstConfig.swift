//
//  ConstConfig.swift
//  GoodsAI
//
//  Created by Emily on 2025/3/11.
//

import Foundation
import UIKit




let kScreenWidth = UIScreen.main.bounds.width
let kScreenHeight = UIScreen.main.bounds.height
let kStatusBarHeight        : CGFloat = UIDevice.vg_statusBarHeight()
let kStatusBarSpaceX        : CGFloat = UIDevice.vg_safeDistanceTop()
let kTopBarHeight           : CGFloat = UIDevice.vg_navigationBarHeight()//44
let kNavigationFullBar       : CGFloat = UIDevice.vg_navigationFullHeight()
let kBottomFullBarHeight        : CGFloat = UIDevice.vg_tabBarFullHeight()
let kBottomBarRealHeight    : CGFloat = UIDevice.vg_tabBarHeight()//49
let kTabbarSafeBottomMargin : CGFloat = UIDevice .vg_safeDistanceBottom()
let ksafeDistanceBottomMargin : CGFloat = UIDevice .vg_safeDistanceBottom()

let ikIsIhoneX :           Bool = UIDevice .isIPhoneX()


let kCurrentAppVerson = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

/// UserdefaultKey
let kZDUserdefaultKey = "kZDUserdefaultKey"
