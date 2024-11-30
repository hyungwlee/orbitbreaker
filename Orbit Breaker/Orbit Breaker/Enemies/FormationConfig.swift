//
//  FormationConfig.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 11/29/24.
//

import SpriteKit


struct FormationMatrix {
    // Each formation is defined by a 2D array where:
    // 1 represents an enemy position
    // 0 represents an empty space
    static let formations: [String: [[Int]]] = [
        "standard": [
            [1, 1, 1, 1, 1],
            [1, 1, 1, 1, 1],
            [1, 1, 1, 1, 1],
            [1, 1, 1, 1, 1],
            [1, 1, 1, 1, 1]
        ],
        "arrow": [
            [0, 0, 1, 0, 0],
            [0, 1, 1, 1, 0],
            [1, 1, 1, 1, 1],
            [1, 1, 1, 1, 1],
            [1, 1, 1, 1, 1]
        ],
        "diamond": [
            [0, 0, 1, 0, 0],
            [0, 1, 1, 1, 0],
            [1, 1, 1, 1, 1],
            [0, 1, 1, 1, 0],
            [0, 0, 1, 0, 0]
        ],
        "vShape": [
            [1, 1, 1, 1, 1],
            [1, 1, 1, 1, 1],
            [1, 0, 1, 0, 1],
            [1, 0, 1, 0, 1],
            [1, 0, 1, 0, 1]
        ],
        "zigzag": [
            [1, 0, 1, 0, 1],
            [0, 1, 0, 1, 0],
            [1, 0, 1, 0, 1],
            [0, 1, 0, 1, 0],
            [1, 0, 1, 0, 1]
        ],
        "cross": [
            [1, 0, 1, 0, 1],
            [0, 1, 1, 1, 0],
            [1, 1, 1, 1, 1],
            [0, 1, 1, 1, 0],
            [1, 0, 1, 0, 1]
        ],
        "wave": [
            [1, 0, 0, 0, 1],
            [0, 1, 0, 1, 0],
            [0, 0, 1, 0, 0],
            [0, 1, 0, 1, 0],
            [1, 0, 0, 0, 1]
        ]
    ]
    
}

class FormationGenerator {
    static func generatePositions(
           from matrix: [[Int]],
           in scene: SKScene,
           spacing: CGSize = CGSize(width: 50, height: 40),
           topMargin: CGFloat = 0.85 // Adjusted to keep formations higher
       ) -> [CGPoint] {
           var positions: [CGPoint] = []
           
           let matrixWidth = matrix[0].count
           let matrixHeight = matrix.count
           
           // Calculate formation dimensions
           let formationWidth = CGFloat(matrixWidth) * spacing.width
           let formationHeight = CGFloat(matrixHeight) * spacing.height
           
           // Safe margins
           let safeMarginX: CGFloat = 40
           
           // Calculate top-area boundaries
           let topAreaMaxY = scene.size.height * topMargin
           let topAreaMinY = scene.size.height * 0.5
           
           // Calculate start position
           let startX = max(safeMarginX, (scene.size.width - formationWidth) / 2 + spacing.width / 2)
           let startY = topAreaMaxY // Start from top of allowed area
           
           for (rowIndex, row) in matrix.enumerated() {
               for (colIndex, value) in row.enumerated() {
                   if value == 1 {
                       let x = startX + CGFloat(colIndex) * spacing.width
                       let y = startY - CGFloat(rowIndex) * spacing.height
                       
                       // Verify position is within bounds
                       if x >= safeMarginX &&
                          x <= scene.size.width - safeMarginX &&
                          y >= topAreaMinY &&
                          y <= topAreaMaxY {
                           positions.append(CGPoint(x: x, y: y))
                       }
                   }
               }
           }
           
           return positions
       }
}

