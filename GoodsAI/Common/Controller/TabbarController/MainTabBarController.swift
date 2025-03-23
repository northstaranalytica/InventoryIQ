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
        let homeVC = MyStuffVC()
        let mineVC = InventoryVC()
        
        let homeNav = BaseNavigationController(rootViewController: homeVC)
        let mineNav = BaseNavigationController(rootViewController: mineVC)
        
        var configuration = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .default)
            let image = UIImage(systemName: "house", withConfiguration: configuration)
            configuration = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .default)
            let selectedImage = UIImage(systemName: "house.fill", withConfiguration: configuration)
            let homeTabBarItem = UITabBarItem(title: "Stuff", image: image, tag: 0)
            tabBarItem.selectedImage = selectedImage
        
        
        var myConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .default)
            let myImage = UIImage(systemName: "list.bullet", withConfiguration: configuration)
        myConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .default)
            let MySelectedImage = UIImage(systemName: "list.bullet", withConfiguration: myConfiguration)
            let MyTabBarItem = UITabBarItem(title: "Inventory", image: myImage, tag: 0)
            tabBarItem.selectedImage = MySelectedImage
        
        homeNav.tabBarItem = homeTabBarItem
        mineNav.tabBarItem = MyTabBarItem
        
        viewControllers = [homeNav, mineNav]
    }
}
