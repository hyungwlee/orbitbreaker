//
//  OBEnemyConfig.swift
//  Orbit Breaker
//
//  Created by Michelle Bai on 12/20/24.
//


import Foundation
import CoreGraphics

struct OBEnemyConfig {
    // Grid layout
    static let topScreenPadding: CGFloat = 0.2  // 20% padding from top
    static let gridHeight: CGFloat = 0.33       // Takes up 1/3 of screen height
    static let horizontalPadding: CGFloat = 0.1 // 10% padding from sides
    
    // Enemy counts
    static let rowCount = 3
    static let columnCount = 6
    
    // Calculated spacing will be handled in EnemyManager
}
