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
            [1, 1, 1, 1, 1]
        ],
        "arrow": [
            [0, 0, 1, 0, 0],
            [0, 1, 1, 1, 0],
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
            [0, 1, 1, 1, 0],
            [0, 0, 1, 0, 0]
        ]
    ]
    
    // Add your own formations by adding new entries to the dictionary above!
}

class FormationGenerator {
    static func generatePositions(
        from matrix: [[Int]],
        in scene: SKScene,
        spacing: CGSize = CGSize(width: 60, height: 50),
        topMargin: CGFloat = 0.8
    ) -> [CGPoint] {
        var positions: [CGPoint] = []
        
        // Calculate total width and height of formation
        let matrixWidth = matrix[0].count
        let matrixHeight = matrix.count
        
        // Calculate total formation dimensions
        let formationWidth = CGFloat(matrixWidth) * spacing.width
        let formationHeight = CGFloat(matrixHeight) * spacing.height
        
        // Calculate starting position to center the formation
        let startX = (scene.size.width - formationWidth) / 2 + spacing.width / 2
        let startY = scene.size.height * topMargin - spacing.height / 2
        
        // Ensure formation fits within screen bounds
        let minX = spacing.width / 2
        let maxX = scene.size.width - spacing.width / 2
        let minY = spacing.height
        let maxY = scene.size.height - spacing.height
        
        // Generate positions for each enemy
        for (rowIndex, row) in matrix.enumerated() {
            for (colIndex, value) in row.enumerated() {
                if value == 1 {
                    let x = startX + CGFloat(colIndex) * spacing.width
                    let y = startY - CGFloat(rowIndex) * spacing.height
                    
                    // Only add position if it's within screen bounds
                    if x >= minX && x <= maxX && y >= minY && y <= maxY {
                        positions.append(CGPoint(x: x, y: y))
                    }
                }
            }
        }
        
        return positions
    }
}

