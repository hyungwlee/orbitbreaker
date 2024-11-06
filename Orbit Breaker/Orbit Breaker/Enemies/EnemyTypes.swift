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
    case d
    
    static var size: CGSize {
        return CGSize(width: 24, height: 16)
    }
    
    static var name: String {
        return "enemy"
    }
    
    // Now color is based on health instead of type
    static func colorForHealth(_ health: Int) -> SKColor {
        switch health {
        case 40: return .purple    // Full health
        case 30: return .red       // Lost some health
        case 20: return .orange    // Half health
        default: return .yellow         // Low health
        }
    }
    
    // Initial color should be purple since all start at 40 health
    var color: SKColor {
        return EnemyType.colorForHealth(40)
    }
    
    var initialHealth: Int {
        return 40  // All enemies start with 40 health
    }
}
