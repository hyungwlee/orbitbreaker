//
//  OBEnemyTypes.swift
//  Orbit Breaker
//
//  Created by Michelle Bai on 12/20/24.
//

import SpriteKit

enum OBEnemyType {
    case a
    case b
    case c
    case d
    
    func size(using layoutInfo: OBLayoutInfo) -> CGSize {
        let baseSize = CGSize(width: 55.2, height: 36.8)
        return CGSize(
            width: baseSize.width * layoutInfo.screenScaleFactor,
            height: baseSize.height * layoutInfo.screenScaleFactor
        )
    }

    static var name: String {
        return "enemy"
    }
    
    // Get sprite name based on health and boss type
    static func spriteForHealth(_ health: Int, bossType: OBBossType) -> String {
        let prefix = bossType == .anger ? "Angry" :
                    bossType == .disgust ? "Breathe" :
                    bossType == .sadness ? "Sad" :
                    "Love"
        
        switch health {
        case 31...40: return "\(prefix) Face UFO (Base)"    // Full health
        case 21...30: return "\(prefix) Face UFO (Damaged 1)" // First damage state
        case 11...20: return "\(prefix) Face UFO (Damaged 2)" // Second damage state
        default: return "\(prefix) Face UFO (Damaged 3)"      // Final damage state
        }
    }
    
    var initialHealth: Int {
        return 40  // All enemies start with 40 health
    }
}
