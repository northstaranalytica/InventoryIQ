//
//  MainTabBarController.swift
//  GoodsAI
//
//  Created by Steve on 2025/3/11.
//

import UIKit

class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
    }
    
    private func setupTabs() {
        let dashboardVC = DashboardVC()
        let searchVC = SearchVC()
        
        let dashboardNav = BaseNavigationController(rootViewController: dashboardVC)
        let searchNav = BaseNavigationController(rootViewController: searchVC)
        
        var dashboardConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .default)
        let dashboardImage = UIImage(systemName: "list.dash", withConfiguration: dashboardConfig)
        dashboardConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .default)
        let dashboardSelectedImage = UIImage(systemName: "list.dash.fill", withConfiguration: dashboardConfig)
        let dashboardTabBarItem = UITabBarItem(title: "Dashboard", image: dashboardImage, tag: 0)
        dashboardTabBarItem.selectedImage = dashboardSelectedImage
        
        var searchConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .default)
        let searchImage = UIImage(systemName: "magnifyingglass", withConfiguration: searchConfig)
        searchConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .default)
        let searchSelectedImage = UIImage(systemName: "magnifyingglass.circle.fill", withConfiguration: searchConfig)
        let searchTabBarItem = UITabBarItem(title: "Search", image: searchImage, tag: 1)
        searchTabBarItem.selectedImage = searchSelectedImage
        
        dashboardNav.tabBarItem = dashboardTabBarItem
        searchNav.tabBarItem = searchTabBarItem
        
        viewControllers = [dashboardNav, searchNav]
    }
}
