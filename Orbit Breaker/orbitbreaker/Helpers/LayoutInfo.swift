//
//  LayoutInfo.swift
//  Orbit Breaker
//
//  Created by Thomas Rife on 12/19/24.
//

import CoreGraphics

struct LayoutInfo {
    let screenSize: CGSize
    let nodeSize: CGSize
    let nodePosition: CGPoint

    init(screenSize: CGSize) {
        self.screenSize = screenSize

        // Example logic for calculating size and position
        self.nodeSize = CGSize(width: screenSize.width * 0.1, height: screenSize.width * 0.1)
        self.nodePosition = CGPoint(x: screenSize.width * 0.5, y: screenSize.height * 0.5)
    }
}
