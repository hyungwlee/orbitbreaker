//
//  EnemyTypes.swift
//  Orbit Breaker
//
//  Created by August Wetterau on 10/25/24.
//

import SpriteKit

enum EnemyType {
    case a
    case b
    case c
    
    static var size: CGSize {
        return CGSize(width: 24, height: 16)
    }
    
    static var name: String {
        return "enemy"
    }
    
    var color: SKColor {
        switch self {
        case .a: return .red
        case .b: return .green
        case .c: return .blue
        }
    }
    
    // Add health for each type
    var initialHealth: Int {
            switch self {
            case .a: return 40  // Now requires 1 hit (with 10 damage)
            case .b: return 40  // Now requires 2 hits
            case .c: return 40  // Now requires 3 hits
            }
        }
}
