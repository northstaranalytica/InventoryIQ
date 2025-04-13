//
//  SortOption.swift
//  GoodsAI
//
//  Created by Claude on 2025/3/16.
//

import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case nameAsc = "Name (A-Z)"
    case nameDesc = "Name (Z-A)"
    case priceAsc = "Price (Low-High)"
    case priceDesc = "Price (High-Low)"
    
    var id: String { self.rawValue }
}