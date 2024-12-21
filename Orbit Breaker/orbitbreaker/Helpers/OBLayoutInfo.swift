//
//  LayoutInfo.swift
//  Orbit Breaker
//
//  Created by Thomas Rife on 12/19/24.
//

import CoreGraphics

struct OBLayoutInfo {
    let screenSize: CGSize
    let nodeSize: CGSize
    let nodePosition: CGPoint
    let screenScaleFactor: CGFloat
    
    init(screenSize: CGSize) {
        self.screenSize = screenSize
        
        // Example logic for calculating size and position
        self.nodeSize = CGSize(width: screenSize.width * 0.1, height: screenSize.width * 0.1)
        self.nodePosition = CGPoint(x: screenSize.width * 0.5, y: screenSize.height * 0.5)
        // 44 is the size you want
        // 440 * 0.1 = 44 (Pro Max)
        // ~300 * = 30 (SE)
        
        self.screenScaleFactor = screenSize.height / 956.0 //height of Pro Max
        // 956 / 956 = 1.0 (Pro Max)
        // 667 / 956 -> 0.7 (SE)
        
        // 44 as player width
        // 44 * 1.0 = 44 (Pro Max)
        // 44 * 0.7 = 30.8 (SE
        
        
        if screenSize.height < 700 { // means it's SE
            // position of something is 0.9 * screenSize.height to make room for other components
        } else { // Normal sizes
            // position of something is 0.8 * screenSize.height
        }
    }
}
